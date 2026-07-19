import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';

class PostPhotoView extends StatelessWidget {
  final PostModel post;

  const PostPhotoView({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final urls = post.mediaUrls;
    if (urls.length == 1) {
      return _singleImage(context, urls[0]);
    }
    return _mosaic(urls);
  }

  Widget _singleImage(BuildContext context, String url) {
    return GestureDetector(
      onTap: () => _showVignette(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 300,
          errorBuilder: (_, __, ___) => Container(
            height: 300,
            color: Colors.grey[900],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mosaic(List<String> urls) {
    return SizedBox(
      height: 300,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _showVignette(null, urls[0]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  urls[0],
                  fit: BoxFit.cover,
                  height: 300,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white24),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: urls.length > 1 ? () => _showVignette(null, urls[1]) : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        urls.length > 1 ? urls[1] : '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey[900]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: urls.length > 2 ? () => _showVignette(null, urls[2]) : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: urls.length > 2
                          ? Image.network(
                              urls[2],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey[900]),
                            )
                          : Container(color: Colors.grey[900]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVignette(BuildContext? context, String imageUrl) {
    if (context == null) return;
    late VoidCallback onClose;
    final overlay = OverlayEntry(
      builder: (_) => _VignettePopup(
        imageUrl: imageUrl,
        onClose: () => onClose(),
      ),
    );
    onClose = () => overlay.remove();
    Overlay.of(context).insert(overlay);
  }
}

class _VignettePopup extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onClose;

  const _VignettePopup({required this.imageUrl, required this.onClose});

  @override
  State<_VignettePopup> createState() => _VignettePopupState();
}

class _VignettePopupState extends State<_VignettePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _ctrl.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _close,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            color: Colors.black.withValues(alpha: 0.92),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.85,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: _scaleAnim,
                  child: GestureDetector(
                    onTap: () {},
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width,
                          maxHeight: MediaQuery.of(context).size.height * 0.82,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              width: 200, height: 200,
                              color: Colors.grey[900],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.white24,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 16,
                  child: GestureDetector(
                    onTap: _close,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
