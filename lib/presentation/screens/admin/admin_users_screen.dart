import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_users_provider.dart';
import '../../widgets/admin/admin_user_card.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(adminUsersProvider.notifier).loadUsers();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                ref.read(adminUsersProvider.notifier).loadUsers(search: value);
                setState(() {});
              },
            ),
          ),
          // Users list
          Expanded(
            child: usersState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                : usersState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur: ${usersState.error}',
                              style: GoogleFonts.plusJakartaSans(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(adminUsersProvider.notifier).loadUsers(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : usersState.users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun utilisateur trouvé',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: usersState.users.length,
                            itemBuilder: (context, index) {
                              final user = usersState.users[index];
                              return AdminUserCard(
                                user: user,
                                onToggleAdmin: () {
                                  ref.read(adminUsersProvider.notifier).toggleAdmin(
                                        user.id,
                                        !(user.isAdmin == true),
                                      );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
