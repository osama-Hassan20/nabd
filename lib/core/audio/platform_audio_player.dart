// import 'package:flutter/foundation.dart';
// import 'package:audioplayers/audioplayers.dart' as ap;
// import 'package:just_audio/just_audio.dart' as ja;

// /// A unified audio player that uses [just_audio] on web
// /// and [audioplayers] on native platforms (Windows, Android, etc.).
// class PlatformAudioPlayer {
//   ap.AudioPlayer? _native;
//   ja.AudioPlayer? _web;

//   bool _isPlaying = false;
//   Duration _position = Duration.zero;
//   Duration _duration = Duration.zero;

//   void Function(bool isPlaying)? onPlayingChanged;
//   void Function(Duration position)? onPositionChanged;
//   void Function(Duration duration)? onDurationChanged;
//   void Function()? onCompleted;

//   PlatformAudioPlayer() {
//     if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
//       _web = ja.AudioPlayer();
//       _setupWebListeners();
//     } else {
//       _native = ap.AudioPlayer();
//       _setupNativeListeners();
//     }
//   }

//   // ── Getters ──────────────────────────────────────────
//   bool get isPlaying => _isPlaying;
//   Duration get position => _position;
//   Duration get duration => _duration;

//   // ── Setup ────────────────────────────────────────────
//   void _setupWebListeners() {
//     final player = _web!;
//     player.playerStateStream.listen((state) {
//       _isPlaying = state.playing;
//       onPlayingChanged?.call(_isPlaying);
//       if (state.processingState == ja.ProcessingState.completed) {
//         _position = Duration.zero;
//         player.seek(Duration.zero);
//         player.pause();
//         onCompleted?.call();
//       }
//     });
//     player.positionStream.listen((p) {
//       _position = p;
//       onPositionChanged?.call(p);
//     });
//     player.durationStream.listen((d) {
//       if (d != null) {
//         _duration = d;
//         onDurationChanged?.call(d);
//       }
//     });
//   }

//   void _setupNativeListeners() {
//     final player = _native!;
//     player.onPlayerStateChanged.listen((s) {
//       _isPlaying = s == ap.PlayerState.playing;
//       onPlayingChanged?.call(_isPlaying);
//     });
//     player.onPositionChanged.listen((p) {
//       _position = p;
//       onPositionChanged?.call(p);
//     });
//     player.onDurationChanged.listen((d) {
//       _duration = d;
//       onDurationChanged?.call(d);
//     });
//     player.onPlayerComplete.listen((_) {
//       _position = Duration.zero;
//       onCompleted?.call();
//     });
//   }

//   // ── Playback ─────────────────────────────────────────

//   /// Play an asset audio file. [assetPath] should include the full path
//   /// e.g. `'assets/audio/typing.mp3'`.
//   Future<void> playAsset(String assetPath) async {
//     if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
//       // On Flutter web, assets are served at their path relative to the web root.
//       // setAsset can fail on web, so we use setUrl with the direct asset path.
//       final webPath = assetPath.startsWith('assets/')
//           ? assetPath
//           : 'assets/$assetPath';
//       try {
//         await _web!.setUrl(webPath);
//       } catch (_) {
//         // Fallback: try setAsset in case the direct URL doesn't work
//         await _web!.setAsset(assetPath);
//       }
//       await _web!.play();
//     } else {
//       // audioplayers expects path relative to assets/ (without the 'assets/' prefix)
//       final nativePath = assetPath.startsWith('assets/')
//           ? assetPath.substring(7)
//           : assetPath;
//       await _native!.play(ap.AssetSource(nativePath));
//     }
//   }

//   /// Play audio from a network URL.
//   Future<void> playUrl(String url) async {
//     if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
//       await _web!.setUrl(url);
//       await _web!.play();
//     } else {
//       await _native!.play(ap.UrlSource(url));
//     }
//   }

//   /// Play audio from a local file path.
//   Future<void> playFile(String filePath) async {
//     if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
//       // File paths don't exist on web, treat as URL
//       await _web!.setUrl(filePath);
//       await _web!.play();
//     } else {
//       await _native!.play(ap.DeviceFileSource(filePath));
//     }
//   }

//   /// Set audio source from a URL without playing.
//   Future<void> setUrl(String url) async {
//     if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
//       await _web!.setUrl(url);
//     } else {
//       await _native!.setSourceUrl(url);
//     }
//   }

//   /// Set audio source from a file path without playing.
//   Future<void> setFile(String filePath) async {
//     if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
//       await _web!.setUrl(filePath);
//     } else {
//       await _native!.setSourceDeviceFile(filePath);
//     }
//   }

//   Future<void> play() async {
//     if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
//       await _web!.play();
//     } else {
//       await _native!.resume();
//     }
//   }

//   Future<void> pause() async {
//     if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
//       await _web!.pause();
//     } else {
//       await _native!.pause();
//     }
//   }

//   Future<void> stop() async {
//     if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
//       await _web!.stop();
//     } else {
//       await _native!.stop();
//     }
//   }

//   Future<void> seek(Duration position) async {
//     if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
//       await _web!.seek(position);
//     } else {
//       await _native!.seek(position);
//     }
//   }

//   Future<void> togglePlayPause() async {
//     if (_isPlaying) {
//       await pause();
//     } else {
//       await play();
//     }
//   }

//   void dispose() {
//     _web?.dispose();
//     _native?.dispose();
//   }
// }
