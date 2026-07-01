import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingPage(
      icon: Icons.explore,
      title: 'Decouvre ton quartier',
      description: 'Trouve des gens autour de toi dans un rayon de 2 km. Partage des moments avec ta communaute locale.',
      color: Colors.blue,
    ),
    _OnboardingPage(
      icon: Icons.auto_stories,
      title: 'Stories en direct',
      description: 'Publie des stories photos et video. Voit ce qui se passe autour de toi en temps reel.',
      color: Colors.orange,
    ),
    _OnboardingPage(
      icon: Icons.chat_bubble,
      title: 'Discussion et partage',
      description: 'Commente, reagis avec des emojis, et connecte avec les gens pres de chez toi.',
      color: Colors.green,
    ),
  ];

  void _onDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) =>
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == i ? Theme.of(context).primaryColor : Colors.grey.shade300,
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
                    if (_currentPage == _pages.length - 1) {
                      _onDone();
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  },
                  child: Text(_currentPage == _pages.length - 1 ? 'Commencer' : 'Suivant'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentPage < _pages.length - 1)
              TextButton(
                onPressed: _onDone,
                child: const Text('Passer'),
              ),
            const SizedBox(height: 32),
          ],
        ),
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
