// import 'package:eyadty/core/api/end_points.dart';
// import 'package:flutter/material.dart';
// import 'package:media_kit/media_kit.dart';
// import 'package:media_kit_video/media_kit_video.dart';
// import '../../core/utils/theme/app_colors.dart';
// import '../../core/utils/theme/custom_app_font_styles.dart';
// import 'video_full_screen.dart';

// class VideoPreviewWidget extends StatefulWidget {
//   const VideoPreviewWidget({
//     super.key,
//     required this.videoPath,
//     this.isNetworkVideo = false,
//     this.height = 200,
//   });

//   final String videoPath;
//   final bool isNetworkVideo;
//   final double height;

//   @override
//   State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
// }

// class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
//   late final Player _player;
//   late final VideoController _controller;
//   bool _isInitialized = false;
//   bool _hasError = false;
//   bool _isPlaying = false;
//   Duration _duration = Duration.zero;
//   Duration _position = Duration.zero;
//   String videoUrl = '';

//   @override
//   void initState() {
//     videoUrl = !widget.isNetworkVideo
//         ? widget.videoPath
//         : '${EndPoints.baseImageUrl}${widget.videoPath}';
//     super.initState();
//     _player = Player();
//     _controller = VideoController(_player);
//     _initializeVideo();
//   }

//   Future<void> _initializeVideo() async {
//     try {
//       // Listen to player state changes
//       _player.stream.playing.listen((playing) {
//         if (mounted) {
//           setState(() => _isPlaying = playing);
//         }
//       });

//       _player.stream.duration.listen((duration) {
//         if (mounted) {
//           setState(() {
//             _duration = duration;
//             if (duration > Duration.zero) {
//               _isInitialized = true;
//             }
//           });
//         }
//       });

//       _player.stream.position.listen((position) {
//         if (mounted) {
//           setState(() => _position = position);
//         }
//       });

//       _player.stream.error.listen((error) {
//         debugPrint('MediaKit error: $error');
//         if (mounted) {
//           setState(() => _hasError = true);
//         }
//       });

//       // Open media
//       await _player.open(Media(videoUrl), play: false);
//     } catch (e) {
//       debugPrint('Error initializing video: $e');
//       if (mounted) {
//         setState(() => _hasError = true);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _player.dispose();
//     super.dispose();
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return '$minutes:$seconds';
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_hasError) {
//       return Container(
//         width: double.infinity,
//         height: widget.height,
//         decoration: BoxDecoration(
//           color: AppColors.gray334155.withValues(alpha: 0.2),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, size: 48, color: Colors.red),
//             const SizedBox(height: 8),
//             Text("فشل تحميل الفيديو", style: CustomAppFontStyle.regular14),
//           ],
//         ),
//       );
//     }

//     if (!_isInitialized) {
//       return Container(
//         width: double.infinity,
//         height: widget.height,
//         decoration: BoxDecoration(
//           color: AppColors.gray334155.withValues(alpha: 0.2),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(12),
//       child: SizedBox(
//         width: double.infinity,
//         height: widget.height,
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             // Video Player
//             SizedBox.expand(
//               child: Video(
//                 controller: _controller,
//                 controls: NoVideoControls,
//                 fit: BoxFit.cover,
//               ),
//             ),
//             // Play/Pause overlay
//             Positioned.fill(
//               child: Material(
//                 color: Colors.transparent,
//                 child: InkWell(
//                   onTap: () {
//                     _player.playOrPause();
//                   },
//                   child: Container(
//                     color: _isPlaying ? Colors.transparent : Colors.black26,
//                     child: Center(
//                       child: Icon(
//                         _isPlaying
//                             ? Icons.pause_circle_outline
//                             : Icons.play_circle_outline,
//                         size: 64,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             // Full Screen Button
//             Positioned(
//               left: 4,
//               top: 4,
//               child: IconButton(
//                 icon: const Icon(Icons.fullscreen, color: Colors.white),
//                 onPressed: () async {
//                   final wasPlaying = _isPlaying;
//                   await _player.pause();
//                   if (context.mounted) {
//                     final position = await Navigator.push<Duration>(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => VideoFullScreenPage(
//                           videoPath: videoUrl,
//                           isNetworkVideo: widget.isNetworkVideo,
//                           initialPosition: _position,
//                         ),
//                       ),
//                     );
//                     if (position != null) {
//                       await _player.seek(position);
//                     }
//                     if (wasPlaying) {
//                       await _player.play();
//                     }
//                   }
//                 },
//               ),
//             ),
//             // Duration indicator
//             Positioned(
//               bottom: 8,
//               right: 8,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.black54,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   _formatDuration(_duration),
//                   style: CustomAppFontStyle.regular12.copyWith(
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
