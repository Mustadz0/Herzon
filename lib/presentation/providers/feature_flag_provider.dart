import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/feature_flag_repository.dart';

class FeatureFlagState {
  final Map<String, dynamic> flags;
  final Map<String, String> experiments;
  final bool isLoading;
  final String? error;

  const FeatureFlagState({
    this.flags = const {},
    this.experiments = const {},
    this.isLoading = false,
    this.error,
  });

  FeatureFlagState copyWith({
    Map<String, dynamic>? flags,
    Map<String, String>? experiments,
    bool? isLoading,
    String? error,
  }) {
    return FeatureFlagState(
      flags: flags ?? this.flags,
      experiments: experiments ?? this.experiments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class FeatureFlagNotifier extends StateNotifier<FeatureFlagState> {
  final IFeatureFlagRepository _repo;

  FeatureFlagNotifier(this._repo) : super(const FeatureFlagState()) {
    _init();
  }

  Future<void> _init() async {
    await loadFlags();
    await loadExperiments();
  }

  Future<void> loadFlags() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getFeatureFlags();
      state = state.copyWith(flags: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadExperiments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getUserExperiments();
      final experiments = <String, String>{
        for (final row in data) row['experiment_id'] as String: row['variant'] as String? ?? 'control',
      };
      state = state.copyWith(experiments: experiments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  T getFlagValue<T>(String key, T defaultValue) {
    final value = state.flags[key];
    if (value == null) return defaultValue;
    if (value is T) return value;
    return defaultValue;
  }
}

final featureFlagProvider = StateNotifierProvider<FeatureFlagNotifier, FeatureFlagState>((ref) {
  return FeatureFlagNotifier(ref.watch(featureFlagRepositoryProvider));
});
