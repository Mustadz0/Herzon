import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_posts_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_zones_screen.dart';
import 'admin_messages_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_notifications_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  var _currentIndex = 0;

  final _screens = const [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminPostsScreen(),
    AdminReportsScreen(),
    AdminZonesScreen(),
    AdminMessagesScreen(),
    AdminAnalyticsScreen(),
    AdminNotificationsScreen(),
  ];

  final _titles = const [
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
            _buildNavDestination(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
            _buildNavDestination(1, Icons.people_outline, Icons.people, 'Users'),
            _buildNavDestination(2, Icons.article_outlined, Icons.article, 'Posts'),
            _buildNavDestination(3, Icons.flag_outlined, Icons.flag, 'Reports'),
            _buildNavDestination(4, Icons.map_outlined, Icons.map, 'Zones'),
            _buildNavDestination(5, Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages'),
            _buildNavDestination(6, Icons.analytics_outlined, Icons.analytics, 'Analytics'),
            _buildNavDestination(7, Icons.notifications_active_outlined, Icons.notifications_active, 'Alertes'),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    return NavigationDestination(
      icon: Icon(
        outlineIcon,
        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
        size: 22,
      ),
      selectedIcon: Icon(
        filledIcon,
        color: const Color(0xFF4F46E5),
        size: 22,
      ),
      label: label,
    );
  }
}
