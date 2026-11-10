import '../../../visits/data/models/enums/visit_status_enum.dart';

abstract class ActiveVisitLookup {
  Future<VisitStatusEnum?> getVisitStatusByBookingId(String bookingId);
}
