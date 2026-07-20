import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/privacy_provider.dart';
import 'edit_profile_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

extension _ThemeDark on ThemeData {
  bool get isDark => brightness == Brightness.dark;
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final authState = ref.watch(authProvider);
    final privacyState = ref.watch(privacyProvider);
    // FIX: FirebaseAuth بدل Supabase.auth
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          // Profile section
          _SectionHeader(title: 'Profil'),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Modifier le profil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(user?.email ?? 'Non connecté',
              style: t.textTheme.bodySmall),
          ),

          const Divider(),
          _SectionHeader(title: 'Confidentialité'),

          // Ghost mode
          SwitchListTile(
            secondary: const Icon(Icons.visibility_off_outlined),
            title: const Text('Mode fantôme'),
            subtitle: const Text('Masque votre position'),
            value: privacyState.ghostMode,
            onChanged: privacyState.isLoading
                ? null
                : (v) => ref.read(privacyProvider.notifier).setGhostMode(v),
          ),

          // Anonymous mode
          SwitchListTile(
            secondary: const Icon(Icons.person_off_outlined),
            title: const Text('Mode anonyme'),
            subtitle: const Text('Publie sous pseudonyme'),
            value: privacyState.anonymousMode,
            onChanged: privacyState.isLoading
                ? null
                : (v) => ref.read(privacyProvider.notifier).setAnonymousMode(v),
          ),

          const Divider(),
          _SectionHeader(title: 'À propos'),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Conditions d\'utilisation'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Se déconnecter ?'),
                  content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Déconnecter'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authProvider.notifier).signOut();
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: t.textTheme.labelLarge?.copyWith(
          color: t.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
