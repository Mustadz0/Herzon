import 'package:flutter/foundation.dart';

/// Returns a sanitized error string for display in the UI.
///
/// Release mode hides the raw exception text (which can contain Supabase
/// RLS violations, SQL fragments, or tokens). All errors should still be
/// recorded via `CrashlyticsService.recordError` for diagnostics.
String safeErrorMessage(Object? error) {
  if (kReleaseMode) {
    return "Une erreur est survenue. Veuillez réessayer.";
  }
  return error?.toString() ?? "Une erreur inconnue est survenue.";
}
