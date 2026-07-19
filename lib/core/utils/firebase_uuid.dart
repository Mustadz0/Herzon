import 'package:uuid/uuid.dart';

class FirebaseUuid {
  static const _uuid = Uuid();
  static String toUuid(String firebaseUid) => _uuid.v5(Uuid.NAMESPACE_URL, 'firebase:$firebaseUid');
}
