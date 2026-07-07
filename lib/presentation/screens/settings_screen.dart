import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../providers/block_provider.dart';
import '../providers/privacy_provider.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(privacyProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final blockState = ref.watch(blockProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ParamÃ¨tres')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.block_rounded, color: AppTheme.error, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Utilisateurs bloquÃ©s',
                            style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          Text('${blockState.blockedUsers.length} utilisateur(s)',
                            style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (blockState.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (blockState.blockedUsers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.shield_outlined, size: 40, color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text('Aucun utilisateur bloquÃ©',
                          style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  )
                else
                  ...blockState.blockedUsers.map((userId) => _BlockedUserTile(userId: userId)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // â”€â”€â”€ ConfidentialitÃ© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Consumer(builder: (context, ref, _) {
            final privacy = ref.watch(privacyProvider);
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: t.isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield_rounded, color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text('ConfidentialitÃ©', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _PrivacyDropdown(
                    label: 'Qui peut voir mon profil',
                    value: privacy.showProfileTo,
                    items: const ['all', 'proches', 'nobody'],
                    itemLabels: const ['Tous', 'Proches uniquement', 'Personne'],
                    onChanged: (v) => ref.read(privacyProvider.notifier).update(PrivacySettings(
                      showProfileTo: v,
                      allowMessages: privacy.allowMessages,
                      showActivity: privacy.showActivity,
                      allowAddProches: privacy.allowAddProches,
                      showZone: privacy.showZone,
                      showAge: privacy.showAge,
                      showDetails: privacy.showDetails,
                      invisibleMode: privacy.invisibleMode,
                    )),
                  ),
                  const Divider(height: 1),
                  _PrivacyDropdown(
                    label: 'Qui peut m\'envoyer un message',
                    value: privacy.allowMessages ? 'all' : 'nobody',
                    items: const ['all', 'proches', 'nobody'],
                    itemLabels: const ['Tous', 'Proches uniquement', 'Personne'],
                    onChanged: (v) => ref.read(privacyProvider.notifier).update(PrivacySettings(
                      showProfileTo: privacy.showProfileTo,
                      allowMessages: v != 'nobody',
                      showActivity: privacy.showActivity,
                      allowAddProches: privacy.allowAddProches,
                      showZone: privacy.showZone,
                      showAge: privacy.showAge,
                      showDetails: privacy.showDetails,
                      invisibleMode: privacy.invisibleMode,
                    )),
                  ),
                  const Divider(height: 1),
                  _PrivacyDropdown(
                    label: 'Qui peut m\'ajouter aux Proches',
                    value: privacy.allowAddProches ? 'all' : 'nobody',
                    items: const ['all', 'nobody'],
                    itemLabels: const ['Tous', 'Personne'],
                    onChanged: (v) => ref.read(privacyProvider.notifier).update(PrivacySettings(
                      showProfileTo: privacy.showProfileTo,
                      allowMessages: privacy.allowMessages,
                      showActivity: privacy.showActivity,
                      allowAddProches: v == 'all',
                      showZone: privacy.showZone,
                      showAge: privacy.showAge,
                      showDetails: privacy.showDetails,
                      invisibleMode: privacy.invisibleMode,
                    )),
                  ),
                  const Divider(height: 1),
                  _PrivacySwitch(
                    label: 'Afficher ma zone active',
                    value: privacy.showZone,
                    onChanged: (v) => ref.read(privacyProvider.notifier).update(PrivacySettings(
                      showProfileTo: privacy.showProfileTo,
                      allowMessages: privacy.allowMessages,
                      showActivity: privacy.showActivity,
                      allowAddProches: privacy.allowAddProches,
                      showZone: v,
                      showAge: privacy.showAge,
                      showDetails: privacy.showDetails,
                      invisibleMode: privacy.invisibleMode,
                    )),
                  ),
                  _PrivacySwitch(
                    label: 'Afficher mon Ã¢ge',
                    value: privacy.showAge,
                    onChanged: (v) => ref.read(privacyProvider.notifier).update(PrivacySettings(
                      showProfileTo: privacy.showProfileTo,
                      allowMessages: privacy.allowMessages,
                      showActivity: privacy.showActivity,
                      allowAddProches: privacy.allowAddProches,
                      showZone: privacy.showZone,
                      showAge: v,
                      showDetails: privacy.showDetails,
                      invisibleMode: privacy.invisibleMode,
                    )),
                  ),
                  _PrivacySwitch(
                    label: 'Afficher "Plus de dÃ©tails"',
                    value: privacy.showDetails,
                    onChanged: (v) => ref.read(privacyProvider.notifier).update(PrivacySettings(
                      showProfileTo: privacy.showProfileTo,
                      allowMessages: privacy.allowMessages,
                      showActivity: privacy.showActivity,
                      allowAddProches: privacy.allowAddProches,
                      showZone: privacy.showZone,
                      showAge: privacy.showAge,
                      showDetails: v,
                      invisibleMode: privacy.invisibleMode,
                    )),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mode invisible', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('Personne ne me voit dans la zone',
                      style: TextStyle(fontSize: 12, color: t.colorScheme.onSurfaceVariant)),
                    value: privacy.invisibleMode,
                    activeThumbColor: AppTheme.primary,
                    onChanged: (v) => ref.read(privacyProvider.notifier).update(PrivacySettings(
                      showProfileTo: privacy.showProfileTo,
                      allowMessages: privacy.allowMessages,
                      showActivity: privacy.showActivity,
                      allowAddProches: privacy.allowAddProches,
                      showZone: privacy.showZone,
                      showAge: privacy.showAge,
                      showDetails: privacy.showDetails,
                      invisibleMode: v,
                    )),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          // â”€â”€â”€ Section juridique â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.gavel_rounded, color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text('Informations lÃ©gales',
                      style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                _LegalTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Politique de confidentialitÃ©',
                  subtitle: 'Loi algÃ©rienne 18-07 & RGPD',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                ),
                const Divider(height: 1),
                _LegalTile(
                  icon: Icons.description_outlined,
                  label: 'Conditions d\'utilisation',
                  subtitle: 'CGU de ProximitÃ©',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
                ),
                const Divider(height: 1),
                _LegalTile(
                  icon: Icons.delete_sweep_outlined,
                  label: 'Supprimer mon compte',
                  subtitle: 'Effacer toutes mes donnÃ©es',
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'com.example.herzon'));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('ID de l\'application copiÃ©'),
                behavior: SnackBarBehavior.floating,
              ));
            },
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text('Cette action est irrÃ©versible. Toutes vos donnÃ©es '
            '(publications, messages, rÃ©actions, photos) seront dÃ©finitivement '
            'effacÃ©es.\n\nVoulez-vous vraiment supprimer votre compte ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              final uid = Supabase.instance.client.auth.currentUser?.id;
              if (uid != null) {
                await Supabase.instance.client.from('profiles').delete().eq('id', uid);
                await Supabase.instance.client.auth.signOut();
              }
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Supprimer dÃ©finitivement'),
          ),
        ],
      ),
    );
  }
}

