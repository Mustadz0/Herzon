import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../../core/theme/app_theme.dart';
import 'feed_screen.dart';
import 'explorer_screen.dart';
import 'marketplace_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'edit_profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final notifState = ref.watch(notificationProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const FeedScreen(),
          const ExplorerScreen(),
          const MarketplaceScreen(),
          const NotificationsScreen(),
          const MessagesScreen(),
          _ProfileTab(user: auth.user),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.near_me), label: 'Pres'),
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Explorer'),
          const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Marche'),
          BottomNavigationBarItem(
            icon: notifState.unreadCount > 0
                ? Badge(
                    label: Text('${notifState.unreadCount}'),
                    child: const Icon(Icons.notifications),
                  )
                : const Icon(Icons.notifications_outlined),
            label: 'Infos',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  final dynamic user;
  const _ProfileTab({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: user?.avatarUrl != null
                  ? NetworkImage(user!.avatarUrl as String)
                  : null,
              backgroundColor: AppTheme.primaryColor,
              child: user?.avatarUrl == null
                  ? const Icon(Icons.person, size: 48, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Utilisateur',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (user?.bio != null) ...[
              const SizedBox(height: 8),
              Text(user!.bio, style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statColumn('0', 'Posts'),
                _statColumn('0', 'Abonnes'),
                _statColumn('0', 'Abonnements'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: user != null
                    ? () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => EditProfileScreen(user: user),
                      ))
                    : null,
                icon: const Icon(Icons.edit),
                label: const Text('Modifier le profil'),
              ),
            ),
            const SizedBox(height: 8),
            if (user?.isAdmin == true)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/admin'),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Admin Panel'),
                ),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Deconnexion', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}
