import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final blockState = ref.watch(blockProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── Blocked users ───────────────────────────────────────
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.block_rounded,
                          color: cs.error, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Utilisateurs bloqués',
                              style: tt.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            '\${blockState.blockedUsers.length} utilisateur(s)',
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (blockState.isLoading)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator()))
                else if (blockState.blockedUsers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 40,
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text('Aucun utilisateur bloqué',
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  )
                else
                  ...blockState.blockedUsers
                      .map((uid) => _BlockedUserTile(userId: uid)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Privacy ──────────────────────────────────────────────
          Consumer(builder: (context, ref, _) {
            final privacy = ref.watch(privacyProvider);
            return _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.shield_rounded,
                    label: 'Confidentialité',
                  ),
                  const SizedBox(height: 16),
                  _PrivacyDropdown(
                    label: 'Qui peut voir mon profil',
                    value: privacy.showProfileTo,
                    items: const ['all', 'proches', 'nobody'],
                    itemLabels: const [
                      'Tous',
                      'Proches uniquement',
                      'Personne'
                    ],
                    onChanged: (v) =>
                        ref.read(privacyProvider.notifier).update(
                              privacy.copyWith(showProfileTo: v),
                            ),
                  ),
                  const Divider(height: 1),
                  _PrivacyDropdown(
                    label: "Qui peut m'envoyer un message",
                    value: privacy.allowMessages ? 'all' : 'nobody',
                    items: const ['all', 'proches', 'nobody'],
                    itemLabels: const [
                      'Tous',
                      'Proches uniquement',
                      'Personne'
                    ],
                    onChanged: (v) =>
                        ref.read(privacyProvider.notifier).update(
                              privacy.copyWith(allowMessages: v != 'nobody'),
                            ),
                  ),
                  const Divider(height: 1),
                  _PrivacyDropdown(
                    label: "Qui peut m'ajouter aux Proches",
                    value: privacy.allowAddProches ? 'all' : 'nobody',
                    items: const ['all', 'nobody'],
                    itemLabels: const ['Tous', 'Personne'],
                    onChanged: (v) =>
                        ref.read(privacyProvider.notifier).update(
                              privacy.copyWith(allowAddProches: v == 'all'),
                            ),
                  ),
                  const Divider(height: 1),
                  _PrivacySwitch(
                    label: 'Afficher ma zone active',
                    value: privacy.showZone,
                    onChanged: (v) =>
                        ref.read(privacyProvider.notifier).update(
                              privacy.copyWith(showZone: v),
                            ),
                  ),
                  _PrivacySwitch(
                    label: 'Afficher mon âge',
                    value: privacy.showAge,
                    onChanged: (v) =>
                        ref.read(privacyProvider.notifier).update(
                              privacy.copyWith(showAge: v),
                            ),
                  ),
                  _PrivacySwitch(
                    label: '"Plus de détails" visible',
                    value: privacy.showDetails,
                    onChanged: (v) =>
                        ref.read(privacyProvider.notifier).update(
                              privacy.copyWith(showDetails: v),
                            ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Mode invisible',
                        style: tt.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Personne ne me voit dans la zone',
                      style:
                          tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    value: privacy.invisibleMode,
                    activeColor: cs.primary,
                    onChanged: (v) =>
                        ref.read(privacyProvider.notifier).update(
                              privacy.copyWith(invisibleMode: v),
                            ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // ─── Legal ────────────────────────────────────────────────
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.gavel_rounded,
                  label: 'Informations légales',
                ),
                const SizedBox(height: 16),
                _LegalTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Politique de confidentialité',
                  subtitle: 'Loi algérienne 18-07 & RGPD',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen()),
                  ),
                ),
                const Divider(height: 1),
                _LegalTile(
                  icon: Icons.description_outlined,
                  label: "Conditions d'utilisation",
                  subtitle: 'CGU de Proximité',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TermsOfServiceScreen()),
                  ),
                ),
                const Divider(height: 1),
                _LegalTile(
                  icon: Icons.delete_sweep_outlined,
                  label: 'Supprimer mon compte',
                  subtitle: 'Effacer toutes mes données',
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(
                  const ClipboardData(text: 'com.heron.app'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("ID de l'application copié"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données '
          '(publications, messages, réactions, photos) seront définitivement '
          'effacées.\n\nVoulez-vous vraiment supprimer votre compte ?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              // ✅ Use FirebaseAuth instead of Supabase.auth
              final firebaseUser = FirebaseAuth.instance.currentUser;
              if (firebaseUser != null) {
                await Supabase.instance.client.functions
                    .invoke('delete-account');
                await FirebaseAuth.instance.signOut();
              }
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (_) => false);
              }
            },
            style:
                FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }
}

// ─── Shared card shell ───────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: cs.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(label,
            style:
                tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─── Privacy helpers ─────────────────────────────────────────────────────────

class _PrivacySwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PrivacySwitch(
      {required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label,
          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      value: value,
      activeColor: cs.primary,
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
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: tt.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            items: List.generate(
              items.length,
              (i) => DropdownMenuItem(
                value: items[i],
                child: Text(itemLabels[i],
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
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

  const _LegalTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: cs.onSurfaceVariant),
      title: Text(label,
          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      trailing:
          Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
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
      // widget.userId is already a Supabase UUID (from block_provider)
      final data = await Supabase.instance.client
          .from('profiles')
          .select('display_name, username, avatar_url')
          .eq('id', widget.userId)
          .maybeSingle();
      if (mounted) setState(() => _profile = data);
    } catch (e) {
      debugPrint('Failed to load profile: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                gradient: AppTheme.brandGradient,
                shape: BoxShape.circle),
            child: _profile?['avatar_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                        _profile!['avatar_url'] as String,
                        fit: BoxFit.cover))
                : const Icon(Icons.person,
                    color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _profile?['display_name'] ??
                  _profile?['username'] ??
                  widget.userId,
              style: tt.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(blockProvider.notifier).unblockUser(widget.userId),
            child: Text('Débloquer',
                style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
    );
  }
}
