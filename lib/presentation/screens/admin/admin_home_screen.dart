import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_posts_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_zones_screen.dart';
import 'admin_messages_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_notifications_screen.dart';

/// Admin shell — entry point for all admin screens.
///
/// 🔐 Security rules:
///   • Only users with `is_admin = true` in their profile may access this.
///   • The guard is enforced at render time AND on every hot-reload /
///     state change via [ref.watch(authProvider)].
///   • On failure the user is sent back with [Navigator.pop] and a
///     SnackBar explaining the situation.
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  var _currentIndex = 0;

  static const _screens = [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminPostsScreen(),
    AdminReportsScreen(),
    AdminZonesScreen(),
    AdminMessagesScreen(),
    AdminAnalyticsScreen(),
    AdminNotificationsScreen(),
  ];

  static const _titles = [
    'Tableau de bord',
    'Utilisateurs',
    'Publications',
    'Signalements',
    'Zones',
    'Messages',
    'Analytiques',
    'Alertes Admin',
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // ── 🔐 Admin Guard ────────────────────────────────────────────────────────
    // Show nothing while auth is loading
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Redirect non-admins immediately
    if (!authState.isAuthenticated || authState.user?.isAdmin != true) {
      // Use addPostFrameCallback so we don't call Navigator during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Accès refusé — Réservé aux administrateurs.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
      // Return blank scaffold while frame callback fires
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // ── End Guard ─────────────────────────────────────────────────────────────

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: const Color(0xFF1E293B),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _titles[_currentIndex],
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        actions: [
          // Admin badge chip
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(Icons.shield_rounded,
                  size: 14, color: Colors.white),
              label: Text(
                'Admin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color(0xFF4F46E5),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          elevation: 0,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
          destinations: [
            _nav(Icons.dashboard_outlined,   Icons.dashboard,              'Dashboard'),
            _nav(Icons.people_outline,        Icons.people,                 'Users'),
            _nav(Icons.article_outlined,      Icons.article,                'Posts'),
            _nav(Icons.flag_outlined,         Icons.flag,                   'Reports'),
            _nav(Icons.map_outlined,          Icons.map,                    'Zones'),
            _nav(Icons.chat_bubble_outline,   Icons.chat_bubble,            'Messages'),
            _nav(Icons.analytics_outlined,    Icons.analytics,              'Analytics'),
            _nav(Icons.notifications_active_outlined,
                 Icons.notifications_active, 'Alertes'),
          ],
        ),
      ),
    );
  }

  NavigationDestination _nav(
    IconData outlineIcon,
    IconData filledIcon,
    String label,
  ) {
    return NavigationDestination(
      icon: Icon(outlineIcon,
          color: const Color(0xFF94A3B8), size: 22),
      selectedIcon: Icon(filledIcon,
          color: const Color(0xFF4F46E5), size: 22),
      label: label,
    );
  }
}
