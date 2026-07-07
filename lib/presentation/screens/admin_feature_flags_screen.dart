import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../providers/feature_flag_provider.dart';

class AdminFeatureFlagsScreen extends ConsumerStatefulWidget {
  const AdminFeatureFlagsScreen({super.key});

  @override
  ConsumerState<AdminFeatureFlagsScreen> createState() => _AdminFeatureFlagsScreenState();
}

class _AdminFeatureFlagsScreenState extends ConsumerState<AdminFeatureFlagsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(featureFlagProvider.notifier).loadFlags();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final flagState = ref.watch(featureFlagProvider);

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
                          'Activez ou dÃ©sactivez des fonctionnalitÃ©s Ã  distance sans publier de mise Ã  jour.',
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
                      subtitle: Text('ActivÃ©' + (entry.value ? '' : ' Â· DÃ©sactivÃ©'),
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
                Text('ExpÃ©riences A/B', style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
                      Text('Gestion des expÃ©riences A/B',
                        style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Les utilisateurs sont assignÃ©s automatiquement via l\'API Supabase.',
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
    } catch (_) {}
  }
}
