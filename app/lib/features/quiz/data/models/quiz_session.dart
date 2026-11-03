import 'package:flutter/foundation.dart';

import '../../../../common/utils/category.dart';
import '../../../news/data/models/article.dart';

@immutable
class QuizItem {
  const QuizItem({required this.mcq, required this.category, required this.articleId});

  final Mcq mcq;
  final NewsCategory category;
  final String articleId;
}

@immutable
class QuizSession {
  const QuizSession({
    required this.title,
    required this.items,
    required this.startedAt,
    this.index = 0,
    this.answers = const <int, int>{},
    this.finishedAt,
  });

  final String title;
  final List<QuizItem> items;
  final DateTime startedAt;
  final int index;
  final Map<int, int> answers; // question index -> chosen option
  final DateTime? finishedAt;

  QuizItem get current => items[index];
  bool get isLast => index >= items.length - 1;
  bool get isFinished => finishedAt != null;
  int? get chosen => answers[index];
  bool get answeredCurrent => answers.containsKey(index);

  int get score {
    var s = 0;
    for (final e in answers.entries) {
      if (items[e.key].mcq.answerIndex == e.value) s++;
    }
    return s;
  }

  int get seconds => (finishedAt ?? DateTime.now()).difference(startedAt).inSeconds;

  Map<String, (int, int)> get byCategory {
    final out = <String, (int, int)>{};
    for (var i = 0; i < items.length; i++) {
      final id = items[i].category.id;
      final cur = out[id] ?? (0, 0);
      final right = answers[i] == items[i].mcq.answerIndex ? 1 : 0;
      out[id] = (cur.$1 + right, cur.$2 + 1);
    }
    return out;
  }

  Set<String> get wrongIds => {
        for (var i = 0; i < items.length; i++)
          if (answers[i] != items[i].mcq.answerIndex) items[i].mcq.id,
      };

  Set<String> get rightIds => {
        for (var i = 0; i < items.length; i++)
          if (answers[i] == items[i].mcq.answerIndex) items[i].mcq.id,
      };

  QuizSession copyWith({int? index, Map<int, int>? answers, DateTime? finishedAt}) => QuizSession(
        title: title,
        items: items,
        startedAt: startedAt,
        index: index ?? this.index,
        answers: answers ?? this.answers,
        finishedAt: finishedAt ?? this.finishedAt,
      );
}
