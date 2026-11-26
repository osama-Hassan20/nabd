import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/conflict_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/store/transactional_local_store.dart';
import 'package:eyadty/core/offline/sync/sync_engine.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

class SyncReviewDialog extends StatefulWidget {
  final bool isBlockingGate;

  const SyncReviewDialog({
    super.key,
    this.isBlockingGate = false,
  });

  static Future<void> show(BuildContext context, {bool isBlockingGate = false}) {
    return showDialog(
      context: context,
      barrierDismissible: !isBlockingGate,
      builder: (ctx) => SyncReviewDialog(isBlockingGate: isBlockingGate),
    );
  }

  @override
  State<SyncReviewDialog> createState() => _SyncReviewDialogState();
}

class _SyncReviewDialogState extends State<SyncReviewDialog> {
  List<OutboxEntry> _entries = [];
  List<ConflictRecord> _conflicts = [];
  final Set<String> _selectedOpIds = {};
  bool _isLoading = false;
  double _syncProgress = 0.0;
  String? _syncStatusMessage;

  static const Map<String, String> sectionTitles = {
    'patient': 'المرضى',
    'booking': 'الحجوزات والمواعيد',
    'visit': 'الزيارات الطبية',
    'drug': 'الأدوية والمستحضرات',
    'doctor': 'الأطباء والجداول',
    'inventory': 'المخزون والمستلزمات',
    'cashier': 'الخزينة والورديات',
    'payment': 'المدفوعات',
    'hr': 'الموارد البشرية',
    'hr_advance': 'السلف والخصومات',
    'hr_payroll': 'مسير الرواتب',
    'settings': 'إعدادات النظام والعيادة',
    'staff_user': 'المستخدمون والصلاحيات',
    'medical_catalog': 'الكتالوجات الطبية',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!getIt.isRegistered<TransactionalLocalStore>()) return;
    final store = getIt<TransactionalLocalStore>();
    final allEntries = await store.getAllOutboxEntries();
    final pendingOrFailed = allEntries
        .where((e) => e.status != OutboxStatus.acknowledged)
        .toList();
    final conflicts = await store.getUnresolvedConflicts();

