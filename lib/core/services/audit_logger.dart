import '../../features/users_management/data/models/security_audit_log_model.dart';
import '../utils/helpers/cairo_time_helper.dart';

abstract class AuditLogger {
  void log({
    required String eventType,
    String? targetUserId,
    String? targetUserName,
    String? performedByUserId,
    String? performedByUserName,
    String? branchId,
    String? branchName,
    String? details,
    String? ipAddress,
  });

  List<SecurityAuditLogModel> getLogs({
    String? targetUserId,
    String? performedByUserId,
    String? eventType,
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? limit,
    int? offset,
  });
}

class InMemoryAuditLogger implements AuditLogger {
  final List<SecurityAuditLogModel> _logs = [];
  int _counter = 1;

  InMemoryAuditLogger({bool seedInitialLogs = true}) {
    if (seedInitialLogs) {
      _initSeedLogs();
    }
  }

  static final RegExp _sensitiveKeywords = RegExp(
    r'(password|passwd|token|jwt|secret|key|pin|bearer)\s*[:=]\s*([^\s,;]+)',
    caseSensitive: false,
  );

  void _initSeedLogs() {
    final baseTime = CairoTimeHelper.now();

    final seeds = [
      SecurityAuditLogModel(
        id: 'AUD-1001',
        eventType: 'login_success',
        performedByUserId: 'usr_owner_01',
        performedByUserName: 'د. خالد عبد الرحمن (المالك)',
        branchId: 'branch_1',
        branchName: 'الفرع الرئيسي - المعادي',
        details: 'تسجيل دخول ناجح للمالك عبر لوحة التحكم الرئيسية',
        ipAddress: '192.168.1.10',
        timestamp: baseTime.subtract(const Duration(hours: 36)),
      ),
      SecurityAuditLogModel(
        id: 'AUD-1002',
        eventType: 'create_branch',
        performedByUserId: 'usr_owner_01',
        performedByUserName: 'د. خالد عبد الرحمن (المالك)',
        branchId: 'branch_2',
        branchName: 'فرع الجيزة - المهندسين',
        details: 'إضافة فرع جديد: فرع الجيزة - المهندسين',
        ipAddress: '192.168.1.10',
        timestamp: baseTime.subtract(const Duration(hours: 30)),
      ),
      SecurityAuditLogModel(
        id: 'AUD-1003',
        eventType: 'create_branch',
        performedByUserId: 'usr_owner_01',
        performedByUserName: 'د. خالد عبد الرحمن (المالك)',
        branchId: 'branch_3',
        branchName: 'فرع الإسكندرية - سموحة',
        details: 'إضافة فرع جديد: فرع الإسكندرية - سموحة',
        ipAddress: '192.168.1.10',
        timestamp: baseTime.subtract(const Duration(hours: 28)),
      ),
      SecurityAuditLogModel(
        id: 'AUD-1004',
        eventType: 'create_user',
        performedByUserId: 'usr_owner_01',
        performedByUserName: 'د. خالد عبد الرحمن (المالك)',
        targetUserId: 'usr_doctor_01',
        targetUserName: 'د. رامي سلامة',
        branchId: 'branch_1',
        branchName: 'الفرع الرئيسي - المعادي',
        details: 'إنشاء حساب طبيب جديد وربطه بملف الطبيب DOC-01',
        ipAddress: '192.168.1.10',
        timestamp: baseTime.subtract(const Duration(hours: 24)),
      ),
      SecurityAuditLogModel(
        id: 'AUD-1005',
        eventType: 'create_user',
        performedByUserId: 'usr_owner_01',
        performedByUserName: 'د. خالد عبد الرحمن (المالك)',
        targetUserId: 'usr_reception_01',
        targetUserName: 'منى السيد',
        branchId: 'branch_1',
        branchName: 'الفرع الرئيسي - المعادي',
        details: 'إنشاء حساب موظف استقبال وتعيين دور موظف استقبال',
        ipAddress: '192.168.1.10',
        timestamp: baseTime.subtract(const Duration(hours: 20)),
      ),
      SecurityAuditLogModel(
        id: 'AUD-1006',
        eventType: 'login_failure',
        performedByUserId: null,
        performedByUserName: 'مجهول',
        details: 'محاولة تسجيل دخول فاشلة بريد admin@example.com - كلمة المرور غير صحيحة',
        ipAddress: '41.233.14.88',
        timestamp: baseTime.subtract(const Duration(hours: 16)),
      ),
      SecurityAuditLogModel(
        id: 'AUD-1007',
        eventType: 'update_role_permissions',
        performedByUserId: 'usr_owner_01',
        performedByUserName: 'د. خالد عبد الرحمن (المالك)',
        details: 'تعديل مصفوفة صلاحيات دور مدير الفرع: إضافة manageMedicalServices',
        ipAddress: '192.168.1.10',
        timestamp: baseTime.subtract(const Duration(hours: 12)),
      ),
      SecurityAuditLogModel(
        id: 'AUD-1008',
        eventType: 'view_patient_profile',
        performedByUserId: 'usr_doctor_01',
        performedByUserName: 'د. رامي سلامة',
        targetUserId: 'PAT-001',
        targetUserName: 'محمد أحمد محمود',
        branchId: 'branch_1',
        branchName: 'الفرع الرئيسي - المعادي',
        details: 'استعراض الملف الطبي وتاريخ الفحوصات للمريض محمد أحمد محمود (PAT-001)',
        ipAddress: '192.168.1.25',
        timestamp: baseTime.subtract(const Duration(hours: 8)),
      ),
      SecurityAuditLogModel(
        id: 'AUD-1009',
        eventType: 'copy_branch_settings',
        performedByUserId: 'usr_owner_01',
        performedByUserName: 'د. خالد عبد الرحمن (المالك)',
        branchId: 'branch_3',
        branchName: 'فرع الإسكندرية - سموحة',
        details: 'نسخ ساعات العمل والعطل الرسمية من الفرع الرئيسي إلى فرع الإسكندرية',
        ipAddress: '192.168.1.10',
        timestamp: baseTime.subtract(const Duration(hours: 4)),
      ),
      SecurityAuditLogModel(
        id: 'AUD-1010',
        eventType: 'view_patient_profile',
        performedByUserId: 'usr_reception_01',
        performedByUserName: 'منى السيد',
        targetUserId: 'PAT-002',
        targetUserName: 'فاطمة حسن إبراهيم',
        branchId: 'branch_1',
        branchName: 'الفرع الرئيسي - المعادي',
        details: 'استعراض البيانات الأساسية للمريضة فاطمة حسن إبراهيم (PAT-002) لتأكيد الحجز',
        ipAddress: '192.168.1.30',
        timestamp: baseTime.subtract(const Duration(hours: 2)),
      ),
    ];

    _logs.addAll(seeds);
    _counter = seeds.length + 1;
  }

