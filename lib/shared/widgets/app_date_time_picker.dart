import 'package:easy_localization/easy_localization.dart' as ez;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';

// ─── Public API ───────────────────────────────────────────────────────────────

/// Shows a custom date-only picker dialog with Year, Month, and Day panels.
/// Returns the selected [DateTime] or `null` if cancelled.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  DateTime? initial,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
  bool allowFuture = false,
}) {
  final now = CairoTimeHelper.now();
  final effectiveLastDate = allowFuture ? (lastDate ?? DateTime(2100)) : (lastDate ?? now);
  final effectiveFirstDate = firstDate ?? DateTime(1900, 1, 1);

  return showDialog<DateTime>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => _AppDateTimePickerDialog(
      initial: initial,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      title: title,
      dateOnly: true,
      showTime: false,
    ),
  );
}

/// Shows a custom date+time picker dialog.
/// Returns the selected [DateTime] or `null` if cancelled.
Future<DateTime?> showAppDateTimePicker(
  BuildContext context, {
  DateTime? initial,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
  bool showTime = true,
  bool allowFuture = true,
}) {
  final now = CairoTimeHelper.now();
  final effectiveLastDate = allowFuture ? (lastDate ?? DateTime(2100)) : (lastDate ?? now);
  final effectiveFirstDate = firstDate ?? DateTime(2020, 1, 1);

  return showDialog<DateTime>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => _AppDateTimePickerDialog(
      initial: initial,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      title: title,
      dateOnly: !showTime,
      showTime: showTime,
    ),
  );
}

// ─── Constants ────────────────────────────────────────────────────────────────

const List<String> _dayHeaders = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];

const List<String> _arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

// ─── Dialog Widget ────────────────────────────────────────────────────────────

class _AppDateTimePickerDialog extends StatefulWidget {
  const _AppDateTimePickerDialog({
    this.initial,
    required this.firstDate,
    required this.lastDate,
    this.title,
    this.dateOnly = false,
    this.showTime = true,
  });

  final DateTime? initial;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? title;
  final bool dateOnly;
  final bool showTime;

  @override
  State<_AppDateTimePickerDialog> createState() =>
      _AppDateTimePickerDialogState();
}