    if (mounted) {
      setState(() {
        _entries = pendingOrFailed;
        _conflicts = conflicts;
        // Select all by default
        _selectedOpIds.clear();
        _selectedOpIds.addAll(pendingOrFailed.map((e) => e.operationId));
      });
    }
  }

  String _describeChange(OutboxEntry entry) {
    final typeName = sectionTitles[entry.entityType] ?? entry.entityType;
    final op = entry.operation;
    final payload = entry.payload;

    if (entry.entityType == 'patient') {
      final name = payload['name'] ?? payload['fullName'] ?? entry.localId;
      if (op == OutboxOperationType.create) return 'إضافة مريض جديد: $name';
      if (op == OutboxOperationType.update) return 'تعديل بيانات مريض: $name';
      if (op == OutboxOperationType.delete) return 'أرشفة مريض: $name';
    }
    if (entry.entityType == 'booking') {
      final status = payload['status'] ?? '';
      if (op == OutboxOperationType.create) return 'إنشاء حجز جديد ($status)';
      if (op == OutboxOperationType.update) {
        if (status == 'noShow') return 'تغيير حالة حجز إلى: لم يحضر';
        if (status == 'completed') return 'تغيير حالة حجز إلى: مكتمل';
        if (status == 'cancelled') return 'إلغاء حجز';
        return 'تعديل بيانات حجز ($status)';
      }
      if (op == OutboxOperationType.delete) return 'حذف حجز';
    }
    if (entry.entityType == 'drug') {
      final name = payload['tradeName'] ?? payload['name'] ?? entry.localId;
      if (op == OutboxOperationType.create) return 'إضافة دواء جديد: $name';
      if (op == OutboxOperationType.update) return 'تعديل دواء: $name';
      if (op == OutboxOperationType.delete) return 'أرشفة دواء: $name';
    }
    if (entry.entityType == 'inventory') {
      final name = payload['itemName'] ?? payload['name'] ?? entry.localId;
      final qty = payload['quantity'] ?? payload['stock'] ?? '';
      if (op == OutboxOperationType.create) return 'إضافة صنف مخزون: $name';
      if (op == OutboxOperationType.update) return 'حركة مخزون: $name ($qty)';
      if (op == OutboxOperationType.delete) return 'حذف صنف مخزون: $name';
    }
    if (entry.entityType == 'hr_advance') {
      final amount = payload['amount'] ?? '';
      final user = payload['employeeName'] ?? payload['userId'] ?? '';
      return 'حركة سلفة / خصم: $amount ج.م لـ $user';
    }
    if (entry.entityType == 'hr_payroll') {
      final period = payload['period'] ?? '';
      return 'إصدار مسير رواتب لشهر $period';
    }
    if (entry.entityType == 'cashier') {
      if (op == OutboxOperationType.create) return 'فتح وردية خزينة جديدة';
      if (op == OutboxOperationType.update) return 'إغلاق أو تعديل وردية';
    }
    final opName = op == OutboxOperationType.create
        ? 'إضافة'
        : op == OutboxOperationType.update
            ? 'تعديل'
            : 'حذف';
    return '$opName في $typeName (${entry.localId})';
  }

  void _toggleSelection(OutboxEntry entry, bool selected) {
    setState(() {
      if (selected) {
        _selectedOpIds.add(entry.operationId);
        // Auto-include parent dependencies
        for (final dep in entry.dependencyRefs) {
          final parent = _entries
              .where((e) =>
                  '${e.entityType}:${e.localId}' == dep || e.localId == dep)
              .firstOrNull;
          if (parent != null) {
            _selectedOpIds.add(parent.operationId);
          }
        }
      } else {
        _selectedOpIds.remove(entry.operationId);
        // Unselect any dependents that depend on this
        final ref1 = '${entry.entityType}:${entry.localId}';
        final ref2 = entry.localId;
        final dependents = _entries.where((e) =>
            e.dependencyRefs.contains(ref1) || e.dependencyRefs.contains(ref2));
        for (final dep in dependents) {
          _selectedOpIds.remove(dep.operationId);
        }
      }
    });
  }

  Future<void> _handleSyncSelected() async {
    if (!getIt.isRegistered<SyncEngine>() || _selectedOpIds.isEmpty) return;
    setState(() {
      _isLoading = true;
      _syncProgress = 0.3;
      _syncStatusMessage = 'جار رفع التغييرات المحددة...';
    });

    final engine = getIt<SyncEngine>();
    await engine.syncNow(operationIds: _selectedOpIds.toList());

    if (mounted) {
      setState(() {
        _syncProgress = 1.0;
        _isLoading = false;
        _syncStatusMessage = null;
      });
      await _loadData();
      if (_entries.isEmpty && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleSyncAll() async {
    if (!getIt.isRegistered<SyncEngine>()) return;
    setState(() {
      _isLoading = true;
      _syncProgress = 0.2;
      _syncStatusMessage = 'جار رفع جميع التغييرات...';
    });

    final engine = getIt<SyncEngine>();
    await engine.syncNow();

    if (mounted) {
      setState(() {
        _syncProgress = 1.0;
        _isLoading = false;
        _syncStatusMessage = null;
      });
      await _loadData();
      if (_entries.isEmpty && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleDiscardOperation(OutboxEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد التراجع والتجاهل'),
        content: Text(
          'هل أنت متأكد من تجاهل هذا التغيير (${_describeChange(entry)})؟ سيتم التراجع محلياً إلى النسخة المعتمدة الأخيرة أو حذفه إن لم يكن قد رُفع مسبقاً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تأكيد التراجع', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && getIt.isRegistered<SyncEngine>()) {
      setState(() => _isLoading = true);
      await getIt<SyncEngine>().discardOperation(entry.operationId, discardDependents: true);
      await _loadData();
      setState(() => _isLoading = false);
      if (_entries.isEmpty && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleDiscardSection(String entityType) async {
    final title = sectionTitles[entityType] ?? entityType;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد تجاهل قسم $title'),
        content: Text(
          'هل أنت متأكد من تجاهل جميع التغييرات المحلية في قسم "$title"؟ سيتم استرجاع الحالات السابقة للمزامنة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تجاهل القسم بالكامل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && getIt.isRegistered<SyncEngine>()) {
      setState(() => _isLoading = true);
      await getIt<SyncEngine>().discardSection(entityType);
      await _loadData();
      setState(() => _isLoading = false);
      if (_entries.isEmpty && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showDetailsDialog(OutboxEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_describeChange(entry)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'المعرف المحلي: ${entry.localId} (${entry.entityType})',
                  style: CustomAppFontStyle.bold12,
                ),
                Text(
                  'التاريخ: ${entry.createdAt}',
                  style: CustomAppFontStyle.regular12.copyWith(color: AppColors.gray),
                ),
                const SizedBox(height: 12),
                if (entry.previousPayload != null) ...[
                  Text('البيانات قبل التعديل:', style: CustomAppFontStyle.bold12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.grayE2E8F0.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      const JsonEncoder.withIndent('  ').convert(entry.previousPayload),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text('البيانات الحالية المراد مزامنتها:', style: CustomAppFontStyle.bold12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(entry.payload),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group entries by section
    final grouped = <String, List<OutboxEntry>>{};
    for (final entry in _entries) {
      grouped.putIfAbsent(entry.entityType, () => []).add(entry);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.grayE2E8F0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.cloud_sync_rounded,
                        color: Color(0xFFD97706),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مراجعة ومزامنة التغييرات المعلقة',
                          style: CustomAppFontStyle.bold16.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          'توجد ${_entries.length} تغييرات محلية تحتاج مراجعتك قبل المتابعة في وضع الاتصال.',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isBlockingGate)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoading) ...[
                LinearProgressIndicator(value: _syncProgress > 0 ? _syncProgress : null),
                if (_syncStatusMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _syncStatusMessage!,
                    style: CustomAppFontStyle.medium11.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
              ],

              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 12),

              // Content List
              Expanded(
                child: _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _conflicts.isNotEmpty
                                  ? 'توجد ${_conflicts.length} تعارضات تحتاج إلى مراجعة'
                                  : 'تمت مزامنة كافة التغييرات بنجاح!',
                              style: CustomAppFontStyle.bold14.copyWith(
                                color: _conflicts.isNotEmpty ? AppColors.warning : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: grouped.keys.length,
                        itemBuilder: (context, index) {
                          final sectionKey = grouped.keys.elementAt(index);
                          final sectionItems = grouped[sectionKey]!;
                          final sectionName = sectionTitles[sectionKey] ?? sectionKey;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: AppColors.grayF8FAFC,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.grayE2E8F0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Section Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.grayE2E8F0.withValues(alpha: 0.5),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(15),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        sectionName,
                                        style: CustomAppFontStyle.bold14.copyWith(
                                          color: AppColors.darkText,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.grayE2E8F0),
                                        ),
                                        child: Text(
                                          '${sectionItems.length} تغييرات',
                                          style: CustomAppFontStyle.medium10.copyWith(
                                            color: AppColors.gray,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: _isLoading ? null : () => _handleDiscardSection(sectionKey),
                                        child: Text(
                                          'تجاهل القسم',
                                          style: CustomAppFontStyle.medium11.copyWith(color: AppColors.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Rows
                                ...sectionItems.map((entry) {
                                  final isSelected = _selectedOpIds.contains(entry.operationId);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: AppColors.grayE2E8F0, width: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (val) => _toggleSelection(entry, val ?? false),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _describeChange(entry),
                                                style: CustomAppFontStyle.medium12.copyWith(
                                                  color: AppColors.darkText,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text(
                                                    DateFormat('HH:mm - yyyy/MM/dd').format(entry.createdAt),
                                                    style: CustomAppFontStyle.regular10.copyWith(
                                                      color: AppColors.gray,
                                                    ),
                                                  ),
                                                  if (entry.lastError != null) ...[
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        entry.lastError!,
                                                        style: CustomAppFontStyle.regular10.copyWith(
                                                          color: AppColors.error,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          tooltip: 'عرض التفاصيل',
                                          icon: const Icon(Icons.info_outline_rounded, size: 18),
                                          onPressed: () => _showDetailsDialog(entry),
                                        ),
                                        IconButton(
                                          tooltip: 'تجاهل هذا التغيير',
                                          icon: const Icon(Icons.undo_rounded, size: 18, color: AppColors.error),
                                          onPressed: _isLoading ? null : () => _handleDiscardOperation(entry),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),

              // Bottom Actions
              Row(
                children: [
                  // Stay in local mode
                  OutlinedButton.icon(
                    key: const Key('sync_review_stay_local_btn'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                    icon: const Icon(Icons.cloud_off_rounded, size: 18, color: Color(0xFFD97706)),
                    label: Text(
                      'البقاء في الوضع المحلي',
                      style: CustomAppFontStyle.bold12.copyWith(color: const Color(0xFFD97706)),
                    ),
                    onPressed: () {
                      if (getIt.isRegistered<DataModeService>()) {
                        getIt<DataModeService>().setForcedLocal(true);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                  const Spacer(),
                  if (_selectedOpIds.length < _entries.length && _selectedOpIds.isNotEmpty) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: _isLoading ? null : _handleSyncSelected,
                      child: Text('مزامنة المحدد (${_selectedOpIds.length})'),
                    ),
                    const SizedBox(width: 10),
                  ],
                  CustomPushButton(
                    key: const Key('sync_review_sync_all_btn'),
                    label: 'مزامنة الكل (${_entries.length})',
                    isLoading: _isLoading,
                    onTap: _entries.isEmpty || _isLoading ? null : _handleSyncAll,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
