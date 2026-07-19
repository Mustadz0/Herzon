import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../core/utils/firebase_uuid.dart';

/// Authentication Repository Interface
abstract class IAuthRepository {
  /// Current authenticated Firebase user
  User? get currentUser;

  /// Stream of Firebase auth state changes
  Stream<User?> get onAuthStateChange;

  /// Sign in with Google via Firebase
  Future<void> signInWithGoogle();

  /// Sign out from Firebase
  Future<void> signOut();

  /// Get the user's profile from Supabase (converts UID to UUID v5)
  Future<UserModel?> getUserProfile(String firebaseUid);

  /// Update the user's profile in Supabase (converts UID to UUID v5)
  Future<void> updateProfile(UserModel user);
}

/// Firebase + Supabase implementation of AuthRepository.
/// Firebase handles authentication; Supabase stores profile data.
/// Firebase UIDs are converted to UUID v5 before any Supabase query.
class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    SupabaseClient? supabase,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _supabase = supabase ?? Supabase.instance.client,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<User?> get onAuthStateChange => _firebaseAuth.authStateChanges();

  @override
  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<UserModel?> getUserProfile(String firebaseUid) async {
    final uuid = FirebaseUuid.toUuid(firebaseUid);
    final responses = await _supabase
        .from('profiles')
        .select()
        .eq('id', uuid);

    if (responses.isEmpty) return null;
    return UserModel.fromJson(responses[0]);
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    await _supabase.from('profiles').upsert(user.toJson());
  }
}
