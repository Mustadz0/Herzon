import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/firebase_uuid.dart';
import '../../services/crashlytics_service.dart';
import '../providers/feature_flag_provider.dart';

class AdminFeatureFlagsScreen extends ConsumerStatefulWidget {
  const AdminFeatureFlagsScreen({super.key});

  @override
  ConsumerState<AdminFeatureFlagsScreen> createState() => _AdminFeatureFlagsScreenState();
}

class _AdminFeatureFlagsScreenState extends ConsumerState<AdminFeatureFlagsScreen> {
  bool _isAdmin = false;
  bool _checkingAdmin = true;
  String? _adminCheckError;

  @override
  void initState() {
    super.initState();
    _verifyAdmin();
  }

  Future<void> _verifyAdmin() async {
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        _adminCheckError = 'Veuillez vous connecter';
        return;
      }
      final userId = FirebaseUuid.toUuid(fbUser.uid);
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('is_admin')
          .eq('id', userId)
          .maybeSingle();
      _isAdmin = profile?['is_admin'] == true;
    } catch (e) {
      _adminCheckError = 'Erreur de vérification: $e';
      CrashlyticsService.recordError(e, StackTrace.current, reason: 'admin_feature_flags verify');
    }
    if (mounted) {
      setState(() => _checkingAdmin = false);
      if (_isAdmin) {
        ref.read(featureFlagProvider.notifier).loadFlags();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final flagState = ref.watch(featureFlagProvider);

    if (_checkingAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feature Flags (Admin)')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feature Flags (Admin)')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _adminCheckError != null ? Icons.error_outline : Icons.lock_outline,
                  size: 64,
                  color: _adminCheckError != null ? Colors.orange[300] : Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  _adminCheckError ?? 'Accès réservé aux administrateurs',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                if (_adminCheckError != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _checkingAdmin = true;
                        _adminCheckError = null;
                      });
                      _verifyAdmin();
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Feature Flags (Admin)')),
      body: flagState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Activez ou désactivez des fonctionnalités Ã  distance sans publier de mise Ã  jour.',
                          style: t.textTheme.bodySmall?.copyWith(color: AppTheme.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...flagState.flags.entries.map((entry) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: SwitchListTile(
                      title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Activé${entry.value ? '' : ' Â· Désactivé'}',
                        style: TextStyle(color: entry.value ? AppTheme.success : t.colorScheme.onSurfaceVariant)),
                      value: entry.value,
                      onChanged: flagState.isLoading ? null : (val) async {
                        await _toggleFlag(entry.key, val);
                        ref.read(featureFlagProvider.notifier).loadFlags();
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: entry.value ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          entry.value ? Icons.check_circle : Icons.cancel,
                          color: entry.value ? AppTheme.success : AppTheme.error,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Text('Expériences A/B', style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: t.isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.science_outlined, size: 48, color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('Gestion des expériences A/B',
                        style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Les utilisateurs sont assignés automatiquement via l\'API Supabase.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: t.colorScheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _toggleFlag(String key, bool value) async {
    try {
      await Supabase.instance.client
          .from('feature_config')
          .upsert({ 'flag_key': key, 'is_enabled': value, 'updated_at': DateTime.now().toIso8601String() });
    } catch (e) {
      CrashlyticsService.recordError(e, StackTrace.current, reason: 'AdminFeatureFlags toggle');
    }
  }
}
