import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bilingual.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../utils/category.dart';

/// Section title with an optional trailing action.
class DcaSectionHeader extends StatelessWidget {
  const DcaSectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: context.text.titleLarge)),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!),
          ),
      ],
    );
  }
}

/// Category pill in its accent tint.
class DcaCategoryChip extends ConsumerWidget {
  const DcaCategoryChip(this.category, {super.key, this.onSurface = false});

  final NewsCategory category;
  final bool onSurface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider.select((s) => s.lang));
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: onSurface ? context.colors.surface : category.tint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category.label.of(lang),
        style: context.text.labelMedium?.copyWith(color: category.color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Small rounded tag (exam names, relevance).
class DcaTag extends StatelessWidget {
  const DcaTag(this.label, {super.key, this.reward = false});

  final String label;
  final bool reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: reward ? context.dca.rewardContainer : context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: reward ? context.dca.onRewardContainer : context.colors.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Streak or coin chip in saffron.
class DcaRewardChip extends StatelessWidget {
  const DcaRewardChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: context.dca.rewardContainer, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.dca.reward),
          const SizedBox(width: 4),
          Text(label, style: context.text.labelLarge?.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

/// Number tile for dashboards.
class DcaStatTile extends StatelessWidget {
  const DcaStatTile({super.key, required this.label, required this.value, this.caption, this.reward = false});

  final String label;
  final String value;
  final String? caption;
  final bool reward;

  @override
  Widget build(BuildContext context) {
    final bg = reward ? context.dca.rewardContainer : context.colors.primaryContainer;
    final fg = reward ? context.dca.onRewardContainer : context.colors.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(caption!, style: context.text.labelSmall?.copyWith(color: fg)),
          ],
        ],
      ),
    );
  }
}

/// EN / हिं toggle for content language.
class DcaLangToggle extends ConsumerWidget {
  const DcaLangToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider.select((s) => s.lang));
    return SegmentedButton<Lang>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: const [
        ButtonSegment(value: Lang.en, label: Text('EN')),
        ButtonSegment(value: Lang.hi, label: Text('हिं')),
      ],
      selected: {lang},
      onSelectionChanged: (s) => ref.read(settingsProvider.notifier).setLang(s.first),
    );
  }
}

/// Visual state of one MCQ option.
enum OptionState { idle, correct, wrong, dimmed }

class DcaMcqOption extends StatelessWidget {
  const DcaMcqOption({
    super.key,
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = context.dca;
    final (Color bg, Color border, double width, Color badgeBg, Color badgeFg) = switch (state) {
      OptionState.correct => (d.successContainer, d.success, 2.0, d.success, c.surface),
      OptionState.wrong => (d.errorContainer, d.error, 2.0, d.error, c.surface),
      OptionState.dimmed => (c.surface, c.outline, 1.5, d.surfaceHigh, d.inkSecondary),
      OptionState.idle => (c.surface, c.outline, 1.5, d.surfaceHigh, c.onSurface),
    };
    return Semantics(
      button: true,
      label: '$letter. $text${state == OptionState.correct ? ', correct answer' : state == OptionState.wrong ? ', your answer, wrong' : ''}',
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: width),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10)),
                    child: Text(letter, style: context.text.labelLarge?.copyWith(color: badgeFg)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(text, style: context.text.bodyLarge?.copyWith(height: 1.35))),
                  if (state == OptionState.correct) Icon(Icons.check_circle, color: d.success, size: 20),
                  if (state == OptionState.wrong) Icon(Icons.cancel, color: d.error, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered message for empty or failed lists.
class DcaEmptyState extends StatelessWidget {
  const DcaEmptyState({super.key, required this.icon, required this.title, this.message, this.action, this.onAction});

  final IconData icon;
  final String title;
  final String? message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.colors.primary),
            const SizedBox(height: 12),
            Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, style: context.text.bodyMedium?.copyWith(color: context.dca.inkSecondary), textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}
