import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/models/bilingual.dart';
import '../../../../common/providers/settings_provider.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../../common/utils/category.dart';
import '../../../../common/widgets/dca_widgets.dart';
import '../../data/providers/news_providers.dart';
import '../widgets/dca_news_tile.dart';

/// All news, filterable by category and searchable by keyword.
class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  static const routePath = '/news';

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider.select((s) => s.lang));
    final selected = ref.watch(categoryFilterProvider);
    final articles = ref.watch(filteredArticlesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == Lang.hi ? 'समाचार' : 'News'),
        actions: const [Padding(padding: EdgeInsetsDirectional.only(end: 12), child: DcaLangToggle())],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: lang == Lang.hi ? 'समाचार, योजनाएं, लोग खोजें' : 'Search news, schemes, people',
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(lang == Lang.hi ? 'सभी' : 'All'),
                    selected: selected == null,
                    onSelected: (_) => ref.read(categoryFilterProvider.notifier).select(null),
                  ),
                ),
                for (final c in NewsCategory.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      avatar: Icon(c.icon, size: 16, color: c.color),
                      label: Text(c.label.of(lang)),
                      selected: selected == c,
                      onSelected: (_) => ref.read(categoryFilterProvider.notifier).select(selected == c ? null : c),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: articles.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => DcaEmptyState(icon: Icons.wifi_off, title: 'Could not load news', message: '$e'),
              data: (list) {
                final shown = _query.isEmpty
                    ? list
                    : list.where((a) {
                        final hay = '${a.headline.en} ${a.headline.hi} ${a.summary.en} ${a.summary.hi}'.toLowerCase();
                        return hay.contains(_query);
                      }).toList();
                if (shown.isEmpty) {
                  return DcaEmptyState(
                    icon: Icons.search_off,
                    title: lang == Lang.hi ? 'कुछ नहीं मिला' : 'No stories match',
                    message: lang == Lang.hi ? 'दूसरी श्रेणी या शब्द आज़माएं।' : 'Try another category or keyword.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: shown.length,
                  itemBuilder: (context, i) => DcaNewsTile(shown[i], showDivider: i < shown.length - 1),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Notes are written from official sources: PIB, RBI, PRS.',
              style: context.text.labelSmall?.copyWith(color: context.dca.inkSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
