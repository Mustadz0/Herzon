import 'package:uuid/uuid.dart';

/// Converts Firebase UIDs (non-UUID strings) to deterministic UUID v5 values.
/// Uses the URL namespace with the prefix 'firebase:{uid}' — must match
/// the PostgreSQL function firebase_uid_to_uuid() in Supabase.
class FirebaseUuid {
  static const _uuid = Uuid();

  /// Convert a Firebase UID string to a UUID v5 string.
  static String toUuid(String firebaseUid) =>
      _uuid.v5(Namespace.url.value, 'firebase:$firebaseUid');
}
