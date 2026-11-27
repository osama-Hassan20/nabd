/// Runtime configuration for the in-process local server simulation.
///
/// Controlled from the QA settings card in [ProfilePage].
class LocalServerConfig {
  LocalServerConfig._();

  static Duration latency = Duration.zero;
  static int? injectedFailureStatusCode;
  static bool resetFailureAfterNextCall = true;

  static void reset() {
    latency = Duration.zero;
    injectedFailureStatusCode = null;
    resetFailureAfterNextCall = true;
  }
}
