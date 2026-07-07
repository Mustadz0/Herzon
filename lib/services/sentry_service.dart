// Sentry stub - dropped sentry_flutter package due to Kotlin version requirements.
// To enable: add `sentry_flutter: ^8.0.0` (requires newer Kotlin Gradle plugin) to pubspec.yaml.

class SentryService {
  static bool get _enabled => false;

  static Future<void> init(String dsn) async {
    // Disabled: requires sentry_flutter package
    if (_enabled) {
      // SentryFlutter.init(...);
    }
  }

  static void captureException(dynamic exception, {dynamic stackTrace}) {
    if (_enabled) {
      // ignore: avoid_print
      print('Sentry disabled. Caught: $exception');
    }
  }

  static void captureMessage(String message, {String? level}) {
    if (_enabled) {
      // ignore: avoid_print
      print('Sentry disabled. Message: $message');
    }
  }
}
