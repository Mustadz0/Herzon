import 'package:supabase_flutter/supabase_flutter.dart';

/// Verifies the current Firebase Auth user is an admin via the
/// `current_user_is_admin()` RPC which reads `auth.uid()` from the JWT
/// and returns true if the profile has `is_admin = true`.
///
/// Returns `true` if admin, `false` otherwise. Returns `false` (deny) on any
/// error — secure default.
Future<bool> verifyAdmin() async {
  try {
    return await Supabase.instance.client.rpc('current_user_is_admin') == true;
  } catch (_) {
    return false;
  }
}
