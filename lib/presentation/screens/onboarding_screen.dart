import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  bool _privacyAccepted = false;

  final _pages = [
    const _OnboardingPage(
      icon: Icons.explore,
      title: 'Découvre ton quartier',
      description: 'Trouve des gens autour de toi dans un rayon de 500 m. Partage des moments avec ta communauté locale.',
      color: AppTheme.primary,
    ),
    const _OnboardingPage(
      icon: Icons.auto_stories,
      title: 'Stories en direct',
      description: 'Publie des stories photos et vidéo. Vois ce qui se passe autour de toi en temps réel.',
      color: AppTheme.accent,
    ),
    const _OnboardingPage(
      icon: Icons.chat_bubble,
      title: 'Discussion et partage',
      description: 'Commente, réagis avec des emojis, et connecte avec les gens près de chez toi.',
      color: AppTheme.success,
    ),
  ];

  void _onDone() async {
    if (!_privacyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez accepter la politique de confidentialité pour continuer'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setBool('privacy_accepted', true);
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length + 1, // +1 for consent page
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) {
                  if (i == _pages.length) return _buildConsentPage(t);
                  return _pages[i];
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length + 1, (i) =>
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == i ? AppTheme.primary : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length) {
                      _onDone();
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    }
                  },
                  child: Text(_currentPage == _pages.length ? 'Commencer' : 'Suivant'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentPage < _pages.length)
              TextButton(
                onPressed: () => _controller.animateToPage(
                  _pages.length, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                child: const Text('Passer'),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentPage(ThemeData t) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.privacy_tip, size: 64, color: AppTheme.primary),
          ),
          const SizedBox(height: 24),
          Text('Protection des données',
            style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Conformément Ã  la loi algérienne nÂ° 18-07 et au RGPD, '
              'vos données personnelles (localisation, photos, interactions) '
              'sont traitées uniquement pour le fonctionnement de l\'application.',
            textAlign: TextAlign.center,
            style: t.textTheme.bodyMedium?.copyWith(height: 1.5)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen())),
                child: const Text('Politique de confidentialité',
                  style: TextStyle(fontSize: 13, decoration: TextDecoration.underline)),
              ),
              const SizedBox(width: 8),
              Text('et', style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const TermsOfServiceScreen())),
                child: const Text('CGU',
                  style: TextStyle(fontSize: 13, decoration: TextDecoration.underline)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.isDark ? AppTheme.cardDark : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24, height: 24,
                  child: Checkbox(
                    value: _privacyAccepted,
                    activeColor: AppTheme.primary,
                    onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'J\'accepte la collecte et le traitement de mes données '
                    'personnelles conformément Ã  la politique de confidentialité.',
                    style: t.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPage({required this.icon, required this.title, required this.description, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 40),
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}
