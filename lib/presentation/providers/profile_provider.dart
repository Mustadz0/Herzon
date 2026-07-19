import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_provider.dart' show authRepositoryProvider;

class ProfileState {
  final UserModel? profile;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  ProfileState copyWith({
    UserModel? profile,
    bool? isLoading,
    String? error,
    bool? isSaving,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final IAuthRepository _repo;

  ProfileNotifier(this._repo) : super(const ProfileState());

  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repo.getUserProfile(userId);
      state = ProfileState(profile: profile);
    } catch (e) {
      state = ProfileState(error: e.toString());
    }
  }

  Future<void> updateProfile(UserModel updated) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.updateProfile(updated);
      state = ProfileState(profile: updated);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const ProfileState();
  }
}

final profileProvider =
    StateNotifierProvider.family<ProfileNotifier, ProfileState, String>(
  (ref, userId) => ProfileNotifier(ref.watch(authRepositoryProvider)),
);
