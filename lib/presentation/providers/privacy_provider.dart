// Fix: PrivacyNotifier استدعى Supabase مباشرة — الآن عبر repository.
// Fix: load() يُستدعى تلقائياً عند إنشاء الـ provider.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/firebase_uuid.dart';

// ── Repository ────────────────────────────────────────────────────────────
abstract class IPrivacyRepository {
  Future<Map<String, dynamic>?> fetchPrivacySettings(String userId);
  Future<void> savePrivacySettings(
      String userId, Map<String, dynamic> settings);
}

class SupabasePrivacyRepository implements IPrivacyRepository {
  final SupabaseClient _supabase;
  SupabasePrivacyRepository(this._supabase);

  @override
  Future<Map<String, dynamic>?> fetchPrivacySettings(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select('privacy_settings')
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return data['privacy_settings'] as Map<String, dynamic>?;
  }

  @override
  Future<void> savePrivacySettings(
      String userId, Map<String, dynamic> settings) async {
    await _supabase
        .from('profiles')
        .update({'privacy_settings': settings})
        .eq('id', userId);
  }
}

final privacyRepositoryProvider = Provider<IPrivacyRepository>((ref) {
  return SupabasePrivacyRepository(Supabase.instance.client);
});

// ── Model ─────────────────────────────────────────────────────────────────
class PrivacySettings {
  final bool showActivity;
  final bool allowMessages;
  final String showProfileTo;
  final bool allowAddProches;
  final bool showZone;
  final bool showAge;
  final bool showDetails;
  final bool invisibleMode;

  const PrivacySettings({
    this.showActivity = true,
    this.allowMessages = true,
    this.showProfileTo = 'all',
    this.allowAddProches = true,
    this.showZone = true,
    this.showAge = true,
    this.showDetails = true,
    this.invisibleMode = false,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      showActivity: json['show_activity'] as bool? ?? true,
      allowMessages: json['allow_messages'] as bool? ?? true,
      showProfileTo: json['show_profile_to'] as String? ?? 'all',
      allowAddProches: json['allow_add_proches'] as bool? ?? true,
      showZone: json['show_zone'] as bool? ?? true,
      showAge: json['show_age'] as bool? ?? true,
      showDetails: json['show_details'] as bool? ?? true,
      invisibleMode: json['invisible_mode'] as bool? ?? false,
    );
  }

  PrivacySettings copyWith({
    bool? showActivity,
    bool? allowMessages,
    String? showProfileTo,
    bool? allowAddProches,
    bool? showZone,
    bool? showAge,
    bool? showDetails,
    bool? invisibleMode,
  }) {
    return PrivacySettings(
      showActivity: showActivity ?? this.showActivity,
      allowMessages: allowMessages ?? this.allowMessages,
      showProfileTo: showProfileTo ?? this.showProfileTo,
      allowAddProches: allowAddProches ?? this.allowAddProches,
      showZone: showZone ?? this.showZone,
      showAge: showAge ?? this.showAge,
      showDetails: showDetails ?? this.showDetails,
      invisibleMode: invisibleMode ?? this.invisibleMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'show_activity': showActivity,
        'allow_messages': allowMessages,
        'show_profile_to': showProfileTo,
        'allow_add_proches': allowAddProches,
        'show_zone': showZone,
        'show_age': showAge,
        'show_details': showDetails,
        'invisible_mode': invisibleMode,
      };
}

// ── Notifier ──────────────────────────────────────────────────────────────
class PrivacyNotifier extends StateNotifier<PrivacySettings> {
  final IPrivacyRepository _repo;

  PrivacyNotifier(this._repo) : super(const PrivacySettings()) {
    load(); // Fix: auto-load on creation
  }

  Future<void> load() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    final userId = FirebaseUuid.toUuid(firebaseUser.uid);
    try {
      final json = await _repo.fetchPrivacySettings(userId);
      if (json != null && mounted) {
        state = PrivacySettings.fromJson(json);
      }
    } catch (_) {}
  }

  Future<void> update(PrivacySettings updated) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    final userId = FirebaseUuid.toUuid(firebaseUser.uid);
    if (mounted) state = updated;
    await _repo.savePrivacySettings(userId, updated.toJson());
  }
}

final privacyProvider =
    StateNotifierProvider<PrivacyNotifier, PrivacySettings>((ref) {
  return PrivacyNotifier(ref.watch(privacyRepositoryProvider));
});
