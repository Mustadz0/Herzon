import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Crash & error monitoring service.
/// Uses Firebase Crashlytics when Firebase is configured, falls back to Supabase.
class CrashlyticsService {
  static FirebaseCrashlytics? _crashlytics;
  static bool _initialized = false;

  /// Initialize crash reporting. Call once at app start.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Try Firebase Crashlytics
    try {
      _crashlytics = FirebaseCrashlytics.instance;
      await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);
      developer.log('Firebase Crashlytics enabled');
    } catch (e) {
      _crashlytics = null;
      developer.log('Firebase Crashlytics unavailable, using Supabase fallback');
    }

    // Set up Flutter error handlers
    _setupErrorHandlers();
  }

  /// Log a non-fatal error
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    developer.log('ERROR: $exception', error: exception, stackTrace: stackTrace);

    if (_crashlytics != null) {
      try {
        await _crashlytics!.recordError(exception, stackTrace, reason: reason);
      } catch (_) {}
    }

    // Always log to Supabase as backup/searchable history
    await _logToSupabase(
      level: 'error',
      message: reason ?? exception.toString(),
      stackTrace: stackTrace?.toString(),
    );
  }

  /// Log a fatal crash
  static Future<void> recordFatal(
    dynamic exception,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    developer.log('FATAL: $exception', error: exception, stackTrace: stackTrace);

    if (_crashlytics != null) {
      try {
        await _crashlytics!.recordError(exception, stackTrace, reason: reason, fatal: true);
      } catch (_) {}
    }

    await _logToSupabase(
      level: 'fatal',
      message: reason ?? exception.toString(),
      stackTrace: stackTrace.toString(),
    );
  }

  /// Log a message/info event
  static Future<void> log(String message, {String level = 'info'}) async {
    developer.log(message);

    if (_crashlytics != null) {
      try {
        await _crashlytics!.log(message);
      } catch (_) {}
    }

    // Only persist warnings and above to Supabase
    if (level == 'warning' || level == 'error') {
      await _logToSupabase(level: level, message: message);
    }
  }

  /// Set user identifier for crash reports
  static Future<void> setUser(String userId) async {
    if (_crashlytics != null) {
      try {
        await _crashlytics!.setUserIdentifier(userId);
      } catch (_) {}
    }
  }

  /// Log custom key-value for debugging
  static Future<void> setCustomKey(String key, String value) async {
    if (_crashlytics != null) {
      try {
        await _crashlytics!.setCustomKey(key, value);
      } catch (_) {}
    }
  }

  /// Send crash report to Supabase crash_reports table
  static Future<void> _logToSupabase({
    required String level,
    required String message,
    String? stackTrace,
  }) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      await client.from('crash_reports').insert({
        'user_id': userId,
        'level': level,
        'message': message,
        'stack_trace': stackTrace,
        'platform': defaultTargetPlatform.name,
        'app_version': '1.0.0',
        'device_info': {
          'debug': kDebugMode,
          'profile': kProfileMode,
          'release': kReleaseMode,
        },
      });
    } catch (e) {
      // Never crash the crash reporter
      developer.log('Failed to log crash to Supabase: $e');
    }
  }

  /// Set up global Flutter error handlers
  static void _setupErrorHandlers() {
    // Flutter framework errors
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      recordError(
        details.exception,
        details.stack,
        reason: 'FlutterError: ${details.context}',
      );
    };

    // Uncaught async errors ( Zone errors)
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      recordError(error, stackTrace, reason: 'Uncaught async error');
      return true;
    };
  }
}
