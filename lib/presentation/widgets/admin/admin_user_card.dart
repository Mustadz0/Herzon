import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/user_model.dart';

class AdminUserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onToggleAdmin;

  const AdminUserCard({
    super.key,
    required this.user,
    this.onTap,
    this.onToggleAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
          child: user.avatarUrl == null
              ? Text(
                  (user.displayName ?? user.username ?? 'U')[0].toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4F46E5),
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName ?? 'Sans nom',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (user.isAdmin == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Admin',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '@${user.username ?? 'inconnu'}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
            if (user.createdAt != null) ...[
              const SizedBox(height: 2),
              Text(
                'Inscrit le ${DateFormat('dd/MM/yyyy').format(user.createdAt!)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ],
        ),
        trailing: onToggleAdmin != null
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'toggle_admin') onToggleAdmin!();
                },
                icon: const Icon(Icons.more_vert, size: 20),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_admin',
                    child: Row(
                      children: [
                        Icon(
                          user.isAdmin == true ? Icons.person_remove : Icons.admin_panel_settings,
                          size: 18,
                          color: const Color(0xFF4F46E5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.isAdmin == true ? 'Retirer admin' : 'Rendre admin',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
