import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/marketplace_item_model.dart';
import '../providers/marketplace_provider.dart';
import 'user_profile_screen.dart';

class MarketplaceDetailScreen extends ConsumerWidget {
  final MarketplaceItemModel item;

  const MarketplaceDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final isOwnItem = user != null && user.id == item.userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Annonce')),
      body: ListView(
        children: [
          if (item.images.isNotEmpty)
            SizedBox(
              height: 300,
              width: double.infinity,
              child: PageView.builder(
                itemCount: item.images.length,
                itemBuilder: (_, i) => Image.network(item.images[i], fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                    if (item.price != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${item.price!.toStringAsFixed(0)} DA',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(_formatDistance(item.distanceMeters), style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(item.category, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                    ),
                    const Spacer(),
                    if (item.createdAt != null)
                      Text(_formatTime(item.createdAt!), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => UserProfileScreen(userId: item.userId),
                  )),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: item.userAvatarUrl != null ? NetworkImage(item.userAvatarUrl!) : null,
                        child: item.userAvatarUrl == null ? const Icon(Icons.person, size: 20) : null,
                      ),
                      const SizedBox(width: 8),
                      Text(item.userDisplayName ?? item.userUsername ?? 'Anonyme',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(height: 32),
                const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(item.description.isNotEmpty ? item.description : 'Aucune description',
                  style: TextStyle(fontSize: 15, color: item.description.isEmpty ? Colors.grey : null, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isOwnItem
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(marketplaceProvider.notifier).markAsSold(item.id),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Marquer comme vendu'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                ),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final msg = 'Bonjour, je suis interesse par: ${item.title} (${item.price?.toStringAsFixed(0) ?? "a discuter"} DA)';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Message copie: $msg')),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Contacter le vendeur'),
                  ),
                ),
              ),
            ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return 'a ${meters.toStringAsFixed(0)}m';
    return 'a ${(meters / 1000).toStringAsFixed(1)}km';
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}
