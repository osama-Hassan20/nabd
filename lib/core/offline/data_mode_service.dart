import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:eyadty/core/config/app_config.dart';
import 'package:eyadty/core/storage/cache_helper.dart';

enum DataMode {
  online,
  offline,
  forcedLocal,
}

class DataModeState extends Equatable {
  final DataMode mode;
  final bool isForcedLocal;
  final bool isServerReachable;
  final int pendingOutboxCount;
  final bool isSyncInProgress;
  final String? lastReachabilityError;
  final DateTime lastCheckedAt;

  const DataModeState({
    required this.mode,
    required this.isForcedLocal,
    required this.isServerReachable,
    this.pendingOutboxCount = 0,
    this.isSyncInProgress = false,
    this.lastReachabilityError,
    required this.lastCheckedAt,
  });

  DataModeState copyWith({
    DataMode? mode,
    bool? isForcedLocal,
    bool? isServerReachable,
    int? pendingOutboxCount,
    bool? isSyncInProgress,
    String? lastReachabilityError,
    DateTime? lastCheckedAt,
  }) {
    return DataModeState(
      mode: mode ?? this.mode,
      isForcedLocal: isForcedLocal ?? this.isForcedLocal,
      isServerReachable: isServerReachable ?? this.isServerReachable,
      pendingOutboxCount: pendingOutboxCount ?? this.pendingOutboxCount,
      isSyncInProgress: isSyncInProgress ?? this.isSyncInProgress,
      lastReachabilityError:
          lastReachabilityError ?? this.lastReachabilityError,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        isForcedLocal,
        isServerReachable,
        pendingOutboxCount,
        isSyncInProgress,
        lastReachabilityError,
        lastCheckedAt,
      ];
}

/// Lightweight reachability probe contract.
typedef ReachabilityProbe = Future<bool> Function(
  String url,
  Duration timeout,
);

/// Coordinates in-flight sync operations when mode changes to prevent losing server acknowledgments.
abstract class InFlightSyncCoordinator {
  bool get isSyncInProgress;
  Future<void> onModeSwitchedToForcedLocal();
  void recordAckSafely(String operationId, Map<String, dynamic> ackResponse);
}

class DataModeService {
  static const String forcedLocalKey = 'eyadty_forced_local_mode';

  final ReachabilityProbe _reachabilityProbe;
  final InFlightSyncCoordinator? _syncCoordinator;
  final _stateController = StreamController<DataModeState>.broadcast();

  late DataModeState _state;
  Timer? _periodicProbeTimer;

  DataModeService({
    ReachabilityProbe? reachabilityProbe,
    this._syncCoordinator,
    bool initialReachable = true,
  })  : _reachabilityProbe = reachabilityProbe ?? _defaultHttpProbe {
    bool persistedForced = false;
    try {
      persistedForced = AppSharedPreferences.getBool(key: forcedLocalKey) ?? false;
    } catch (_) {
      persistedForced = false;
    }
    _state = DataModeState(
      mode: _calculateEffectiveMode(
        forcedLocal: persistedForced,
        reachable: initialReachable,
      ),
      isForcedLocal: persistedForced,
      isServerReachable: initialReachable,
      lastCheckedAt: DateTime.now(),
    );
  }

  Stream<DataModeState> get stream => _stateController.stream;
  DataModeState get state => _state;
  DataMode get currentMode => _state.mode;
  bool get isOnline => _state.mode == DataMode.online;
  bool get isOffline => _state.mode == DataMode.offline;
  bool get isForcedLocal => _state.mode == DataMode.forcedLocal;

  static DataMode _calculateEffectiveMode({
    required bool forcedLocal,
    required bool reachable,
  }) {
    if (forcedLocal) return DataMode.forcedLocal;
    if (!reachable) return DataMode.offline;
    return DataMode.online;
  }

  /// Sets manual Forced Local Mode toggle and persists it.
  Future<void> setForcedLocal(bool enabled) async {
    if (_state.isForcedLocal == enabled) return;

    await AppSharedPreferences.setBool(key: forcedLocalKey, value: enabled);

    if (enabled && _syncCoordinator?.isSyncInProgress == true) {
      // Reconcile and halt new requests while ensuring in-flight ACK is preserved
      await _syncCoordinator?.onModeSwitchedToForcedLocal();
    }

    final newMode = _calculateEffectiveMode(
      forcedLocal: enabled,
      reachable: _state.isServerReachable,
    );

    _emit(_state.copyWith(
      isForcedLocal: enabled,
      mode: newMode,
      lastCheckedAt: DateTime.now(),
    ));
  }

  /// Updates the pending outbox operations counter displayed in UI chips.
  void updatePendingOutboxCount(int count) {
    if (_state.pendingOutboxCount == count) return;
    _emit(_state.copyWith(pendingOutboxCount: count));
  }

  /// Updates sync in-progress state.
  void setSyncInProgress(bool inProgress) {
    if (_state.isSyncInProgress == inProgress) return;
    _emit(_state.copyWith(isSyncInProgress: inProgress));
  }

  /// Probes real reachability against the configured baseUrl.
  Future<bool> checkReachability({Duration timeout = const Duration(seconds: 3)}) async {
    bool reachable = false;
    String? errorMsg;

    try {
      reachable = await _reachabilityProbe(AppConfig.baseUrl, timeout);
    } catch (e) {
      reachable = false;
      errorMsg = e.toString();
    }

    final newMode = _calculateEffectiveMode(
      forcedLocal: _state.isForcedLocal,
      reachable: reachable,
    );

    _emit(_state.copyWith(
      isServerReachable: reachable,
      lastReachabilityError: errorMsg,
      mode: newMode,
      lastCheckedAt: DateTime.now(),
    ));

    return reachable;
  }

  /// Starts periodic background connectivity probing.
  void startPeriodicProbing({Duration interval = const Duration(seconds: 30)}) {
    _periodicProbeTimer?.cancel();
    _periodicProbeTimer = Timer.periodic(interval, (_) => checkReachability());
  }

  void stopPeriodicProbing() {
    _periodicProbeTimer?.cancel();
    _periodicProbeTimer = null;
  }

  void dispose() {
    stopPeriodicProbing();
    _stateController.close();
  }

  void _emit(DataModeState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  static Future<bool> _defaultHttpProbe(String url, Duration timeout) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .head(uri)
          .timeout(timeout, onTimeout: () => http.Response('timeout', 408));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  @visibleForTesting
  void setReachabilityForTesting(bool reachable) {
    final newMode = _calculateEffectiveMode(
      forcedLocal: _state.isForcedLocal,
      reachable: reachable,
    );
    _emit(_state.copyWith(
      isServerReachable: reachable,
      mode: newMode,
      lastCheckedAt: DateTime.now(),
    ));
  }
}
