import 'dart:convert';
import 'package:eyadty/core/storage/cache_helper.dart';

/// In-memory + persisted JSON database for the local server simulation.
///
/// Persists collections to [AppSharedPreferences] so web/desktop restarts
/// preserve local server state until [resetToSeeds] is called.
class LocalServerDb {
  static const String _storageKey = 'eyadty_local_server_db_v1';

  final Map<String, List<Map<String, dynamic>>> _collections = {};
  final Map<String, dynamic> _idempotencyCache = {};
  final Map<String, int> _revisions = {};
  bool _seeded = false;

  void Function(LocalServerDb db)? onSeed;

  LocalServerDb({this.onSeed});

  void ensureSeeded() {
    if (_seeded) return;
    _seeded = true;
    if (_restoreFromPrefs()) return;
    onSeed?.call(this);
    _persistToPrefs();
  }

  List<Map<String, dynamic>> collection(String name) {
    ensureSeeded();
    return _collections.putIfAbsent(name, () => []);
  }

  void replaceCollection(String name, List<Map<String, dynamic>> items) {
    _collections[name] = items.map((e) => Map<String, dynamic>.from(e)).toList();
    _persistToPrefs();
  }

  int nextRevision(String key) {
    final next = (_revisions[key] ?? 0) + 1;
    _revisions[key] = next;
    return next;
  }

  dynamic getIdempotentResponse(String? key) {
    if (key == null || key.isEmpty) return null;
    return _idempotencyCache[key];
  }

  void saveIdempotentResponse(String? key, dynamic response) {
    if (key == null || key.isEmpty) return;
    _idempotencyCache[key] = response;
    _persistToPrefs();
  }

  void persist() => _persistToPrefs();

  Future<void> resetToSeeds() async {
    _collections.clear();
    _idempotencyCache.clear();
    _revisions.clear();
    _seeded = true;
    onSeed?.call(this);
    _persistToPrefs();
  }

  bool _restoreFromPrefs() {
    try {
      final raw = AppSharedPreferences.getString(key: _storageKey);
      if (raw == null || raw.isEmpty) return false;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cols = decoded['collections'] as Map<String, dynamic>?;
      if (cols == null || cols.isEmpty) return false;
      cols.forEach((key, value) {
        _collections[key] = (value as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
      final idem = decoded['idempotency'] as Map<String, dynamic>?;
      if (idem != null) _idempotencyCache.addAll(idem);
      final revs = decoded['revisions'] as Map<String, dynamic>?;
      if (revs != null) {
        revs.forEach((k, v) => _revisions[k] = (v as num).toInt());
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void _persistToPrefs() {
    try {
      final payload = jsonEncode({
        'collections': _collections,
        'idempotency': _idempotencyCache,
        'revisions': _revisions,
      });
      AppSharedPreferences.setString(value: payload, key: _storageKey);
    } catch (_) {
      // SharedPreferences may be uninitialized in pure unit tests.
    }
  }
}
