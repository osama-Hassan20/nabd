// import 'package:flutter/material.dart';
// import 'package:media_kit/media_kit.dart';
// import 'package:media_kit_video/media_kit_video.dart';
// import 'package:purexo/core/utils/theme/app_colors.dart';

// class VideoFullScreenPage extends StatefulWidget {
//   final String videoPath;
//   final bool isNetworkVideo;
//   final Duration? initialPosition;

//   const VideoFullScreenPage({
//     super.key,
//     required this.videoPath,
//     this.isNetworkVideo = false,
//     this.initialPosition,
//   });

//   @override
//   State<VideoFullScreenPage> createState() => _VideoFullScreenPageState();
// }

// class _VideoFullScreenPageState extends State<VideoFullScreenPage> {
//   late final Player _player;
//   late final VideoController _controller;
//   bool _isInitialized = false;
//   bool _isPlaying = false;
//   Duration _position = Duration.zero;
//   Duration _duration = Duration.zero;

//   @override
//   void initState() {
//     super.initState();
//     _player = Player();
//     _controller = VideoController(_player);
//     _initializeVideo();
//   }

//   Future<void> _initializeVideo() async {
//     // Listen to streams
//     _player.stream.playing.listen((playing) {
//       if (mounted) setState(() => _isPlaying = playing);
//     });

//     _player.stream.position.listen((position) {
//       if (mounted) setState(() => _position = position);
//     });

//     _player.stream.duration.listen((duration) {
//       if (mounted) {
//         setState(() {
//           _duration = duration;
//           if (duration > Duration.zero) {
//             _isInitialized = true;
//           }
//         });
//       }
//     });

//     await _player.open(Media(widget.videoPath), play: false);

//     if (widget.initialPosition != null) {
//       await _player.seek(widget.initialPosition!);
//     }
//     await _player.play();
//   }

//   @override
//   void dispose() {
//     _player.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           Center(
//             child: _isInitialized
//                 ? Video(controller: _controller, controls: NoVideoControls)
//                 : const CircularProgressIndicator(),
//           ),
//           // Back Button
//           Positioned(
//             top: MediaQuery.of(context).padding.top + 10,
//             left: 10,
//             child: IconButton(
//               icon: const Icon(Icons.close, color: Colors.white, size: 30),
//               onPressed: () => Navigator.pop(context, _position),
//             ),
//           ),
//           // Controls
//           if (_isInitialized)
//             Positioned(
//               bottom: 20,
//               left: 0,
//               right: 0,
//               child: Column(
//                 children: [
//                   // Progress bar
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                     child: SliderTheme(
//                       data: SliderTheme.of(context).copyWith(
//                         activeTrackColor: AppColors.primary,
//                         inactiveTrackColor: Colors.white24,
//                         thumbColor: AppColors.primary,
//                         thumbShape: const RoundSliderThumbShape(
//                           enabledThumbRadius: 6,
//                         ),
//                         trackHeight: 3,
//                       ),
//                       child: Slider(
//                         min: 0,
//                         max: _duration.inMilliseconds.toDouble(),
//                         value: _position.inMilliseconds.toDouble().clamp(
//                           0,
//                           _duration.inMilliseconds.toDouble(),
//                         ),
//                         onChanged: (value) {
//                           _player.seek(Duration(milliseconds: value.toInt()));
//                         },
//                       ),
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       IconButton(
//                         icon: Icon(
//                           _isPlaying ? Icons.pause : Icons.play_arrow,
//                           color: Colors.white,
//                           size: 40,
//                         ),
//                         onPressed: () {
//                           _player.playOrPause();
//                         },
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
