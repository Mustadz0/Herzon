import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/location_service.dart';
import '../providers/page_provider.dart';
import 'page_detail_screen.dart';

class PageListScreen extends ConsumerStatefulWidget {
  const PageListScreen({super.key});

  @override
  ConsumerState<PageListScreen> createState() => _PageListScreenState();
}

class _PageListScreenState extends ConsumerState<PageListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pageProvider.notifier).loadNearbyPages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final pageState = ref.watch(pageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreatePageSheet(context),
          ),
        ],
      ),
      body: pageState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : pageState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Erreur', style: t.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(pageState.error!, textAlign: TextAlign.center,
                          style: TextStyle(color: t.colorScheme.onSurfaceVariant, fontSize: 12)),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () => ref.read(pageProvider.notifier).loadNearbyPages(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : pageState.pages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag_outlined, size: 64, color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('Aucune page', style: t.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('CrÃ©ez une page pour votre organisation, commerce ou Ã©vÃ©nement',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => _showCreatePageSheet(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('CrÃ©er une page'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(pageProvider.notifier).loadNearbyPages(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pageState.pages.length,
                    itemBuilder: (_, i) {
                      final page = pageState.pages[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(gradient: AppTheme.brandGradient, borderRadius: BorderRadius.circular(12)),
                            child: Icon(_pageIcon(page.category), color: Colors.white, size: 22),
                          ),
                          title: Text(page.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(page.category, style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PageDetailScreen(page: page),
                          )),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _pageIcon(String category) {
    switch (category) {
      case 'commerce': return Icons.store;
      case 'organisation': return Icons.business;
      case 'evenement': return Icons.event;
      case 'artiste': return Icons.music_note;
      case 'service': return Icons.build;
      default: return Icons.flag;
    }
  }

  void _showCreatePageSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'organisation';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Text('Créer une page', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom de la page', hintText: 'Mon organisation')),
              const SizedBox(height: 12),
              TextField(controller: slugCtrl, decoration: const InputDecoration(labelText: 'Identifiant (slug)', hintText: 'mon-org', prefixText: '@')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optionnelle)'), maxLines: 3),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: const [
                  DropdownMenuItem(value: 'organisation', child: Text('Organisation')),
                  DropdownMenuItem(value: 'commerce', child: Text('Commerce')),
                  DropdownMenuItem(value: 'evenement', child: Text('Événement')),
                  DropdownMenuItem(value: 'artiste', child: Text('Artiste / Créateur')),
                  DropdownMenuItem(value: 'service', child: Text('Service')),
                ],
                onChanged: (v) => setSheetState(() => category = v ?? 'organisation'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final slug = slugCtrl.text.trim();
                    if (name.isEmpty || slug.isEmpty) return;

                    // Validate slug format (security: prevent injection)
                    final slugRegex = RegExp(r'^[a-z0-9-]{3,50}$');
                    if (!slugRegex.hasMatch(slug)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Slug invalide : 3-50 caractères, minuscules, chiffres et tirets uniquement'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                      ));
                      return;
                    }

                    // Get GPS coordinates
                    double? lat;
                    double? lng;
                    bool locationFailed = false;
                    try {
                      final locationService = ref.read(locationServiceProvider);
                      final pos = await locationService.initializeLocation();
                      lat = pos.latitude;
                      lng = pos.longitude;

                      // Validate Algeria bounds (security: prevent invalid geography)
                      if (lat < 19.5 || lat > 38.0 || lng < -2.91 || lng > 11.9) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Position hors d\'Algérie — page créée sans position'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.orange,
                        ));
                        lat = null;
                        lng = null;
                      }
                    } catch (_) {
                      locationFailed = true;
                    }

                    if (!ctx.mounted) return;

                    if (locationFailed && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('GPS indisponible — la page sera créée sans position'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.orange,
                      ));
                    }

                    await ref.read(pageProvider.notifier).createPage(
                      name: name,
                      slug: slug,
                      category: category,
                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      latitude: lat,
                      longitude: lng,
                    );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Page créée !'),
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  child: const Text('Créer la page'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