  @override
  void log({
    required String eventType,
    String? targetUserId,
    String? targetUserName,
    String? performedByUserId,
    String? performedByUserName,
    String? branchId,
    String? branchName,
    String? details,
    String? ipAddress,
  }) {
    final sanitizedDetails = _sanitize(details);
    final entry = SecurityAuditLogModel(
      id: 'AUD-${DateTime.now().microsecondsSinceEpoch}-${_counter++}',
      eventType: eventType,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      performedByUserId: performedByUserId,
      performedByUserName: performedByUserName,
      branchId: branchId,
      branchName: branchName,
      details: sanitizedDetails,
      ipAddress: ipAddress,
      timestamp: CairoTimeHelper.now(),
    );
    _logs.insert(0, entry); // Insert newest at the top
  }

  @override
  List<SecurityAuditLogModel> getLogs({
    String? targetUserId,
    String? performedByUserId,
    String? eventType,
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? limit,
    int? offset,
  }) {
    var result = List<SecurityAuditLogModel>.from(_logs);

    if (targetUserId != null && targetUserId.isNotEmpty) {
      result = result.where((e) => e.targetUserId == targetUserId).toList();
    }

    if (performedByUserId != null && performedByUserId.isNotEmpty) {
      result = result.where((e) => e.performedByUserId == performedByUserId).toList();
    }

    if (eventType != null && eventType.isNotEmpty && eventType != 'all') {
      result = result.where((e) => e.eventType == eventType).toList();
    }

    if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
      result = result.where((e) => e.branchId == branchId).toList();
    }

    if (startDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      result = result.where((e) {
        if (e.timestamp == null) return false;
        return e.timestamp!.isAfter(start) ||
            (e.timestamp!.year == start.year &&
                e.timestamp!.month == start.month &&
                e.timestamp!.day == start.day);
      }).toList();
    }

    if (endDate != null) {
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      result = result.where((e) {
        if (e.timestamp == null) return false;
        return e.timestamp!.isBefore(end);
      }).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      result = result.where((e) {
        final idMatch = (e.id ?? '').toLowerCase().contains(query);
        final eventMatch = (e.eventType ?? '').toLowerCase().contains(query);
        final detailsMatch = (e.details ?? '').toLowerCase().contains(query);
        final userMatch = (e.performedByUserName ?? '').toLowerCase().contains(query);
        final targetMatch = (e.targetUserName ?? '').toLowerCase().contains(query);
        final branchMatch = (e.branchName ?? '').toLowerCase().contains(query);
        final ipMatch = (e.ipAddress ?? '').toLowerCase().contains(query);
        return idMatch || eventMatch || detailsMatch || userMatch || targetMatch || branchMatch || ipMatch;
      }).toList();
    }

    // Sort newest first
    result.sort((a, b) {
      final tA = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tB = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tB.compareTo(tA);
    });

    if (offset != null && offset > 0) {
      if (offset >= result.length) return [];
      result = result.sublist(offset);
    }

    if (limit != null && limit > 0 && result.length > limit) {
      result = result.sublist(0, limit);
    }

    return List.unmodifiable(result);
  }

  String? _sanitize(String? input) {
    if (input == null) return null;
    return input.replaceAllMapped(_sensitiveKeywords, (match) {
      final key = match.group(1);
      return '$key=[REDACTED]';
    });
  }
}
