// import 'dart:math' as math;
// import 'package:eyadty/core/api/end_points.dart';
// import 'package:flutter/material.dart';
// import 'package:eyadty/core/audio/platform_audio_player.dart';
// import '../../../core/models/audio_model.dart';
// import '../../../core/utils/extensions/theme_mode_extensions.dart';
// import '../../../core/utils/theme/app_colors.dart';
// import '../../../core/utils/theme/app_icons.dart';
// import '../../../core/utils/theme/custom_app_font_styles.dart';
// import './custom_asset_image.dart';
// import './custom_container.dart';

// class CustomAudioPlayer extends StatefulWidget {
//   const CustomAudioPlayer({
//     super.key,
//     required this.audioModel,
//     this.onDelete,
//     this.onReRecord,
//     this.showControls = true,
//   });

//   final AudioModel audioModel;
//   final VoidCallback? onDelete;
//   final VoidCallback? onReRecord;
//   final bool showControls;

//   @override
//   State<CustomAudioPlayer> createState() => _CustomAudioPlayerState();
// }

// class _CustomAudioPlayerState extends State<CustomAudioPlayer> {
//   late PlatformAudioPlayer _player;
//   bool _isPlaying = false;
//   Duration _position = Duration.zero;
//   Duration _total = Duration.zero;
//   bool _isLoaded = false;

//   // Waveform (generated from file hash or path for visual consistency)
//   late List<double> _waveform;
//   String audioUrl = '';
//   @override
//   void initState() {
//     widget.audioModel.type == AudioSourceType.file
//         ? audioUrl = widget.audioModel.path
//         : audioUrl = "${EndPoints.baseImageUrl}${widget.audioModel.path}";
//     super.initState();
//     _waveform = _generateWaveform(audioUrl.hashCode);
//     _player = PlatformAudioPlayer();
//     _setupListeners();
//     _loadAudio();
//   }

//   void _setupListeners() {
//     _player.onPlayingChanged = (playing) {
//       if (mounted) setState(() => _isPlaying = playing);
//     };
//     _player.onPositionChanged = (p) {
//       if (mounted) setState(() => _position = p);
//     };
//     _player.onDurationChanged = (d) {
//       if (mounted) setState(() => _total = d);
//     };
//     _player.onCompleted = () {
//       if (mounted) setState(() => _position = Duration.zero);
//     };
//   }

//   Future<void> _loadAudio() async {
//     try {
//       if (widget.audioModel.type == AudioSourceType.file) {
//         await _player.setFile(audioUrl);
//       } else {
//         await _player.setUrl(audioUrl);
//       }
//       if (mounted) setState(() => _isLoaded = true);
//     } catch (e) {
//       debugPrint('Error loading audio: $e');
//     }
//   }

//   @override
//   void didUpdateWidget(covariant CustomAudioPlayer oldWidget) {
//     if (oldWidget.audioModel != widget.audioModel) {
//       _waveform = _generateWaveform(audioUrl.hashCode);
//       _player.stop();
//       _position = Duration.zero;
//       _isLoaded = false;
//       _loadAudio();
//     }
//     super.didUpdateWidget(oldWidget);
//   }

//   @override
//   void dispose() {
//     _player.dispose();
//     super.dispose();
//   }

//   Future<void> _togglePlayPause() async {
//     if (!_isLoaded) {
//       // If not loaded yet, try to play directly
//       try {
//         if (widget.audioModel.type == AudioSourceType.file) {
//           await _player.playFile(audioUrl);
//         } else {
//           await _player.playUrl(audioUrl);
//         }
//         if (mounted) setState(() => _isLoaded = true);
//       } catch (e) {
//         debugPrint('Error playing audio: $e');
//       }
//       return;
//     }
//     await _player.togglePlayPause();
//   }

//   Future<void> _seek(DragUpdateDetails details, BuildContext ctx) async {
//     if (_total.inMilliseconds == 0) return;
//     final box = ctx.findRenderObject() as RenderBox?;
//     if (box == null) return;
//     final progress =
//         (box.globalToLocal(details.globalPosition).dx / box.size.width).clamp(
//           0.0,
//           1.0,
//         );
//     await _player.seek(
//       Duration(milliseconds: (progress * _total.inMilliseconds).toInt()),
//     );
//   }

//   String _fmt(Duration d) {
//     final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   List<double> _generateWaveform(int seed) {
//     final rng = math.Random(seed);
//     return List.generate(40, (_) => 0.2 + rng.nextDouble() * 0.8);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final progress = _total.inMilliseconds > 0
//         ? _position.inMilliseconds / _total.inMilliseconds
//         : 0.0;

