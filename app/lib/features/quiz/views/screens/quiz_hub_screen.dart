import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/models/bilingual.dart';
import '../../../../common/providers/settings_provider.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../../common/utils/category.dart';
import '../../../../common/widgets/dca_widgets.dart';
import '../../../news/data/models/article.dart';
import '../../../news/data/providers/news_providers.dart';
import '../../../profile/data/providers/progress_provider.dart';
import '../../data/providers/quiz_provider.dart';

/// Pick a quiz: daily, by category, or your mistakes.
class QuizHubScreen extends ConsumerWidget {
  const QuizHubScreen({super.key});

  static const routePath = '/quiz-hub';

  void _start(BuildContext context, WidgetRef ref, String title, List<Article> articles, {int count = 10, Set<String>? onlyIds}) {
    final items = buildQuizItems(articles, count: count, onlyIds: onlyIds);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No questions available yet.')));
      return;
    }
    ref.read(quizProvider.notifier).start(title: title, items: items);
    context.push('/quiz');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider.select((s) => s.lang));
    final mistakes = ref.watch(progressProvider.select((p) => p.mistakes));
    final articles = ref.watch(examArticlesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(lang == Lang.hi ? 'क्विज़' : 'Quiz')),
      body: articles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DcaEmptyState(icon: Icons.wifi_off, title: 'Could not load questions', message: '$e'),
        data: (list) {
          final total = list.fold<int>(0, (s, a) => s + a.mcqs.length);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _QuizCard(
                title: lang == Lang.hi ? 'डेली 10' : 'Daily 10',
                subtitle: '${total.clamp(0, 10)} questions · about 8 min · +20 coins',
                primary: true,
                onTap: () => _start(context, ref, 'Daily Quiz', list),
              ),
              const SizedBox(height: 12),
              _QuizCard(
                title: lang == Lang.hi ? 'डेली 25' : 'Daily 25',
                subtitle: '${total.clamp(0, 25)} questions from the last few days',
                onTap: () => _start(context, ref, 'Daily 25', list, count: 25),
              ),
              const SizedBox(height: 12),
              _QuizCard(
                title: lang == Lang.hi ? 'मेरी गलतियां' : 'My mistakes',
                subtitle: mistakes.isEmpty ? 'Nothing to fix. Nice!' : '${mistakes.length} questions to get right this time',
                onTap: mistakes.isEmpty ? null : () => _start(context, ref, 'Mistakes', list, count: 25, onlyIds: mistakes),
              ),
              const SizedBox(height: 24),
              DcaSectionHeader(lang == Lang.hi ? 'श्रेणी के अनुसार' : 'By category'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in NewsCategory.values)
                    if (list.any((a) => a.category == c && a.mcqs.isNotEmpty))
                      ActionChip(
                        avatar: Icon(c.icon, size: 16, color: c.color),
                        label: Text(c.label.of(lang)),
                        onPressed: () => _start(context, ref, c.label.of(lang), list.where((a) => a.category == c).toList()),
                      ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.title, required this.subtitle, required this.onTap, this.primary = false});

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? context.colors.primary : context.colors.surfaceContainerLow;
    final fg = primary ? context.colors.onPrimary : context.colors.onSurface;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: primary ? BorderSide.none : BorderSide(color: context.colors.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleLarge?.copyWith(color: fg)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: context.text.bodyMedium?.copyWith(color: primary ? const Color(0xFFD6E0FF) : context.dca.inkSecondary)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: onTap == null ? context.dca.inkSecondary : fg),
            ],
          ),
        ),
      ),
    );
  }
}