class _AppDateTimePickerDialogState extends State<_AppDateTimePickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  late TimeOfDay _selectedTime;
  late ScrollController _monthScrollController;
  late ScrollController _yearScrollController;

  late TextEditingController _yearController;
  late TextEditingController _monthController;
  late TextEditingController _dayController;

  @override
  void initState() {
    super.initState();
    final init = widget.initial ?? CairoTimeHelper.now();
    // Clamp initial date within bounds
    final clamped = init.isBefore(widget.firstDate)
        ? widget.firstDate
        : (init.isAfter(widget.lastDate) ? widget.lastDate : init);

    _selectedYear = clamped.year;
    _selectedMonth = clamped.month;
    _selectedDay = clamped.day;
    _selectedTime = TimeOfDay(hour: clamped.hour, minute: clamped.minute);

    _monthScrollController = ScrollController();
    _yearScrollController = ScrollController();

    _yearController = TextEditingController(text: _selectedYear.toString());
    _monthController = TextEditingController(
      text: _selectedMonth.toString().padLeft(2, '0'),
    );
    _dayController = TextEditingController(
      text: _selectedDay.toString().padLeft(2, '0'),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedMonth();
      _scrollToSelectedYear();
    });
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    _yearScrollController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _yearController.text = _selectedYear.toString();
    _monthController.text = _selectedMonth.toString().padLeft(2, '0');
    _dayController.text = _selectedDay.toString().padLeft(2, '0');
  }

  void _scrollToSelectedMonth() {
    if (!_monthScrollController.hasClients) return;
    const itemHeight = 44.0;
    final offset = (_selectedMonth - 1) * itemHeight;
    final maxScroll = _monthScrollController.position.maxScrollExtent;
    _monthScrollController.animateTo(
      offset.clamp(0, maxScroll),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _scrollToSelectedYear() {
    if (!_yearScrollController.hasClients) return;
    const rowHeight = 36.0;
    const yearsPerRow = 2;
    final yearIndex = _selectedYear - widget.firstDate.year;
    final rowIndex = yearIndex ~/ yearsPerRow;
    final offset = rowIndex * rowHeight;
    final maxScroll = _yearScrollController.position.maxScrollExtent;
    _yearScrollController.animateTo(
      (offset - 60).clamp(0, maxScroll),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _clampDay() {
    final maxDay = _daysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay > maxDay) _selectedDay = maxDay;
  }

  DateTime get _currentDate =>
      DateTime(_selectedYear, _selectedMonth, _selectedDay);

  bool get _isDateValid {
    if (_yearController.text.isEmpty ||
        _monthController.text.isEmpty ||
        _dayController.text.isEmpty) {
      return false;
    }
    final yearOk = int.tryParse(_yearController.text) == _selectedYear;
    final monthOk = int.tryParse(_monthController.text) == _selectedMonth;
    final dayOk = int.tryParse(_dayController.text) == _selectedDay;

    if (!yearOk || !monthOk || !dayOk) return false;

    final d = _currentDate;
    return !d.isBefore(widget.firstDate) && !d.isAfter(widget.lastDate);
  }

  String _monthName(int month) {
    if (month >= 1 && month <= 12) {
      return _arabicMonths[month - 1];
    }
    return '';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  void _onYearChanged(String value) {
    if (value.length == 4) {
      final y = int.tryParse(value);
      if (y != null &&
          y >= widget.firstDate.year &&
          y <= widget.lastDate.year) {
        setState(() {
          _selectedYear = y;
          _clampDay();
        });
        _scrollToSelectedYear();
      }
    }
  }

  void _onYearSubmitted(String value) {
    final y = int.tryParse(value);
    if (y != null && y >= widget.firstDate.year && y <= widget.lastDate.year) {
      setState(() {
        _selectedYear = y;
        _clampDay();
        _syncControllers();
      });
      _scrollToSelectedYear();
    } else {
      _yearController.text = _selectedYear.toString();
    }
  }

  void _onMonthChanged(String value) {
    final m = int.tryParse(value);
    if (m == null) return;
    if (value.length == 2 && m >= 1 && m <= 12) {
      setState(() {
        _selectedMonth = m;
        _clampDay();
      });
      _scrollToSelectedMonth();
    }
  }

  void _onMonthSubmitted(String value) {
    final m = int.tryParse(value);
    if (m != null && m >= 1 && m <= 12) {
      setState(() {
        _selectedMonth = m;
        _clampDay();
        _syncControllers();
      });
      _scrollToSelectedMonth();
    } else {
      _monthController.text = _selectedMonth.toString().padLeft(2, '0');
    }
  }

  void _onDayChanged(String value) {
    final d = int.tryParse(value);
    final maxDay = _daysInMonth(_selectedYear, _selectedMonth);
    if (d == null) return;
    if (value.length == 2 && d >= 1 && d <= maxDay) {
      setState(() {
        _selectedDay = d;
      });
    }
  }

  void _onDaySubmitted(String value) {
    final d = int.tryParse(value);
    final maxDay = _daysInMonth(_selectedYear, _selectedMonth);
    if (d != null && d >= 1 && d <= maxDay) {
      setState(() {
        _selectedDay = d;
        _syncControllers();
      });
    } else {
      _dayController.text = _selectedDay.toString().padLeft(2, '0');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final title = widget.title ?? 'تاريخ الميلاد';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: CustomAppFontStyle.bold16.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      visualDensity: VisualDensity.compact,
                      color: colors.textSecondary,
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: colors.borderSubtle),

              // ── Three-panel row (Right: Days | Mid: Months | Left: Years) ─
              SizedBox(
                height: 270,
                child: Row(
                  children: [
                    // Right panel (Days Calendar)
                    Expanded(flex: 5, child: _buildCalendarPanel()),
                    Container(width: 1, color: colors.borderSubtle),
                    // Middle panel (Months)
                    Expanded(flex: 3, child: _buildMonthPanel()),
                    Container(width: 1, color: colors.borderSubtle),
                    // Left panel (Years)
                    Expanded(flex: 3, child: _buildYearPanel()),
                  ],
                ),
              ),

              Divider(height: 1, color: colors.borderSubtle),

              // ── Bottom Bar ──────────────────────────────────────────────
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Calendar Panel (Days) ──────────────────────────────────────────────────

  Widget _buildCalendarPanel() {
    final colors = context.themeColors;
    final daysInMonth = _daysInMonth(_selectedYear, _selectedMonth);
    // Sunday is index 0 in _dayHeaders ('ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س')
    final firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday;
    final startOffset = firstWeekday % 7;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: _dayHeaders
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.15,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: startOffset + daysInMonth,
              itemBuilder: (context, index) {
                if (index < startOffset) return const SizedBox.shrink();
                final day = index - startOffset + 1;
                final isSelected = day == _selectedDay;

                final dayDate = DateTime(_selectedYear, _selectedMonth, day);
                final isDisabled = dayDate.isBefore(widget.firstDate) ||
                    dayDate.isAfter(widget.lastDate);

                return InkWell(
                  onTap: isDisabled
                      ? null
                      : () {
                          setState(() {
                            _selectedDay = day;
                            _syncControllers();
                          });
                        },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: isSelected
                        ? BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Text(
                      '$day',
                      style: isSelected
                          ? CustomAppFontStyle.bold13.copyWith(
                              color: Colors.white,
                            )
                          : CustomAppFontStyle.regular13.copyWith(
                              color: isDisabled
                                  ? colors.textMuted.withValues(alpha: 0.4)
                                  : colors.textPrimary,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Month Panel ────────────────────────────────────────────────────────────

  Widget _buildMonthPanel() {
    final colors = context.themeColors;
    return ListView.builder(
      controller: _monthScrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: 12,
      itemExtent: 44,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelected = month == _selectedMonth;
        final monthLabel =
            '${month.toString().padLeft(2, '0')} - ${_monthName(month)}';

        return InkWell(
          onTap: () {
            setState(() {
              _selectedMonth = month;
              _clampDay();
              _syncControllers();
            });
            _scrollToSelectedMonth();
          },
          child: Container(
            alignment: Alignment.center,
            color: isSelected
                ? colors.primaryLight
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              monthLabel,
              textAlign: TextAlign.center,
              style: isSelected
                  ? CustomAppFontStyle.bold13.copyWith(
                      color: colors.primary,
                    )
                  : CustomAppFontStyle.regular13.copyWith(
                      color: colors.textPrimary,
                    ),
            ),
          ),
        );
      },
    );
  }

  // ─── Year Panel ─────────────────────────────────────────────────────────────

  Widget _buildYearPanel() {
    final colors = context.themeColors;
    final firstYear = widget.firstDate.year;
    final lastYear = widget.lastDate.year;
    final totalYears = lastYear - firstYear + 1;

    return GridView.builder(
      controller: _yearScrollController,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.1,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: totalYears,
      itemBuilder: (context, index) {
        final year = firstYear + index;
        final isSelected = year == _selectedYear;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedYear = year;
              _clampDay();
              _syncControllers();
            });
            _scrollToSelectedYear();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? colors.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$year',
              style: isSelected
                  ? CustomAppFontStyle.bold13.copyWith(
                      color: colors.primary,
                    )
                  : CustomAppFontStyle.regular13.copyWith(
                      color: colors.textPrimary,
                    ),
            ),
          ),
        );
      },
    );
  }

  // ─── Bottom Bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final colors = context.themeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // ── Editable date boxes: [ Day ] - [ Month ] - [ Year ] ─────────
          _buildEditableField(
            controller: _dayController,
            width: 44,
            maxLength: 2,
            onSubmitted: _onDaySubmitted,
            onChanged: _onDayChanged,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '-',
              style: CustomAppFontStyle.bold16.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          _buildEditableField(
            controller: _monthController,
            width: 44,
            maxLength: 2,
            onSubmitted: _onMonthSubmitted,
            onChanged: _onMonthChanged,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '-',
              style: CustomAppFontStyle.bold16.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          _buildEditableField(
            controller: _yearController,
            width: 64,
            maxLength: 4,
            onSubmitted: _onYearSubmitted,
            onChanged: _onYearChanged,
          ),

          // ── Time button (if showTime) ──────────────────────────────────
          if (!widget.dateOnly && widget.showTime) ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceLevel1,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedTime.format(context),
                      style: CustomAppFontStyle.medium13.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const Spacer(),

          // ── Confirm button ─────────────────────────────────────────────
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 100),
            child: ElevatedButton(
              onPressed: _isDateValid
                  ? () {
                      final result = widget.dateOnly || !widget.showTime
                          ? _currentDate
                          : DateTime(
                              _selectedYear,
                              _selectedMonth,
                              _selectedDay,
                              _selectedTime.hour,
                              _selectedTime.minute,
                            );
                      Navigator.of(context).pop(result);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                disabledBackgroundColor: colors.fillDisabled,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'confirm'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required double width,
    required int maxLength,
    required ValueChanged<String> onSubmitted,
    ValueChanged<String>? onChanged,
  }) {
    final colors = context.themeColors;
    return SizedBox(
      width: width,
      height: 38,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: maxLength,
        style: CustomAppFontStyle.bold14.copyWith(
          color: colors.textPrimary,
        ),
        cursorColor: colors.primary,
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          filled: true,
          fillColor: colors.inputBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.primary, width: 1.5),
          ),
        ),
        onSubmitted: onSubmitted,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        onEditingComplete: () {
          onSubmitted(controller.text);
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }
}