class _PrivacySwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PrivacySwitch({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      value: value,
      activeThumbColor: AppTheme.primary,
      onChanged: onChanged,
    );
  }
}

class _PrivacyDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final List<String> itemLabels;
  final ValueChanged<String> onChanged;
  const _PrivacyDropdown({
    required this.label, required this.value, required this.items,
    required this.itemLabels, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            items: List.generate(items.length, (i) => DropdownMenuItem(
              value: items[i],
              child: Text(itemLabels[i], style: TextStyle(color: t.colorScheme.onSurfaceVariant, fontSize: 13)),
            )),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ],
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _LegalTile({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}

class _BlockedUserTile extends ConsumerStatefulWidget {
  final String userId;
  const _BlockedUserTile({required this.userId});

  @override
  ConsumerState<_BlockedUserTile> createState() => _BlockedUserTileState();
}

class _BlockedUserTileState extends ConsumerState<_BlockedUserTile> {
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('display_name, username, avatar_url')
          .eq('id', widget.userId)
          .maybeSingle();
      if (mounted) setState(() => _profile = data);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(gradient: AppTheme.brandGradient, shape: BoxShape.circle),
            child: _profile?['avatar_url'] != null
                ? ClipRRect(borderRadius: BorderRadius.circular(20),
                    child: Image.network(_profile!['avatar_url'] as String, fit: BoxFit.cover))
                : const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_profile?['display_name'] ?? _profile?['username'] ?? widget.userId,
              style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(blockProvider.notifier).unblockUser(widget.userId);
            },
            child: const Text('DÃ©bloquer', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}
