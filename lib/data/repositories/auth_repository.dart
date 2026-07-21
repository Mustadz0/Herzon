import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../core/utils/firebase_uuid.dart';

abstract class IAuthRepository {
  fb.User? get currentUser;
  Stream<fb.User?> get authStateChanges;
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<UserModel?> getUserProfile(String userId);
  Future<void> updateProfile(UserModel user);
}

class SupabaseAuthRepository implements IAuthRepository {
  final SupabaseClient? _supabase;
  final GoogleSignIn _googleSignIn;
  final fb.FirebaseAuth _firebaseAuth;

  SupabaseAuthRepository({required SupabaseClient? supabase})
      : _supabase = supabase,
        _firebaseAuth = fb.FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

  static String firebaseUidToUuid(String firebaseUid) {
    return FirebaseUuid.toUuid(firebaseUid);
  }

  @override
  fb.User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<fb.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      if (!kReleaseMode) debugPrint('[Auth] Google sign-in cancelled by user');
      return;
    }
    if (!kReleaseMode) debugPrint('[Auth] Google user: ${googleUser.email}');

    final googleAuth = await googleUser.authentication;
    if (!kReleaseMode) debugPrint('[Auth] Got tokens: idToken=${googleAuth.idToken != null}, accessToken=${googleAuth.accessToken != null}');

    final credential = fb.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final result = await _firebaseAuth.signInWithCredential(credential);
    if (!kReleaseMode) debugPrint('[Auth] Firebase sign-in: ${result.user?.uid}');
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    final s = _supabase;
    if (s == null) return null;
    final uuid = firebaseUidToUuid(userId);
    final responses = await s
        .from('profiles')
        .select()
        .eq('id', uuid);

    if (responses.isEmpty) return null;
    return UserModel.fromJson(responses[0]);
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    final s = _supabase;
    if (s == null) return;
    final json = user.toJson();
    json['id'] = firebaseUidToUuid(user.id);
    await s.from('profiles').upsert(json);
  }
}
