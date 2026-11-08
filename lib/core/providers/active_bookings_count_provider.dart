abstract class ActiveBookingsCountProvider {
  Future<int> countActiveFutureBookingsForDoctor(String doctorId);
  Future<int> countActiveFutureBookingsForBranch(String branchId);
}