//     return CustomContainer(
//       borderRaduis: 12,
//       backGroundColor: context.isDarkMode
//           ? AppColors.gray334155.withValues(alpha: 0.4)
//           : AppColors.gray334155.withValues(alpha: 0.1),
//       border: Border.all(color: AppColors.gray334155.withValues(alpha: 0.4)),
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header row
//           Row(
//             children: [
//               Icon(Icons.mic_rounded, color: AppColors.gray334155, size: 18),
//               const SizedBox(width: 6),
//               Text("التسجيل الصوتي", style: CustomAppFontStyle.medium16),
//               const Spacer(),
//               if (widget.showControls) ...[
//                 // Re-record
//                 if (widget.onReRecord != null)
//                   GestureDetector(
//                     onTap: widget.onReRecord,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: AppColors.gray334155.withValues(alpha: 0.3),
//                         ),
//                       ),
//                       child: Row(
//                         spacing: 4,
//                         children: [
//                           Icon(
//                             Icons.refresh_rounded,
//                             size: 14,
//                             color: context.isDarkMode
//                                 ? AppColors.gray334155
//                                 : AppColors.gray334155,
//                           ),
//                           Text(
//                             "إعادة تسجيل",
//                             style: CustomAppFontStyle.regular14.copyWith(),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 const SizedBox(width: 8),
//                 // Delete
//                 if (widget.onDelete != null)
//                   GestureDetector(
//                     onTap: widget.onDelete,
//                     child: Container(
//                       padding: const EdgeInsets.all(6),
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: AppColors.gray334155,
//                       ),
//                       child: CustomAssetImage(
//                         path: AppIcons.delete,
//                         color: AppColors.white,
//                       ),
//                     ),
//                   ),
//               ],
//             ],
//           ),
//           const SizedBox(height: 12),
//           // Player row
//           Row(
//             children: [
//               // Play/pause button
//               GestureDetector(
//                 onTap: _togglePlayPause,
//                 child: Container(
//                   width: 42,
//                   height: 42,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: AppColors.gray334155,
//                     boxShadow: [
//                       BoxShadow(
//                         color: AppColors.gray334155.withValues(alpha: 0.35),
//                         blurRadius: 10,
//                         offset: const Offset(0, 3),
//                       ),
//                     ],
//                   ),
//                   child: AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 200),
//                     child: Icon(
//                       _isPlaying
//                           ? Icons.pause_rounded
//                           : Icons.play_arrow_rounded,
//                       key: ValueKey(_isPlaying),
//                       color: AppColors.white,
//                       size: 22,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               // Waveform + duration
//               Expanded(
//                 child: Column(
//                   children: [
//                     GestureDetector(
//                       onHorizontalDragUpdate: (d) => _seek(d, context),
//                       child: SizedBox(
//                         height: 32,
//                         child: CustomPaint(
//                           size: const Size(double.infinity, 32),
//                           painter: PlaybackWaveformPainter(
//                             waveform: _waveform,
//                             progress: progress,
//                             activeColor: AppColors.gray334155,
//                             inactiveColor: AppColors.gray334155.withValues(
//                               alpha: 0.35,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           _isPlaying || _position > Duration.zero
//                               ? _fmt(_position)
//                               : _fmt(_total),
//                           style: CustomAppFontStyle.medium12.copyWith(
//                             color: AppColors.gray334155,
//                             fontFeatures: [const FontFeature.tabularFigures()],
//                           ),
//                         ),
//                         if (_total > Duration.zero)
//                           Text(
//                             _fmt(_total),
//                             style: CustomAppFontStyle.medium12.copyWith(
//                               color: AppColors.gray334155,
//                               fontFeatures: [
//                                 const FontFeature.tabularFigures(),
//                               ],
//                             ),
//                           ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class PlaybackWaveformPainter extends CustomPainter {
//   PlaybackWaveformPainter({
//     required this.waveform,
//     required this.progress,
//     required this.activeColor,
//     required this.inactiveColor,
//   });

//   final List<double> waveform;
//   final double progress;
//   final Color activeColor;
//   final Color inactiveColor;

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (waveform.isEmpty) return;
//     const barWidth = 2.5;
//     const barSpacing = 1.5;
//     final maxBars = (size.width / (barWidth + barSpacing)).floor();
//     final centerY = size.height / 2;
//     final maxBarH = size.height * 0.85;
//     final displayBars = math.min(maxBars, waveform.length);
//     final step = waveform.length / displayBars;

//     final activePaint = Paint()
//       ..color = activeColor
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = barWidth;
//     final inactivePaint = Paint()
//       ..color = inactiveColor
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = barWidth;

//     final totalW = displayBars * (barWidth + barSpacing) - barSpacing;
//     final startX = (size.width - totalW) / 2;

//     for (int i = 0; i < displayBars; i++) {
//       final amp = waveform[(i * step).floor().clamp(0, waveform.length - 1)];
//       final barH = (amp * maxBarH).clamp(3.0, maxBarH);
//       final x = startX + i * (barWidth + barSpacing);
//       final paint = i / displayBars <= progress ? activePaint : inactivePaint;
//       canvas.drawLine(
//         Offset(x, centerY - barH / 2),
//         Offset(x, centerY + barH / 2),
//         paint,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(covariant PlaybackWaveformPainter old) =>
//       old.progress != progress || old.waveform != waveform;
// }
