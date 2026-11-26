import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/offline/repositories/offline_first_specialty_records_repo.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import 'package:eyadty/features/specialty_records/data/models/specialty_record_entry_model.dart';

/// Shared component for multi-session treatments & packages across
/// Dentistry, Dermatology, Cosmetic, Orthodontics, and Physiotherapy.
class SessionsAndPackagesWidget extends StatefulWidget {
  final String patientId;
  final String? patientName;
  final String? visitId;
  final String? doctorId;
  final String? doctorName;
  final MedicalSpecialty specialty;
  final String title;
  final List<String> procedureOptions;

  const SessionsAndPackagesWidget({
    super.key,
    required this.patientId,
    this.patientName,
    this.visitId,
    this.doctorId,
    this.doctorName,
    required this.specialty,
    required this.title,
    required this.procedureOptions,
  });

  @override
  State<SessionsAndPackagesWidget> createState() =>
      _SessionsAndPackagesWidgetState();
}

class _SessionsAndPackagesWidgetState extends State<SessionsAndPackagesWidget> {
  List<SpecialtyRecordEntryModel> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final res = await getIt<OfflineFirstSpecialtyRecordsRepo>().getEntriesForPatient(
      patientId: widget.patientId,
      specialty: widget.specialty,
    );
    res.fold((_) {}, (list) {
      if (mounted) {
        setState(() {
          _entries = list.where((e) => e.kind == 'session_package').toList();
          _loading = false;
        });
      }
    });
  }

  Future<void> _addSession({
    required String procedure,
    required int totalSessions,
    required int doneSessions,
    required num price,
    String? notes,
  }) async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    final entry = SpecialtyRecordEntryModel(
      id: '',
      patientId: widget.patientId,
      visitId: widget.visitId,
      specialty: widget.specialty,
      kind: 'session_package',
      data: {
        'procedure': procedure,
        'totalSessions': totalSessions,
        'doneSessions': doneSessions,
        'remainingSessions': (totalSessions - doneSessions).clamp(0, 999),
        'price': price,
        'nextSessionDate':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      createdAt: DateTime.now(),
    );
    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(entry);
    await _load();
  }

  Future<void> _bookNextSession(SpecialtyRecordEntryModel entry) async {
    if (!getIt.isRegistered<BookingsRepo>()) return;
    final nextDate = DateTime.now().add(const Duration(days: 7));
    final procedure = entry.data['procedure']?.toString() ?? widget.title;
    final price = (entry.data['price'] as num?) ?? 300;
    final booking = BookingModel(
      patientId: widget.patientId,
      patientName: widget.patientName,
      doctorId: widget.doctorId,
      doctorName: widget.doctorName,
      specialty: widget.specialty.value,
      specialtyCode: widget.specialty,
      serviceName: procedure,
      date: nextDate,
      appointmentTime: nextDate,
      consultationFee: price,
      totalPrice: price,
      status: BookingStatusEnum.scheduled,
    );
    await getIt<BookingsRepo>().createBooking(booking);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حجز الجلسة القادمة: $procedure')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.specialty.icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.title, style: CustomAppFontStyle.bold14),
              ),
              TextButton.icon(
                onPressed: () {
                  _addSession(
                    procedure: widget.procedureOptions.first,
                    totalSessions: 4,
                    doneSessions: 1,
                    price: 500,
                  );
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('إضافة جلسة / باقة'),
              ),
            ],
          ),
          if (_entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'لا توجد باقات أو جلسات مسجلة حتى الآن.',
                style: CustomAppFontStyle.regular12.copyWith(color: AppColors.gray),
              ),
            )
          else
            ..._entries.map((entry) {
              final d = entry.data;
              final proc = d['procedure']?.toString() ?? '';
              final done = d['doneSessions'] ?? 1;
              final total = d['totalSessions'] ?? 1;
              final rem = d['remainingSessions'] ?? 0;
              final price = d['price'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.grayE2E8F0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(proc, style: CustomAppFontStyle.semiBold13),
                          Text(
                            'جلسة $done من $total • المتبقي: $rem • السعر: $price ج.م',
                            style: CustomAppFontStyle.regular12
                                .copyWith(color: AppColors.gray),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _bookNextSession(entry),
                      child: const Text('حجز الجلسة القادمة'),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
