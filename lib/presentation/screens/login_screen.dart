import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primary.withValues(alpha: 0.05), t.scaffoldBackgroundColor],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Image.asset(
                  'assets/images/logo_new.png',
                  width: 120, height: 120,
                ),
                const SizedBox(height: 8),
                Text("DÃ©couvrez ce qui se passe autour de vous",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
                const Spacer(flex: 2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: t.isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: auth.isLoading ? null : () => ref.read(authProvider.notifier).signInWithGoogle(),
                          icon: const Icon(Icons.login, size: 20),
                          label: const Text('Continuer avec Google'),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Connectez-vous pour accéder à toutes les fonctionnalités',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center),
                      if (auth.isLoading)
                        const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator()),
                      if (auth.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(auth.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                        ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
