import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserListTile extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserListTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user['display_name'] as String? ?? user['username'] as String? ?? 'Inconnu';
    final avatar = user['avatar_url'] as String?;
    final bio = user['bio'] as String?;

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
        child: avatar == null ? Icon(Icons.person, color: Colors.grey[400]) : null,
      ),
      title: Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      subtitle: bio != null ? Text(bio, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
    );
  }
}
