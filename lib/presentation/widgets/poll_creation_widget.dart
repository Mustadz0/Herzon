import 'package:flutter/material.dart';
import 'package:herzon/core/theme/app_theme.dart';

/// Widget for building a poll inside the post creation flow.
/// Lives in widgets/ — NOT screens/ — as it is a reusable UI component.
class PollCreationWidget extends StatefulWidget {
  final bool enabled;
  final ValueChanged<List<String>>? onChanged;
  final VoidCallback? onToggle;

  const PollCreationWidget({
    super.key,
    this.enabled = false,
    this.onChanged,
    this.onToggle,
  });

  @override
  State<PollCreationWidget> createState() => _PollCreationWidgetState();
}

class _PollCreationWidgetState extends State<PollCreationWidget> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _addOption();
      _addOption();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    final controller = TextEditingController();
    _controllers.add(controller);
    controller.addListener(_notifyChange);
    setState(() {});
  }

  void _removeOption(int index) {
    if (_controllers.length <= 2) return;
    _controllers[index].removeListener(_notifyChange);
    _controllers[index].dispose();
    _controllers.removeAt(index);
    _notifyChange();
    setState(() {});
  }

  void _notifyChange() {
    widget.onChanged?.call(
      _controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    if (!widget.enabled) {
      return InkWell(
        onTap: widget.onToggle,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.poll_outlined, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add a poll',
                style: context.theme.textTheme.bodyMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Poll Options',
                style: context.theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: widget.onToggle,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Remove poll',
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_controllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controllers[index],
                      decoration: InputDecoration(
                        hintText: 'Option \${index + 1}',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  if (_controllers.length > 2)
                    IconButton(
                      onPressed: () => _removeOption(index),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: cs.error,
                    ),
                ],
              ),
            );
          }),
          if (_controllers.length < 6)
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add option'),
            ),
        ],
      ),
    );
  }
}
