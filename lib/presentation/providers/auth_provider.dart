import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AppAuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AppAuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AppAuthState> {
  final IAuthRepository _repo;
  StreamSubscription<fb.User?>? _sub;

  AuthNotifier(this._repo) : super(const AppAuthState(isLoading: true)) {
    _init();
  }

  void _init() {
    _sub = _repo.authStateChanges.listen((fb.User? firebaseUser) {
      if (firebaseUser != null) {
        _loadProfile(firebaseUser.uid);
      } else {
        state = const AppAuthState();
      }
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AppAuthState(isLoading: true);
    try {
      await _repo.signInWithGoogle();
    } catch (e) {
      state = AppAuthState(error: e.toString());
    }
    if (state.isLoading) {
      state = const AppAuthState();
    }
  }

  Future<void> signInAnonymously() async {
    state = const AppAuthState(isLoading: true);
    try {
      await _repo.signInAnonymously();
    } catch (e) {
      state = AppAuthState(error: e.toString());
    }
  }

  Future<void> _loadProfile(String id) async {
    try {
      var profile = await _repo.getUserProfile(id);
      if (profile == null) {
        final fbUser = _repo.currentUser;
        final meta = fbUser?.displayName != null
            ? {'full_name': fbUser!.displayName, 'avatar_url': fbUser.photoURL}
            : <String, dynamic>{};
        profile = UserModel(
          id: id,
          username: 'user_${id.substring(0, 8)}',
          displayName: meta['full_name'] as String? ?? 'User',
          avatarUrl: meta['avatar_url'] as String?,
          privacySettings: const {'show_activity': true, 'allow_messages': true},
        );
        await _repo.updateProfile(profile);
        profile = await _repo.getUserProfile(id) ?? profile;
      }
      state = AppAuthState(user: profile);
    } catch (e) {
      debugPrint('[Auth] _loadProfile error: $e');
      state = AppAuthState(error: e.toString());
    }
  }

  Future<void> refreshProfile() async {
    final id = _repo.currentUser?.uid;
    if (id != null) await _loadProfile(id);
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AppAuthState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final supabase = Supabase.instance.client;
  return SupabaseAuthRepository(supabase: supabase);
});

final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final currentUserIdProvider = Provider<String?>((ref) =>
    fb.FirebaseAuth.instance.currentUser?.uid);
