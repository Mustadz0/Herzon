import 'package:flutter/material.dart';
import 'package:herzon/core/theme/app_theme.dart';

/// Stateful editor for creating a poll with one question and 2..N options.
///
/// In modal form use [show] which displays the editor bottom sheet and
/// returns the entered option strings, or `null` if the user cancels.
///
/// In inline form, embed [PollCreationWidget] inside a parent form and
/// listen to [onOptionsChanged] / [onSubmit].
class PollCreationWidget extends StatefulWidget {
  final String? initialQuestion;
  final List<String>? initialOptions;

  /// Live-updated list of currently entered (non-empty) options.
  final ValueChanged<List<String>>? onOptionsChanged;

  /// Called when the user submits the form. Receives the trimmed question
  /// and the non-empty option list.
  final void Function(String question, List<String> options)? onSubmit;

  const PollCreationWidget({
    super.key,
    this.initialQuestion,
    this.initialOptions,
    this.onOptionsChanged,
    this.onSubmit,
  });

  /// Show the editor in a bottom sheet and resolve with `[options]` on
  /// submit, or `null` if the sheet is dismissed.
  static Future<List<String>?> show(
    BuildContext context, {
    String? initialQuestion,
    List<String>? initialOptions,
  }) {
    final cs = context.cs;
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: PollCreationWidget(
          initialQuestion: initialQuestion,
          initialOptions: initialOptions,
        ),
      ),
    );
  }

  @override
  State<PollCreationWidget> createState() => _PollCreationWidgetState();
}

class _PollCreationWidgetState extends State<PollCreationWidget> {
  static const int _minOptions = 2;
  static const int _maxOptions = 8;

  late final TextEditingController _questionController;
  late final List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.initialQuestion ?? '');
    final seed = widget.initialOptions ?? const <String>[];
    _optionControllers = seed.length >= _minOptions
        ? [for (final s in seed) TextEditingController(text: s)]
        : [TextEditingController(), TextEditingController()];
    for (final c in _optionControllers) {
      c.addListener(_emit);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _collectOptions() => [
        for (final c in _optionControllers) c.text.trim(),
      ].where((s) => s.isNotEmpty).toList();

  void _emit() {
    if (!mounted || widget.onOptionsChanged == null) return;
    widget.onOptionsChanged!(_collectOptions());
  }

  void _addOption() {
    if (_optionControllers.length >= _maxOptions) return;
    final c = TextEditingController();
    c.addListener(_emit);
    setState(() => _optionControllers.add(c));
    _emit();
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= _minOptions) return;
    final c = _optionControllers.removeAt(index);
    c.removeListener(_emit);
    c.dispose();
    _emit();
    setState(() {});
  }

  void _submit() {
    final question = _questionController.text.trim();
    final options = _collectOptions();
    if (question.isEmpty || options.length < _minOptions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a question and at least 2 options.')),
      );
      return;
    }
    final navigator = Navigator.of(context);
    widget.onSubmit?.call(question, options);
    navigator.pop(options);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Create a poll', style: tt.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _questionController,
            style: tt.titleMedium,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Question',
              hintText: 'What do you want to ask?',
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _optionControllers.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _OptionRow(
              controller: _optionControllers[i],
              index: i,
              removable: _optionControllers.length > _minOptions,
              onRemove: () => _removeOption(i),
            ),
          ],
          const SizedBox(height: 4),
          if (_optionControllers.length < _maxOptions)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add_rounded),
                label: const Text('+ Option'),
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Create Poll'),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final TextEditingController controller;
  final int index;
  final bool removable;
  final VoidCallback onRemove;

  const _OptionRow({
    required this.controller,
    required this.index,
    required this.removable,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${index + 1}',
            style: tt.labelSmall?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            style: tt.bodyMedium,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: 'Option ${index + 1}'),
          ),
        ),
        if (removable)
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            color: cs.onSurfaceVariant,
            tooltip: 'Remove option',
          ),
      ],
    );
  }
}
