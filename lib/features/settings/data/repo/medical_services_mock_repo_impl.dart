import 'package:dartz/dartz.dart';
import '../../../../core/cubits/session_cubit.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/params.dart';
import '../../../bookings/domain/repo/bookings_repo.dart';
import '../../domain/repo/medical_services_repo.dart';
import '../models/medical_service_model.dart';

class MedicalServicesMockRepoImpl implements MedicalServicesRepo {
  final CurrentRoleProvider? roleProvider;
  final BookingsRepo? bookingsRepo;

  MedicalServicesMockRepoImpl({
    this.roleProvider,
    this.bookingsRepo,
  }) {
    _initMockData();
  }

  final List<MedicalServiceModel> _services = [];

  void _initMockData() {
    _services.addAll([
      const MedicalServiceModel(
        id: 'SRV-01',
        name: 'كشف جديد',
        consultationFee: 300,
        durationMinutes: 20,
        isActive: true,
        description: 'كشف طبي شامل لأول مرة وتقييم الحالة السريرية وإعداد الخطة العلاجية.',
      ),
      const MedicalServiceModel(
        id: 'SRV-02',
        name: 'استشارة ومتابعة',
        consultationFee: 150,
        durationMinutes: 15,
        isActive: true,
        description: 'متابعة الحالة السريرية ومراجعة نتائج التحاليل والفحوصات الدورية.',
      ),
      const MedicalServiceModel(
        id: 'SRV-03',
        name: 'كشف طارئ ومستعجل',
        consultationFee: 500,
        durationMinutes: 30,
        isActive: true,
        description: 'كشف فوري بأولوية قصوى للحالات العاجلة وغير المستقرة.',
      ),
      const MedicalServiceModel(
        id: 'SRV-04',
        name: 'سونار بطن وحوض',
        consultationFee: 400,
        durationMinutes: 20,
        isActive: true,
        description: 'فحص دقيق بالموجات فوق الصوتية لأعضاء البطن والحوض مع تقرير فوري.',
      ),
      const MedicalServiceModel(
        id: 'SRV-05',
        name: 'رسم قلب بالمجهود',
        consultationFee: 250,
        durationMinutes: 15,
        isActive: true,
        description: 'تخطيط كهربائية القلب لتقييم كفاءة العضلة والشرايين التاجية.',
      ),
      const MedicalServiceModel(
        id: 'SRV-06',
        name: 'غيار جراحي وخياطة',
        consultationFee: 200,
        durationMinutes: 15,
        isActive: true,
        description: 'تنظيف وتطهير الجروح السطحية والغيار الجراحي المعقم.',
      ),
      const MedicalServiceModel(
        id: 'SRV-07',
        name: 'كشف تخصصي قلب وأوعية دموية',
        consultationFee: 450,
        durationMinutes: 30,
        isActive: true,
        assignedDoctorId: 'DOC-01',
        assignedDoctorName: 'د. حسام الدين مصطفى',
        description: 'فحص سريري متقدم ومخصص لمرضى القلب والأوعية الدموية مع د. حسام الدين مصطفى.',
        category: 'باطنة وقلب',
      ),
      const MedicalServiceModel(
        id: 'SRV-08',
        name: 'جلسة علاج طبيعي مكثفة',
        consultationFee: 350,
        durationMinutes: 45,
        isActive: true,
        description: 'برنامج تأهيلي حركي شامل لإصابات العمود الفقري والمفاصل.',
        category: 'علاج طبيعي',
      ),
      const MedicalServiceModel(
        id: 'SRV-09',
        name: 'باقة ليزر إزالة شعر - جسم كامل (6 جلسات)',
        consultationFee: 4500,
        durationMinutes: 60,
        isActive: true,
        isMultiSession: true,
        sessionsCount: 6,
        category: 'جلدية وليزر',
        description: 'باقة متكاملة لإزالة الشعر بأحدث أجهزة التبريد، تشمل 6 جلسات مع رتوش مجانية.',
      ),
      const MedicalServiceModel(
        id: 'SRV-10',
        name: 'خطة تقويم أسنان ثابت (متابعة 12 شهر)',
        consultationFee: 12000,
        durationMinutes: 30,
        isActive: true,
        isMultiSession: true,
        sessionsCount: 12,
        category: 'طب الأسنان',
        description: 'خطة تقويم أسنان متكاملة بنظام الدفعات المرنة تشمل التركيب وجلسات الشد الدورية.',
      ),
      const MedicalServiceModel(
        id: 'SRV-11',
        name: 'علاج جذور وحشو عصب ضرس (3 جلسات)',
        consultationFee: 1800,
        durationMinutes: 40,
        isActive: true,
        isMultiSession: true,
        sessionsCount: 3,
        category: 'طب الأسنان',
        description: 'سحب العصب وتوسيع القنوات بأحدث أجهزة الروتاري مع حشو كمبوزيت ضوئي نهائي.',
      ),
      const MedicalServiceModel(
        id: 'SRV-12',
        name: 'جلسات تنظيف عميق وبلازما نضارة للبشرة (4 جلسات)',
        consultationFee: 2400,
        durationMinutes: 45,
        isActive: true,
        isMultiSession: true,
        sessionsCount: 4,
        category: 'جلدية وليزر',
        description: 'جلسات هيدرافيشيل مع حقن بلازما PRP معززة بالفيتامينات لنضارة الوجه.',
      ),
      const MedicalServiceModel(
        id: 'SRV-13',
        name: 'برنامج تأهيل عمود فقري وعلاج طبيعي (10 جلسات)',
        consultationFee: 2800,
        durationMinutes: 45,
        isActive: true,
        isMultiSession: true,
        sessionsCount: 10,
        category: 'علاج طبيعي',
        description: 'برنامج مكثف يشمل العلاج اليدوي والموجات فوق الصوتية والتمارين العلاجية.',
      ),
    ]);
  }

