// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';



// // ─── Public API ───────────────────────────────────────────────────────────────

// /// Shows a custom date+time picker dialog.
// /// Returns the selected [DateTime] or `null` if cancelled/cleared.
// Future<DateTime?> showAppDateTimePicker(
//   BuildContext context, {
//   DateTime? initial,
//   DateTime? firstDate,
//   DateTime? lastDate,
//   String? title,
//   bool showTime = true,
//   bool allowFuture = true,
// }) {
//   final now = DateTime.now();
//   final effectiveLastDate = allowFuture ? (lastDate ?? DateTime(2100)) : now;

//   return showAnimatedDialog<DateTime>(
//     context: context,
//     child: _AppDateTimePickerDialog(
//       initial: initial,
//       firstDate: firstDate ?? DateTime(2020),
//       lastDate: effectiveLastDate,
//       title: title,
//       showTime: showTime,
//     ),
//   );
// }

// /// Shows a custom date-only picker dialog.
// /// Returns the selected [DateTime] (time 00:00) or `null` if cancelled/cleared.
// Future<DateTime?> showAppDatePicker(
//   BuildContext context, {
//   DateTime? initial,
//   DateTime? firstDate,
//   DateTime? lastDate,
//   String? title,
//   bool allowFuture = false,
// }) {
//   final now = DateTime.now();
//   final effectiveLastDate = allowFuture ? (lastDate ?? DateTime(2100)) : now;

//   return showAnimatedDialog<DateTime>(
//     context: context,
//     child: _AppDateTimePickerDialog(
//       initial: initial,
//       firstDate: firstDate ?? DateTime(1900),
//       lastDate: effectiveLastDate,
//       title: title,
//       dateOnly: true,
//     ),
//   );
// }

// // ─── Day-of-week header keys ──────────────────────────────────────────────────

// const _dayHeaders = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];

// // ─── Dialog widget ────────────────────────────────────────────────────────────

// class _AppDateTimePickerDialog extends StatefulWidget {
//   const _AppDateTimePickerDialog({
//     this.initial,
//     required this.firstDate,
//     required this.lastDate,
//     this.title,
//     this.dateOnly = false,
//     this.showTime = true,
//   });

//   final DateTime? initial;
//   final DateTime firstDate;
//   final DateTime lastDate;
//   final String? title;
//   final bool dateOnly;
//   final bool showTime;

//   @override
//   State<_AppDateTimePickerDialog> createState() =>
//       _AppDateTimePickerDialogState();
// }

// class _AppDateTimePickerDialogState extends State<_AppDateTimePickerDialog> {
//   late int _selectedYear;
//   late int _selectedMonth;
//   late int _selectedDay;
//   late TimeOfDay _selectedTime;
//   late ScrollController _monthScrollController;
//   late ScrollController _yearScrollController;

//   // ── Editable text controllers ──────────────────────────────────────────
//   late TextEditingController _yearController;
//   late TextEditingController _monthController;
//   late TextEditingController _dayController;

//   @override
//   void initState() {
//     super.initState();
//     final now = widget.initial ?? DateTime(2001, 3, 21);
//     _selectedYear = now.year;
//     _selectedMonth = now.month;
//     _selectedDay = now.day;
//     _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
//     _monthScrollController = ScrollController();
//     _yearScrollController = ScrollController();

//     _yearController = TextEditingController(text: _selectedYear.toString());
//     _monthController = TextEditingController(
//       text: _selectedMonth.toString().padLeft(2, '0'),
//     );
//     _dayController = TextEditingController(
//       text: _selectedDay.toString().padLeft(2, '0'),
//     );

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollToSelectedMonth();
//       _scrollToSelectedYear();
//     });
//   }

//   @override
//   void dispose() {
//     _monthScrollController.dispose();
//     _yearScrollController.dispose();
//     _yearController.dispose();
//     _monthController.dispose();
//     _dayController.dispose();
//     super.dispose();
//   }

//   void _syncControllers() {
//     _yearController.text = _selectedYear.toString();
//     _monthController.text = _selectedMonth.toString().padLeft(2, '0');
//     _dayController.text = _selectedDay.toString().padLeft(2, '0');
//   }

