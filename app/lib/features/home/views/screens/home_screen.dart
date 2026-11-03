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
import '../../../news/views/widgets/dca_news_tile.dart';
import '../../../profile/data/providers/progress_provider.dart';
import '../../../quiz/data/providers/quiz_provider.dart';
import '../../../revise/data/providers/revise_provider.dart';
import '../widgets/dca_today_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final progress = ref.watch(progressProvider);
    final articles = ref.watch(examArticlesProvider);
    final lang = settings.lang;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(articlesProvider.future),
          child: articles.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => DcaEmptyState(
              icon: Icons.wifi_off,
              title: 'Could not load today\'s news',
              message: '$e',
              action: 'Try again',
              onAction: () => ref.invalidate(articlesProvider),
            ),
            data: (list) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _Header(name: settings.name, streak: progress.streak, coins: progress.coins),
                const SizedBox(height: 16),
                if (list.any((a) => a.isBreaking)) ...[
                  _BreakingBanner(article: list.firstWhere((a) => a.isBreaking)),
                  const SizedBox(height: 16),
                ],
                DcaTodayCard(articles: list),
                const SizedBox(height: 24),
                DcaSectionHeader(lang == Lang.hi ? 'मुख्य समाचार' : 'Top headlines', action: 'See all', onAction: () => context.go('/news')),
                const SizedBox(height: 8),
                SizedBox(
                  height: 236,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length.clamp(0, 5),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => DcaHeadlineCard(list[i]),
                  ),
                ),
                const SizedBox(height: 8),
                _LiveRow(onTap: () => context.push('/live')),
                const SizedBox(height: 24),
                DcaSectionHeader(lang == Lang.hi ? 'आपकी परीक्षा के लिए' : 'Important for your exams'),
                for (final (i, a) in list.skip(list.length > 5 ? 5 : 0).take(4).indexed) DcaNewsTile(a, showDivider: i < 3),
                const SizedBox(height: 24),
                _CategoryGrid(lang: lang),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.streak, required this.coins});

  final String name;
  final int streak;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name.isEmpty ? greet : '$greet, $name', style: context.text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(MaterialLocalizations.of(context).formatMediumDate(DateTime.now()), style: context.text.labelSmall?.copyWith(color: context.dca.inkSecondary)),
            ],
          ),
        ),
        DcaRewardChip(icon: Icons.local_fire_department, label: '$streak'),
        const SizedBox(width: 6),
        DcaRewardChip(icon: Icons.monetization_on, label: '$coins'),
        IconButton(
          tooltip: 'Search',
          onPressed: () => context.go('/news'),
          icon: const Icon(Icons.search),
        ),
      ],
    );
  }
}

class _BreakingBanner extends ConsumerWidget {
  const _BreakingBanner({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider.select((s) => s.lang));
    return Material(
      color: context.dca.errorContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/article/${article.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: context.dca.error, borderRadius: BorderRadius.circular(999)),
                child: Text('LIVE', style: context.text.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(article.headline.of(lang), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall?.copyWith(fontSize: 13))),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveRow extends StatelessWidget {
  const _LiveRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: context.colors.outline)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: context.dca.error, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text('Live from newspapers', style: context.text.titleSmall)),
              Text('6 papers', style: context.text.labelSmall?.copyWith(color: context.dca.inkSecondary)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid({required this.lang});

  final Lang lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const cats = [
      NewsCategory.national,
      NewsCategory.international,
      NewsCategory.economy,
      NewsCategory.scitech,
      NewsCategory.environment,
      NewsCategory.schemes,
      NewsCategory.defence,
      NewsCategory.days,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DcaSectionHeader(lang == Lang.hi ? 'श्रेणियां' : 'Top categories'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            for (final c in cats)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ref.read(categoryFilterProvider.notifier).select(c);
                  context.go('/news');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(radius: 26, backgroundColor: c.tint, child: Icon(c.icon, color: c.color)),
                    const SizedBox(height: 6),
                    Text(c.label.of(lang), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelSmall),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Kept here so the Today card can start a quiz without importing screens.
void startDailyQuiz(BuildContext context, WidgetRef ref, List<Article> articles) {
  ref.read(quizProvider.notifier).start(title: 'Daily Quiz', items: buildQuizItems(articles, count: 10));
  context.push('/quiz');
}

/// Exposed for the Today card's third step.
int dueCardCount(WidgetRef ref) => ref.watch(deckProvider).value?.length ?? 0;
