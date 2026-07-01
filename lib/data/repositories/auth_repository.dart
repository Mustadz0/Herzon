import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Authentication Repository Interface
abstract class IAuthRepository {
  /// Current authenticated user
  User? get currentUser;

  /// Stream of auth state changes
  Stream<AuthState> get onAuthStateChange;

  /// Sign in with Google OAuth
  Future<void> signInWithGoogle();

  /// Sign in anonymously
  Future<AuthResponse> signInAnonymously();

  /// Sign out
  Future<void> signOut();

  /// Get the user's profile
  Future<UserModel?> getUserProfile(String userId);

  /// Update the user's profile
  Future<void> updateProfile(UserModel user);
}

/// Supabase implementation of AuthRepository
class SupabaseAuthRepository implements IAuthRepository {
  final SupabaseClient _supabase;

  SupabaseAuthRepository({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  @override
  Future<void> signInWithGoogle() async {
    // For mobile, we use native sign in
    // Web version would use OAuth redirect
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.example.proximite://login-callback',
    );
  }

  @override
  Future<AuthResponse> signInAnonymously() async {
    return await _supabase.auth.signInAnonymously(
      data: {'is_anonymous': true},
    );
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    final responses = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId);

    if (responses.isEmpty) return null;
    return UserModel.fromJson(responses[0]);
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    await _supabase.from('profiles').upsert(user.toJson());

  }
}