//   void _scrollToSelectedMonth() {
//     if (!_monthScrollController.hasClients) return;
//     const itemHeight = 44.0;
//     final offset = (_selectedMonth - 1) * itemHeight;
//     final maxScroll = _monthScrollController.position.maxScrollExtent;
//     _monthScrollController.animateTo(
//       offset.clamp(0, maxScroll),
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeOut,
//     );
//   }

//   void _scrollToSelectedYear() {
//     if (!_yearScrollController.hasClients) return;
//     const rowHeight = 40.0;
//     const yearsPerRow = 2;
//     final yearIndex = _selectedYear - widget.firstDate.year;
//     final rowIndex = yearIndex ~/ yearsPerRow;
//     final offset = rowIndex * rowHeight;
//     final maxScroll = _yearScrollController.position.maxScrollExtent;
//     _yearScrollController.animateTo(
//       (offset - 80).clamp(0, maxScroll),
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeOut,
//     );
//   }

//   int _daysInMonth(int year, int month) {
//     return DateTime(year, month + 1, 0).day;
//   }

//   void _clampDay() {
//     final maxDay = _daysInMonth(_selectedYear, _selectedMonth);
//     if (_selectedDay > maxDay) _selectedDay = maxDay;
//   }

//   DateTime get _currentDate =>
//       DateTime(_selectedYear, _selectedMonth, _selectedDay);

//   bool get _isDateValid {
//     // 1. No field should be empty
//     if (_yearController.text.isEmpty ||
//         _monthController.text.isEmpty ||
//         _dayController.text.isEmpty) {
//       return false;
//     }

//     // 2. The typed text must match the confirmed selected values.
//     //    If the user is mid-edit (typed something but hasn't submitted yet),
//     //    the texts won't match → disable the button.
//     final yearOk = int.tryParse(_yearController.text) == _selectedYear;
//     final monthOk = int.tryParse(_monthController.text) == _selectedMonth;
//     final dayOk = int.tryParse(_dayController.text) == _selectedDay;

//     if (!yearOk || !monthOk || !dayOk) return false;

//     // 3. The confirmed date must be within the allowed range
//     final d = _currentDate;
//     return !d.isBefore(widget.firstDate) && !d.isAfter(widget.lastDate);
//   }

//   String _monthName(BuildContext context, int month) {
//     return context.l10n.tr('month_$month');
//   }

//   Future<void> _pickTime() async {
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedTime,
//     );
//     if (picked != null && mounted) {
//       setState(() => _selectedTime = picked);
//     }
//   }

//   // ── Handle editable field changes ──────────────────────────────────────
//   void _onYearChanged(String value) {
//     if (value.length == 4) {
//       final y = int.tryParse(value);
//       if (y != null &&
//           y >= widget.firstDate.year &&
//           y <= widget.lastDate.year) {
//         setState(() {
//           _selectedYear = y;
//           _clampDay();
//         });
//         _scrollToSelectedYear();
//       } else {
//         // revert to last valid value
//         final cursor = _yearController.selection;
//         _yearController.text = _selectedYear.toString();
//         _yearController.selection = cursor;
//       }
//     }
//   }

//   void _onYearSubmitted(String value) {
//     final y = int.tryParse(value);
//     if (y != null && y >= widget.firstDate.year && y <= widget.lastDate.year) {
//       setState(() {
//         _selectedYear = y;
//         _clampDay();
//         _syncControllers();
//       });
//       _scrollToSelectedYear();
//     } else {
//       _yearController.text = _selectedYear.toString();
//     }
//   }

//   void _onMonthChanged(String value) {
//     final m = int.tryParse(value);
//     if (m == null) return;
//     // single digit: wait for more input unless user pressed submit
//     if (value.length == 1 && m >= 2) {
//       // auto-complete: 2-9 must be 02-09
//       if (m >= 1 && m <= 12) {
//         setState(() {
//           _selectedMonth = m;
//           _clampDay();
//         });
//         _monthController.text = m.toString().padLeft(2, '0');
//         _monthController.selection = TextSelection.collapsed(
//           offset: _monthController.text.length,
//         );
//         _scrollToSelectedMonth();
//       }
//     } else if (value.length == 2) {
//       if (m >= 1 && m <= 12) {
//         setState(() {
//           _selectedMonth = m;
//           _clampDay();
//         });
//         _scrollToSelectedMonth();
//       } else {
//         _monthController.text = _selectedMonth.toString().padLeft(2, '0');
//         _monthController.selection = TextSelection.collapsed(
//           offset: _monthController.text.length,
//         );
//       }
//     }
//   }

