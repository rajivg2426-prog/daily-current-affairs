import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/models/bilingual.dart';
import '../../../news/data/models/article.dart';
import '../../../news/data/providers/news_providers.dart';
import '../../../profile/data/providers/progress_provider.dart';

@immutable
class Flashcard {
  const Flashcard({required this.id, required this.front, required this.back, required this.articleId, this.fromMistake = false});

  final String id;
  final Bi front;
  final Bi back;
  final String articleId;
  final bool fromMistake;
}

/// Cards due today: mistakes first (they matter most), then key facts.
List<Flashcard> buildDeck(List<Article> articles, Set<String> mistakes) {
  final fromMistakes = <Flashcard>[];
  final fromFacts = <Flashcard>[];
  for (final a in articles) {
    for (final q in a.mcqs) {
      if (!mistakes.contains(q.id)) continue;
      fromMistakes.add(Flashcard(
        id: q.id,
        front: q.question,
        back: Bi(
          '${q.options.en[q.answerIndex]}\n\n${q.explanation.en}',
          '${q.options.of(Lang.hi)[q.answerIndex]}\n\n${q.explanation.of(Lang.hi)}',
        ),
        articleId: a.id,
        fromMistake: true,
      ));
    }
    for (var i = 0; i < a.facts.length; i++) {
      fromFacts.add(Flashcard(id: '${a.id}-f$i', front: a.headline, back: a.facts[i], articleId: a.id));
    }
  }
  return [...fromMistakes, ...fromFacts].take(12).toList();
}

final deckProvider = Provider<AsyncValue<List<Flashcard>>>((ref) {
  final mistakes = ref.watch(progressProvider.select((p) => p.mistakes));
  return ref.watch(articlesProvider).whenData((list) => buildDeck(list, mistakes));
});
