import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/marketplace_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/marketplace_item_model.dart';
import 'marketplace_detail_screen.dart';
import 'create_marketplace_item_screen.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(marketplaceProvider.notifier).loadItems());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final state = ref.watch(marketplaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MarchÃ©'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(marketplaceProvider.notifier).loadItems(category: state.selectedCategory),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: marketplaceCategories.length,
              itemBuilder: (_, i) {
                final cat = marketplaceCategories[i];
                final selected = (state.selectedCategory ?? 'Tout') == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : t.colorScheme.onSurfaceVariant)),
                    selected: selected,
                    selectedColor: AppTheme.primary,
                    backgroundColor: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    onSelected: (_) => ref.read(marketplaceProvider.notifier).loadItems(category: cat),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off, size: 48, color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('Erreur: ${state.error}'),
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                            onPressed: () => ref.read(marketplaceProvider.notifier).loadItems(),
                            icon: const Icon(Icons.refresh, size: 18), label: const Text('RÃ©essayer')),
                        ],
                      ))
                    : state.items.isEmpty
                        ? Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                                child: Icon(Icons.store_outlined, size: 36, color: AppTheme.primary.withValues(alpha: 0.3)),
                              ),
                              const SizedBox(height: 20),
                              Text('Rien Ã  vendre dans le coin', style: t.textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text('Sois le premier Ã  proposer quelque chose !',
                                style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                            ],
                          ))
                        : RefreshIndicator(
                            onRefresh: () => ref.read(marketplaceProvider.notifier).loadItems(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: state.items.length,
                              itemBuilder: (_, i) => _MarketplaceCard(item: state.items[i]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreateMarketplaceItemScreen()));
          if (created == true) ref.read(marketplaceProvider.notifier).loadItems();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MarketplaceCard extends StatelessWidget {
  final MarketplaceItemModel item;
  const _MarketplaceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: t.isDark ? AppTheme.cardDark : AppTheme.cardGlassLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.isDark ? const Color(0x1AFFFFFF) : const Color(0x0A000000)),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: t.isDark ? 0.06 : 0.08), blurRadius: 24, offset: const Offset(0, 6))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplaceDetailScreen(item: item))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 88, height: 88,
                  child: item.images.isNotEmpty
                      ? Image.network(item.images.first, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)))
                      : Container(color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          child: const Icon(Icons.image_outlined, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(item.description, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (item.price != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${item.price!.toStringAsFixed(0)} DA',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.primary)),
                          ),
                        if (item.price != null) const SizedBox(width: 8),
                        Icon(Icons.near_me, size: 12, color: t.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(_formatDistance(item.distanceMeters),
                          style: TextStyle(color: t.colorScheme.onSurfaceVariant, fontSize: 11)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item.category, style: TextStyle(color: t.colorScheme.onSurfaceVariant, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}
