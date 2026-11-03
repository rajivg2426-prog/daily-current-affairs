import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/providers/settings_provider.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../profile/data/providers/progress_provider.dart';
import '../../data/models/article.dart';

String examLabel(String id) => switch (id) {
      'upsc' => 'UPSC',
      'ssc' => 'SSC',
      'banking' => 'Banking',
      'railway' => 'Railway',
      'defence' => 'Defence',
      'statepsc' => 'State PSC',
      _ => id,
    };

/// Compact list row: thumbnail, headline, category, bookmark.
class DcaNewsTile extends ConsumerWidget {
  const DcaNewsTile(this.article, {super.key, this.showDivider = true});

  final Article article;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider.select((s) => s.lang));
    final saved = ref.watch(progressProvider.select((p) => p.bookmarks.contains(article.id)));
    final read = ref.watch(progressProvider.select((p) => p.readArticles.contains(article.id)));
    return InkWell(
      onTap: () => context.push('/article/${article.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: showDivider ? Border(bottom: BorderSide(color: context.colors.outline)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: article.category.tint, borderRadius: BorderRadius.circular(12)),
              child: Icon(article.category.icon, color: article.category.color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.headline.of(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(
                      fontSize: 14,
                      color: read ? context.dca.inkSecondary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${article.category.label.of(lang)} · ${article.examTags.take(2).map(examLabel).join(' · ')}',
                    style: context.text.labelSmall?.copyWith(color: context.dca.inkSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: saved ? 'Remove bookmark' : 'Bookmark',
              onPressed: () => ref.read(progressProvider.notifier).toggleBookmark(article.id),
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: saved ? context.colors.primary : context.dca.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large card for the horizontal headlines carousel.
class DcaHeadlineCard extends ConsumerWidget {
  const DcaHeadlineCard(this.article, {super.key});

  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider.select((s) => s.lang));
    return SizedBox(
      width: 260,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/article/${article.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(color: article.category.tint, borderRadius: BorderRadius.circular(16)),
              child: Stack(
                children: [
                  Center(child: Icon(article.category.icon, size: 56, color: article.category.color)),
                  PositionedDirectional(
                    start: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        article.category.label.of(lang),
                        style: context.text.labelSmall?.copyWith(color: article.category.color, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(article.headline.of(lang), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
            const SizedBox(height: 4),
            Text(
              '${article.source.name} · ${article.readMinutes} min · ${article.examTags.take(2).map(examLabel).join(' · ')}',
              style: context.text.labelSmall?.copyWith(color: context.dca.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
