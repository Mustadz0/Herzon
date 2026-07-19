import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../providers/suggestion_provider.dart';
import 'suggestion_card.dart';

/// Slide-up panel that renders the suggestion feed inside the Explorer.
/// Controlled by [isVisible] from the parent ExplorerScreen.
class SuggestionPanel extends ConsumerStatefulWidget {
  const SuggestionPanel({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  ConsumerState<SuggestionPanel> createState() => _SuggestionPanelState();
}

class _SuggestionPanelState extends ConsumerState<SuggestionPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    _anim.forward();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _loadSuggestions() {
    ref.read(suggestionProvider.notifier).loadSuggestions();
  }

  Future<void> _close() async {
    await _anim.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(suggestionProvider);
    final t      = Theme.of(context);
    final cs     = t.colorScheme;
    final isDark = t.isDark;

    return SlideTransition(
      position: _slide,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header row ───────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (r) =>
                        AppTheme.brandGradient.createShader(r),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Suggestions pour vous',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Refresh button
                  if (!state.isLoading)
                    GestureDetector(
                      onTap: _loadSuggestions,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  // Close button
                  GestureDetector(
                    onTap: _close,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.52,
              child: _buildContent(state, cs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(_SuggestionState state, ColorScheme cs) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 40, color: cs.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  color: cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadSuggestions,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_off_rounded,
                size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              'Aucune suggestion pour l\'instant',
              style: GoogleFonts.plusJakartaSans(
                  color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: state.posts.length,
      itemBuilder: (_, i) => SuggestionCard(
        post: state.posts[i],
        rank: i + 1,
      ),
    );
  }
}

// ── Local state alias (re-exported for readability) ───────────────────────
typedef _SuggestionState = SuggestionState;
