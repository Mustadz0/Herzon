import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AppAuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AppAuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;
  bool get isAnonymous => user?.privacySettings['is_anonymous'] == true;
}

class AuthNotifier extends StateNotifier<AppAuthState> {
  final IAuthRepository _repo;
  StreamSubscription<sb.AuthState>? _sub;

  AuthNotifier(this._repo) : super(const AppAuthState(isLoading: true)) {
    _init();
  }

  void _init() {
    _sub = _repo.onAuthStateChange.listen((sb.AuthState event) {
      final u = event.session?.user;
      if (u != null) {
        _loadProfile(u.id);
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
  }

  Future<void> signInAnonymously() async {
    state = const AppAuthState(isLoading: true);
    try {
      final res = await _repo.signInAnonymously();
      if (res.user != null) await _loadProfile(res.user!.id);
    } catch (e) {
      state = AppAuthState(error: e.toString());
    }
  }

  void signInAsGuest() {
    final guest = UserModel(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      username: 'Invite',
      displayName: 'Utilisateur invite',
      isAnonymous: true,
    );
    state = AppAuthState(user: guest);
  }

  Future<void> _loadProfile(String id) async {
    try {
      var profile = await _repo.getUserProfile(id);
      if (profile == null) {
        final meta = _repo.currentUser?.userMetadata ?? {};
        profile = UserModel(
          id: id,
          username: 'user_${id.substring(0, 8)}',
          displayName: meta['full_name'] as String? ?? 'User',
          avatarUrl: meta['avatar_url'] as String?,
          privacySettings: const {'show_activity': true, 'allow_messages': true},
        );
        await _repo.updateProfile(profile);
      }
      state = AppAuthState(user: profile);
    } catch (e) {
      state = AppAuthState(error: e.toString());
    }
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
  final supabase = sb.Supabase.instance.client;
  return SupabaseAuthRepository(supabase: supabase);
});

final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