//   void _onMonthSubmitted(String value) {
//     final m = int.tryParse(value);
//     if (m != null && m >= 1 && m <= 12) {
//       setState(() {
//         _selectedMonth = m;
//         _clampDay();
//         _syncControllers();
//       });
//       _scrollToSelectedMonth();
//     } else {
//       _monthController.text = _selectedMonth.toString().padLeft(2, '0');
//     }
//   }

//   void _onDayChanged(String value) {
//     final d = int.tryParse(value);
//     final maxDay = _daysInMonth(_selectedYear, _selectedMonth);
//     if (d == null) return;
//     if (value.length == 1 && d > 3) {
//       // single digit > 3 must be 01-03 range auto-pad
//       if (d >= 1 && d <= maxDay) {
//         setState(() {
//           _selectedDay = d;
//         });
//         _dayController.text = d.toString().padLeft(2, '0');
//         _dayController.selection = TextSelection.collapsed(
//           offset: _dayController.text.length,
//         );
//       }
//     } else if (value.length == 2) {
//       if (d >= 1 && d <= maxDay) {
//         setState(() {
//           _selectedDay = d;
//         });
//       } else {
//         _dayController.text = _selectedDay.toString().padLeft(2, '0');
//         _dayController.selection = TextSelection.collapsed(
//           offset: _dayController.text.length,
//         );
//       }
//     }
//   }

//   void _onDaySubmitted(String value) {
//     final d = int.tryParse(value);
//     final maxDay = _daysInMonth(_selectedYear, _selectedMonth);
//     if (d != null && d >= 1 && d <= maxDay) {
//       setState(() {
//         _selectedDay = d;
//         _syncControllers();
//       });
//     } else {
//       _dayController.text = _selectedDay.toString().padLeft(2, '0');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final title = widget.title ?? context.l10n.tr('home_date_time');

