import 'package:firebase_app_check/firebase_app_check.dart';

/// Helper to get Firebase App Check token for Edge Function requests.
class AppCheckHelper {
  /// Get the current App Check token.
  /// Returns null if App Check is not available.
  static Future<String?> getToken() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      return token;
    } catch (e) {
      return null;
    }
  }

  /// Get headers to attach to Edge Function requests.
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    if (token != null) {
      return {'X-Firebase-AppCheck': token};
    }
    return {};
  }
}