  String _normalize(String? text) {
    if (text == null) return '';
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _canManage() {
    if (roleProvider == null) return true;
    return roleProvider!.currentRole.canManageSettings;
  }

  @override
  Future<Either<Failures, List<MedicalServiceModel>>> getMedicalServices({
    bool? onlyActive,
    String? doctorId,
    String? query,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      var filtered = List<MedicalServiceModel>.from(_services);

      if (onlyActive == true) {
        filtered = filtered.where((s) => s.isServiceActive).toList();
      }

      if (doctorId != null && doctorId.isNotEmpty) {
        filtered = filtered.where((s) {
          // A service is available if it has no specific doctor assigned (clinic-wide)
          // or is explicitly assigned to this specific doctor.
          return s.assignedDoctorId == null ||
              s.assignedDoctorId!.isEmpty ||
              s.assignedDoctorId == doctorId;
        }).toList();
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = _normalize(query);
        filtered = filtered.where((s) {
          final nameMatch = _normalize(s.name).contains(q);
          final descMatch = _normalize(s.description).contains(q);
          final docMatch = _normalize(s.assignedDoctorName).contains(q);
          return nameMatch || descMatch || docMatch;
        }).toList();
      }

      return Right(filtered);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, MedicalServiceModel>> getMedicalServiceById(
    String id,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final index = _services.indexWhere((s) => s.id == id);
      if (index != -1) {
        return Right(_services[index]);
      }
      return const Left(ServerFailure(errMessage: 'service_not_found'));
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, MedicalServiceModel>> addMedicalService(
    MedicalServiceModel service,
  ) async {
    try {
      if (!_canManage()) {
        return const Left(ServerFailure(errMessage: 'permission_denied'));
      }

      final name = service.name?.trim() ?? '';
      if (name.isEmpty) {
        return const Left(ServerFailure(errMessage: 'service_name_required'));
      }

      final normalizedName = _normalize(name);
      final isDuplicate = _services.any(
        (s) => _normalize(s.name) == normalizedName,
      );
      if (isDuplicate) {
        return const Left(
          ServerFailure(errMessage: 'service_name_already_exists'),
        );
      }

      final fee = service.consultationFee ?? 0;
      if (fee < 0) {
        return const Left(ServerFailure(errMessage: 'invalid_service_fee'));
      }

      final duration = service.durationMinutes ?? 0;
      if (duration < 5 || duration > 240) {
        return const Left(
          ServerFailure(errMessage: 'invalid_service_duration'),
        );
      }

      final newId = 'SRV-${(_services.length + 1).toString().padLeft(2, '0')}';
      final newService = service.copyWith(
        id: newId,
        name: name,
        consultationFee: fee,
        durationMinutes: duration,
        isActive: service.isActive ?? true,
      );

      _services.insert(0, newService);
      return Right(newService);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, MedicalServiceModel>> updateMedicalService(
    MedicalServiceModel service,
  ) async {
    try {
      if (!_canManage()) {
        return const Left(ServerFailure(errMessage: 'permission_denied'));
      }

      final id = service.id;
      if (id == null) {
        return const Left(ServerFailure(errMessage: 'service_not_found'));
      }

      final index = _services.indexWhere((s) => s.id == id);
      if (index == -1) {
        return const Left(ServerFailure(errMessage: 'service_not_found'));
      }

      final name = service.name?.trim() ?? '';
      if (name.isEmpty) {
        return const Left(ServerFailure(errMessage: 'service_name_required'));
      }

      final normalizedName = _normalize(name);
      final isDuplicate = _services.any(
        (s) => s.id != id && _normalize(s.name) == normalizedName,
      );
      if (isDuplicate) {
        return const Left(
          ServerFailure(errMessage: 'service_name_already_exists'),
        );
      }

      final fee = service.consultationFee ?? _services[index].consultationFee ?? 0;
      if (fee < 0) {
        return const Left(ServerFailure(errMessage: 'invalid_service_fee'));
      }

      final duration = service.durationMinutes ?? _services[index].durationMinutes ?? 0;
      if (duration < 5 || duration > 240) {
        return const Left(
          ServerFailure(errMessage: 'invalid_service_duration'),
        );
      }

      final updated = _services[index].copyWith(
        name: name,
        consultationFee: fee,
        durationMinutes: duration,
        isActive: service.isActive ?? _services[index].isActive,
        assignedDoctorId: service.assignedDoctorId,
        clearAssignedDoctor: service.assignedDoctorId == null ||
            service.assignedDoctorId!.isEmpty,
        assignedDoctorName: service.assignedDoctorName,
        description: service.description ?? _services[index].description,
      );

      _services[index] = updated;
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, MedicalServiceModel>> toggleServiceStatus(
    String id,
  ) async {
    try {
      if (!_canManage()) {
        return const Left(ServerFailure(errMessage: 'permission_denied'));
      }

      final index = _services.indexWhere((s) => s.id == id);
      if (index == -1) {
        return const Left(ServerFailure(errMessage: 'service_not_found'));
      }

      final current = _services[index];
      final newStatus = !(current.isActive ?? true);
      final updated = current.copyWith(isActive: newStatus);
      _services[index] = updated;

      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, Unit>> deleteMedicalService(String id) async {
    try {
      if (!_canManage()) {
        return const Left(ServerFailure(errMessage: 'permission_denied'));
      }

      final index = _services.indexWhere((s) => s.id == id);
      if (index == -1) {
        return const Left(ServerFailure(errMessage: 'service_not_found'));
      }

      // Check if linked to any existing bookings
      if (bookingsRepo != null) {
        final bookingsResult = await bookingsRepo!.getBookings(
          const PaginationParams(page: 1, limit: 1000),
        );
        final isLinked = bookingsResult.fold(
          (failure) => false,
          (response) => (response.bookings ?? []).any((b) => b.serviceId == id),
        );
        if (isLinked) {
          return const Left(
            ServerFailure(
              errMessage: 'cannot_delete_service_linked_to_bookings',
            ),
          );
        }
      }

      _services.removeAt(index);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }
}
