import 'package:flutter/material.dart';
import 'package:herzon/core/theme/app_theme.dart';
import 'package:herzon/data/models/poll_model.dart';

class PollWidget extends StatelessWidget {
  final PollModel poll;
  final ValueChanged<int>? onVote;

  const PollWidget({super.key, required this.poll, this.onVote});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final hasVoted = poll.hasVoted;
    final total = poll.totalVotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < poll.options.length; i++) ...[
          _OptionCard(
            option: poll.options[i],
            index: i,
            totalVotes: total,
            hasVoted: hasVoted,
            isSelected: hasVoted && poll.userVoteIndex == i,
            tappable: !hasVoted && onVote != null,
            onVote: () => onVote?.call(i),
          ),
          if (i < poll.options.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hasVoted ? 'Thanks for voting!' : 'Tap an option to vote',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            Text(
              '$total ${total == 1 ? 'vote' : 'votes'}',
              style: tt.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final PollOptionItem option;
  final int index;
  final int totalVotes;
  final bool hasVoted;
  final bool isSelected;
  final bool tappable;
  final VoidCallback? onVote;

  const _OptionCard({
    required this.option,
    required this.index,
    required this.totalVotes,
    required this.hasVoted,
    required this.isSelected,
    required this.tappable,
    this.onVote,
  });

  double get _percentage =>
      totalVotes == 0 ? 0.0 : (option.votes / totalVotes).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;

    final cardColor = isSelected ? cs.primaryContainer : cs.surface;
    final borderSide = isSelected
        ? BorderSide(color: cs.primary, width: 1.5)
        : BorderSide(color: cs.outlineVariant);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: isSelected ? 4 : 1,
      shadowColor: cs.primary.withValues(alpha: 0.12),
      child: InkWell(
        onTap: tappable ? onVote : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.fromBorderSide(borderSide),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IndexBubble(index: index, selected: isSelected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.text,
                      style: tt.titleSmall?.copyWith(
                        color: isSelected ? cs.primary : cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasVoted)
                    Text(
                      '${(_percentage * 100).toStringAsFixed(0)}%',
                      style: tt.labelLarge?.copyWith(
                        color: isSelected ? cs.primary : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              if (hasVoted) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _percentage,
                    minHeight: 8,
                    backgroundColor: cs.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isSelected ? cs.primary : cs.secondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IndexBubble extends StatelessWidget {
  final int index;
  final bool selected;
  const _IndexBubble({required this.index, required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? cs.primary : cs.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        '${index + 1}',
        style: tt.labelSmall?.copyWith(
          color: selected ? cs.onPrimary : cs.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
