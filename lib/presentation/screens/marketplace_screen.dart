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
    final state = ref.watch(marketplaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marche'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(marketplaceProvider.notifier).loadItems(category: state.selectedCategory),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: marketplaceCategories.length,
              itemBuilder: (_, i) {
                final cat = marketplaceCategories[i];
                final selected = (state.selectedCategory ?? 'Tout') == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(fontSize: 13, color: selected ? Colors.white : null)),
                    selected: selected,
                    selectedColor: AppTheme.primaryColor,
                    onSelected: (_) => ref.read(marketplaceProvider.notifier).loadItems(category: cat),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text('Erreur: ${state.error}'),
                            TextButton(onPressed: () => ref.read(marketplaceProvider.notifier).loadItems(), child: const Text('Reessayer')),
                          ],
                        ),
                      )
                    : state.items.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.store, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('Rien a vendre dans le coin', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                SizedBox(height: 8),
                                Text('Sois le premier a proposer quelque chose!', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref.read(marketplaceProvider.notifier).loadItems(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: state.items.length,
                              itemBuilder: (_, i) => _MarketplaceCard(item: state.items[i]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateMarketplaceItemScreen()),
          );
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => MarketplaceDetailScreen(item: item),
        )),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: item.images.isNotEmpty
                      ? Image.network(item.images.first, fit: BoxFit.cover)
                      : Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(item.description, style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.price != null)
                          Text('${item.price!.toStringAsFixed(0)} DA',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 15)),
                        if (item.price != null) const SizedBox(width: 12),
                        Text(_formatDistance(item.distanceMeters), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        const Spacer(),
                        Text(item.category, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
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