//     return Container(
//       constraints: const BoxConstraints(maxWidth: 660),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(AppSize.size16),
//         border: Border.all(color: AppColors.grayE2E8F0),
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // ── Header ──────────────────────────────────────────────────────
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: AppFontStyle.semiBold18(
//                       context,
//                     ).copyWith(color: AppColors.surface72A),
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   icon: const Icon(Icons.close, size: 20),
//                   visualDensity: VisualDensity.compact,
//                   color: AppColors.gray94A3B8,
//                 ),
//               ],
//             ),
//           ),

//           const Divider(height: 1, color: AppColors.grayE2E8F0),

//           // ── Three-panel row ──────────────────────────────────────────────
//           SizedBox(
//             height: 260,
//             child: Row(
//               children: [
//                 Expanded(flex: 5, child: _buildCalendarPanel()),
//                 Container(width: 1, color: AppColors.grayE2E8F0),
//                 Expanded(flex: 3, child: _buildMonthPanel()),
//                 Container(width: 1, color: AppColors.grayE2E8F0),
//                 Expanded(flex: 3, child: _buildYearPanel()),
//               ],
//             ),
//           ),

//           const Divider(height: 1, color: AppColors.grayE2E8F0),

//           // ── Bottom bar ──────────────────────────────────────────────────
//           _buildBottomBar(),
//         ],
//       ),
//     );
//   }

//   // ─── Calendar Panel ─────────────────────────────────────────────────────────

//   Widget _buildCalendarPanel() {
//     final daysInMonth = _daysInMonth(_selectedYear, _selectedMonth);
//     final firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday;
//     final startOffset = firstWeekday % 7;

//     return Padding(
//       padding: const EdgeInsets.all(8),
//       child: Column(
//         children: [
//           Row(
//             children: _dayHeaders
//                 .map(
//                   (d) => Expanded(
//                     child: Center(
//                       child: Text(
//                         d,
//                         style: AppFontStyle.medium12(
//                           context,
//                         ).copyWith(color: AppColors.gray94A3B8),
//                       ),
//                     ),
//                   ),
//                 )
//                 .toList(),
//           ),
//           const SizedBox(height: 4),
//           Expanded(
//             child: GridView.builder(
//               padding: EdgeInsets.zero,
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 7,
//                 childAspectRatio: 1.1,
//               ),
//               itemCount: startOffset + daysInMonth,
//               itemBuilder: (context, index) {
//                 if (index < startOffset) return const SizedBox.shrink();
//                 final day = index - startOffset + 1;
//                 final isSelected = day == _selectedDay;
//                 return GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _selectedDay = day;
//                       _syncControllers();
//                     });
//                   },
//                   child: Container(
//                     alignment: Alignment.center,
//                     decoration: isSelected
//                         ? BoxDecoration(
//                             color: AppColors.primary.withValues(alpha: 0.15),
//                             shape: BoxShape.circle,
//                           )
//                         : null,
//                     child: Text(
//                       '$day',
//                       style: TextStyle(
//                         color: isSelected
//                             ? AppColors.primary
//                             : AppColors.surface72A,
//                         fontSize: 13,
//                         fontWeight: isSelected
//                             ? FontWeight.bold
//                             : FontWeight.normal,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── Month Panel ────────────────────────────────────────────────────────────

//   Widget _buildMonthPanel() {
//     return ListView.builder(
//       controller: _monthScrollController,
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       itemCount: 12,
//       itemExtent: 44,
//       itemBuilder: (context, index) {
//         final month = index + 1;
//         final isSelected = month == _selectedMonth;
//         final monthLabel =
//             '${month.toString().padLeft(2, '0')} - ${_monthName(context, month)}';
//         return GestureDetector(
//           onTap: () {
//             setState(() {
//               _selectedMonth = month;
//               _clampDay();
//               _syncControllers();
//             });
//             _scrollToSelectedMonth();
//           },
//           child: Container(
//             alignment: Alignment.center,
//             color: isSelected
//                 ? AppColors.primary.withValues(alpha: 0.1)
//                 : Colors.transparent,
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             child: Text(
//               monthLabel,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: isSelected ? AppColors.primary : AppColors.surface72A,
//                 fontSize: 13,
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ─── Year Panel ─────────────────────────────────────────────────────────────

//   Widget _buildYearPanel() {
//     final firstYear = widget.firstDate.year;
//     final lastYear = widget.lastDate.year;
//     final totalYears = lastYear - firstYear + 1;

//     return GridView.builder(
//       controller: _yearScrollController,
//       padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 2.2,
//       ),
//       itemCount: totalYears,
//       itemBuilder: (context, index) {
//         final year = firstYear + index;
//         final isSelected = year == _selectedYear;
//         return GestureDetector(
//           onTap: () {
//             setState(() {
//               _selectedYear = year;
//               _clampDay();
//               _syncControllers();
//             });
//             _scrollToSelectedYear();
//           },
//           child: Container(
//             alignment: Alignment.center,
//             margin: const EdgeInsets.all(2),
//             decoration: BoxDecoration(
//               color: isSelected
//                   ? AppColors.primary.withValues(alpha: 0.1)
//                   : Colors.transparent,
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Text(
//               '$year',
//               style: TextStyle(
//                 color: isSelected ? AppColors.primary : AppColors.surface72A,
//                 fontSize: 13,
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ─── Bottom Bar ─────────────────────────────────────────────────────────────

//   Widget _buildBottomBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: Row(
//         children: [
//           // ── Confirm button ─────────────────────────────────────────────
//           CustomButton(
//             title: context.l10n.tr('confirm'),
//             enabled: _isDateValid,
//             width: 100,
//             height: 40,
//             borderRadius: 8,
//             titleStyle: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: AppColors.white,
//             ),
//             onTap: () {
//               final result = widget.dateOnly || !widget.showTime
//                   ? _currentDate
//                   : DateTime(
//                       _selectedYear,
//                       _selectedMonth,
//                       _selectedDay,
//                       _selectedTime.hour,
//                       _selectedTime.minute,
//                     );
//               Navigator.of(context).pop(result);
//             },
//           ),

//           // ── Time button (only for datetime mode) ──────────────────────
//           if (!widget.dateOnly && widget.showTime) ...[
//             const SizedBox(width: 10),
//             GestureDetector(
//               onTap: _pickTime,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(6),
//                   border: Border.all(color: AppColors.grayE2E8F0),
//                 ),
//                 child: Text(
//                   _selectedTime.format(context),
//                   style: AppFontStyle.semiBold14(
//                     context,
//                   ).copyWith(color: AppColors.surface72A),
//                 ),
//               ),
//             ),
//           ],

//           const Spacer(),

//           // ── Editable date fields (YYYY - MM - DD) ─────────────────────
//           _buildEditableField(
//             controller: _yearController,
//             width: 60,
//             maxLength: 4,
//             onSubmitted: _onYearSubmitted,
//             onChanged: _onYearChanged,
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: Text(
//               '-',
//               style: AppFontStyle.bold18(
//                 context,
//               ).copyWith(color: AppColors.surface72A),
//             ),
//           ),
//           _buildEditableField(
//             controller: _monthController,
//             width: 36,
//             maxLength: 2,
//             onSubmitted: _onMonthSubmitted,
//             onChanged: _onMonthChanged,
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: Text(
//               '-',
//               style: AppFontStyle.bold18(
//                 context,
//               ).copyWith(color: AppColors.surface72A),
//             ),
//           ),
//           _buildEditableField(
//             controller: _dayController,
//             width: 36,
//             maxLength: 2,
//             onSubmitted: _onDaySubmitted,
//             onChanged: _onDayChanged,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEditableField({
//     required TextEditingController controller,
//     required double width,
//     required int maxLength,
//     required ValueChanged<String> onSubmitted,
//     ValueChanged<String>? onChanged,
//   }) {
//     return SizedBox(
//       width: width,
//       child: TextField(
//         controller: controller,
//         textAlign: TextAlign.center,
//         keyboardType: TextInputType.number,
//         maxLength: maxLength,
//         style: AppFontStyle.bold16(
//           context,
//         ).copyWith(color: AppColors.surface72A),
//         decoration: InputDecoration(
//           counterText: '',
//           isDense: true,
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 4,
//             vertical: 8,
//           ),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(6),
//             borderSide: BorderSide(color: AppColors.grayE2E8F0),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(6),
//             borderSide: BorderSide(color: AppColors.grayE2E8F0),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(6),
//             borderSide: BorderSide(color: AppColors.primary, width: 1.5),
//           ),
//         ),
//         onSubmitted: onSubmitted,
//         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//         onChanged: onChanged,
//         onEditingComplete: () {
//           onSubmitted(controller.text);
//           FocusScope.of(context).unfocus();
//         },
//       ),
//     );
//   }
// }

// class AppDateTimeField extends StatelessWidget {
//   const AppDateTimeField({
//     super.key,
//     required this.label,
//     required this.value,
//     required this.onTap,
//     this.hintText,
//     this.onClear,
//   });

//   final String label;
//   final String value;
//   final VoidCallback onTap;
//   final String? hintText;
//   final VoidCallback? onClear;

//   @override
//   Widget build(BuildContext context) {
//     final effectiveHint = hintText ?? context.l10n.tr('home_date_time_hint');
//     final isEmpty = value.isEmpty;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (label.isNotEmpty) ...[
//           Text(
//             label,
//             style: AppFontStyle.medium16(
//               context,
//             ).copyWith(color: AppColors.textSecondary569),
//           ),
//           const SizedBox(height: 8),
//         ],
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//             decoration: BoxDecoration(
//               border: Border.all(color: AppColors.grayE2E8F0),
//               borderRadius: BorderRadius.circular(AppSize.borderRadiusSize12),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     isEmpty ? effectiveHint : value,
//                     style: AppFontStyle.regular14(context).copyWith(
//                       color: isEmpty
//                           ? AppColors.gray94A3B8
//                           : AppColors.surface72A,
//                     ),
//                   ),
//                 ),
//                 if (!isEmpty && onClear != null) ...[
//                   GestureDetector(
//                     onTap: onClear,
//                     behavior: HitTestBehavior.opaque,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 4.0),
//                       child: Icon(
//                         Icons.close,
//                         size: 18,
//                         color: AppColors.red29,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 4),
//                 ],
//                 AppImage.asset(
//                   path: AppAssets.calendarChip,
//                   height: 20,
//                   width: 20,
//                   colorFilter: ColorFilter.mode(
//                     isEmpty
//                         ? AppColors.textSecondary569
//                         : AppColors.textSecondary569,
//                     BlendMode.srcIn,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
