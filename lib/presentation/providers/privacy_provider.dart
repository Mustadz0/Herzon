import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/firebase_uuid.dart';

class PrivacySettings {
  final bool showActivity;
  final bool allowMessages;
  final String showProfileTo; // "all", "proches", "nobody"
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
    bool? showActivity, bool? allowMessages, String? showProfileTo,
    bool? allowAddProches, bool? showZone, bool? showAge,
    bool? showDetails, bool? invisibleMode,
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

class PrivacyNotifier extends StateNotifier<PrivacySettings> {
  PrivacyNotifier() : super(const PrivacySettings());

  Future<void> load() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;
    final userId = FirebaseUuid.toUuid(fbUser.uid);
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('privacy_settings')
          .eq('id', userId)
          .maybeSingle();
      if (data != null && data['privacy_settings'] != null) {
        state = PrivacySettings.fromJson(data['privacy_settings'] as Map<String, dynamic>);
      }
    } catch (e) { debugPrint('PrivacyProvider.load: $e'); }
  }

  Future<void> update(PrivacySettings updated) async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;
    final userId = FirebaseUuid.toUuid(fbUser.uid);
    state = updated;
    await Supabase.instance.client
        .from('profiles')
        .update({'privacy_settings': updated.toJson()})
        .eq('id', userId);
  }
}

final privacyProvider = StateNotifierProvider<PrivacyNotifier, PrivacySettings>((ref) {
  return PrivacyNotifier();
});
