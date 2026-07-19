import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/utils/firebase_uuid.dart';

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
  StreamSubscription<User?>? _sub;

  AuthNotifier(this._repo) : super(const AppAuthState(isLoading: true)) {
    _init();
  }

  void _init() {
    // Listen to Firebase auth state changes
    _sub = _repo.onAuthStateChange.listen((User? firebaseUser) {
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
      // _init listener will call _loadProfile automatically
    } catch (e) {
      state = AppAuthState(error: e.toString());
    }
  }

  Future<void> _loadProfile(String firebaseUid) async {
    try {
      final uuid = FirebaseUuid.toUuid(firebaseUid);
      var profile = await _repo.getUserProfile(firebaseUid);

      if (profile == null) {
        final firebaseUser = _repo.currentUser;
        profile = UserModel(
          id: uuid,
          username: 'user_${firebaseUid.substring(0, 8)}',
          displayName: firebaseUser?.displayName ?? 'User',
          avatarUrl: firebaseUser?.photoURL,
          privacySettings: const {
            'show_activity': true,
            'allow_messages': true,
            'show_profile_to': 'everyone',
            'allow_add_proches': true,
            'show_zone': true,
            'show_age': true,
            'show_details': true,
            'invisible_mode': false,
          },
        );
        await _repo.updateProfile(profile);
        // Re-fetch after upsert so DB defaults (is_admin etc.) are loaded
        profile = await _repo.getUserProfile(firebaseUid) ?? profile;
      }

      state = AppAuthState(user: profile);
    } catch (e) {
      state = AppAuthState(error: e.toString());
    }
  }

  /// Call this after updating profile to refresh state.
  Future<void> refreshProfile() async {
    final uid = _repo.currentUser?.uid;
    if (uid == null) return;
    await _loadProfile(uid);
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
  return FirebaseAuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
