import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/models/bilingual.dart';
import '../../../../common/providers/settings_provider.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/dca_widgets.dart';
import '../../../profile/data/providers/progress_provider.dart';
import '../../data/models/article.dart';
import '../../data/providers/news_providers.dart';
import '../widgets/dca_news_tile.dart';

/// Article detail: summary, detail, why it matters, practice.
class ArticleScreen extends ConsumerStatefulWidget {
  const ArticleScreen({super.key, required this.id});

  static const routePath = '/article/:id';

  final String id;

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  @override
  void initState() {
    super.initState();
    // Opening an article counts toward today's brief and the streak.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(progressProvider.notifier).markRead(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final article = ref.watch(articleByIdProvider(widget.id));
    final lang = ref.watch(settingsProvider.select((s) => s.lang));
    final saved = ref.watch(progressProvider.select((p) => p.bookmarks.contains(widget.id)));

    if (article == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const DcaEmptyState(icon: Icons.article_outlined, title: 'This story is not available'),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            const DcaLangToggle(),
            IconButton(
              tooltip: saved ? 'Remove bookmark' : 'Bookmark',
              onPressed: () => ref.read(progressProvider.notifier).toggleBookmark(article.id),
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(color: article.category.tint, borderRadius: BorderRadius.circular(20)),
                      child: Icon(article.category.icon, size: 64, color: article.category.color),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        DcaCategoryChip(article.category),
                        const SizedBox(width: 8),
                        Text(
                          '${MaterialLocalizations.of(context).formatShortDate(article.publishDate)} · ${article.readMinutes} min',
                          style: context.text.labelSmall?.copyWith(color: context.dca.inkSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(article.headline.of(lang), style: context.text.headlineMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in article.examTags) DcaTag(examLabel(t)),
                        DcaTag('${article.relevance == 'mains' ? 'Mains' : article.relevance == 'both' ? 'Prelims + Mains' : 'Prelims'}', reward: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(pinned: true, delegate: _TabsHeader(lang: lang, background: context.colors.surface)),
          ],
          body: TabBarView(
            children: [
              _SummaryTab(article: article, lang: lang),
              _DetailTab(article: article, lang: lang),
              _WhyTab(article: article, lang: lang),
              _PracticeTab(article: article, lang: lang),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader({required this.lang, required this.background});

  final Lang lang;
  final Color background;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: background,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: lang == Lang.hi ? 'सारांश' : 'Summary'),
          Tab(text: lang == Lang.hi ? 'विस्तार' : 'Detailed'),
          Tab(text: lang == Lang.hi ? 'क्यों ज़रूरी' : 'Why it matters'),
          Tab(text: lang == Lang.hi ? 'अभ्यास' : 'Practice'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsHeader old) => old.lang != lang || old.background != background;
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.article, required this.lang});

  final Article article;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(article.summary.of(lang), style: context.text.bodyLarge),
        const SizedBox(height: 20),
        Text(lang == Lang.hi ? 'मुख्य बिंदु' : 'Key points', style: context.text.titleLarge),
        const SizedBox(height: 10),
        for (final p in article.keyPoints.of(lang))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(p, style: context.text.bodyLarge)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _SourceCard(source: article.source),
      ],
    );
  }
}

class _DetailTab extends StatelessWidget {
  const _DetailTab({required this.article, required this.lang});

  final Article article;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(article.body.of(lang), style: context.text.bodyLarge),
        if (article.facts.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: context.colors.primaryContainer, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang == Lang.hi ? 'याद रखने योग्य तथ्य' : 'FACTS TO REMEMBER',
                    style: context.text.labelMedium?.copyWith(color: context.colors.onPrimaryContainer, letterSpacing: 0.6)),
                const SizedBox(height: 8),
                for (final f in article.facts)
                  Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(f.of(lang), style: context.text.bodyMedium)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _SourceCard(source: article.source),
      ],
    );
  }
}

class _WhyTab extends StatelessWidget {
  const _WhyTab({required this.article, required this.lang});

  final Article article;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0B1736), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.track_changes, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Text(lang == Lang.hi ? 'परीक्षा के लिए क्यों ज़रूरी' : 'Why it matters for exams',
                      style: context.text.titleLarge?.copyWith(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _InfoBox(label: 'Syllabus', value: article.syllabus)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoBox(
                      label: 'Relevance',
                      value: article.relevance == 'both' ? 'Prelims + Mains' : article.relevance == 'mains' ? 'Mains' : 'Prelims',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(article.whyImportant.of(lang), style: context.text.bodyMedium?.copyWith(color: const Color(0xFFDCE3F5))),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.labelSmall?.copyWith(color: const Color(0xFFB9C4E0))),
          Text(value, style: context.text.titleSmall?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class _PracticeTab extends ConsumerStatefulWidget {
  const _PracticeTab({required this.article, required this.lang});

  final Article article;
  final Lang lang;

  @override
  ConsumerState<_PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends ConsumerState<_PracticeTab> {
  final Map<int, int> _choice = {};

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final mcqs = widget.article.mcqs;
    if (mcqs.isEmpty) {
      return const DcaEmptyState(icon: Icons.quiz_outlined, title: 'No practice questions for this story yet');
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final (qi, q) in mcqs.indexed) ...[
          Text('${qi + 1}. ${q.question.of(lang)}', style: context.text.titleMedium),
          const SizedBox(height: 12),
          for (final (oi, opt) in q.options.of(lang).indexed) ...[
            DcaMcqOption(
              letter: 'ABCD'[oi],
              text: opt,
              state: _stateFor(q, qi, oi),
              onTap: _choice.containsKey(qi) ? null : () => setState(() => _choice[qi] = oi),
            ),
            const SizedBox(height: 10),
          ],
          if (_choice.containsKey(qi))
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.colors.outline),
              ),
              child: Text(q.explanation.of(lang), style: context.text.bodyMedium),
            ),
          const SizedBox(height: 24),
        ],
        OutlinedButton(onPressed: () => context.pop(), child: Text(lang == Lang.hi ? 'अगली ख़बर' : 'Back to stories')),
      ],
    );
  }

  OptionState _stateFor(Mcq q, int qi, int oi) {
    final c = _choice[qi];
    if (c == null) return OptionState.idle;
    if (oi == q.answerIndex) return OptionState.correct;
    if (oi == c) return OptionState.wrong;
    return OptionState.dimmed;
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});

  final SourceCredit source;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(source.url);
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: context.colors.outline)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: uri == null ? null : () => launchUrl(uri, mode: LaunchMode.externalApplication),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: context.colors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  source.name.length > 4 ? source.name.substring(0, 3) : source.name,
                  style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: context.colors.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source.attribution.isEmpty ? source.name : source.attribution, style: context.text.titleSmall?.copyWith(fontSize: 13)),
                    Text('Summarised by Daily CA editors · read the original',
                        style: context.text.labelSmall?.copyWith(color: context.dca.inkSecondary)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 18, color: context.dca.inkSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
