import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/providers/core_providers.dart';
import '../../../news/data/models/article.dart';
import '../../../profile/data/models/progress.dart';
import '../../../profile/data/providers/progress_provider.dart';
import '../models/quiz_session.dart';

/// Builds a quiz from the newest articles' questions.
List<QuizItem> buildQuizItems(List<Article> articles, {int count = 10, Set<String>? onlyIds}) {
  final items = <QuizItem>[];
  for (final a in articles) {
    for (final q in a.mcqs) {
      if (onlyIds != null && !onlyIds.contains(q.id)) continue;
      items.add(QuizItem(mcq: q, category: a.category, articleId: a.id));
    }
  }
  return items.take(count).toList();
}

/// The quiz in progress (null when none).
class QuizNotifier extends Notifier<QuizSession?> {
  @override
  QuizSession? build() => null;

  DateTime _now() => ref.read(clockProvider)();

  void start({required String title, required List<QuizItem> items}) {
    state = items.isEmpty ? null : QuizSession(title: title, items: items, startedAt: _now());
  }

  /// Instant mode: one answer per question, no changing it afterwards.
  void answer(int option) {
    final s = state;
    if (s == null || s.answeredCurrent || s.isFinished) return;
    state = s.copyWith(answers: {...s.answers, s.index: option});
  }

  void next() {
    final s = state;
    if (s == null || s.isLast) return;
    state = s.copyWith(index: s.index + 1);
  }

  /// Finishes, records progress, returns coins earned.
  int finish() {
    final s = state;
    if (s == null || s.isFinished) return 0;
    final done = s.copyWith(finishedAt: _now());
    state = done;
    return ref.read(progressProvider.notifier).recordQuiz(
          attempt: QuizAttempt(
            date: done.finishedAt!,
            score: done.score,
            total: done.items.length,
            seconds: done.seconds,
            byCategory: done.byCategory,
          ),
          wrongIds: done.wrongIds,
          rightIds: done.rightIds,
        );
  }

  void clear() => state = null;
}

final quizProvider = NotifierProvider<QuizNotifier, QuizSession?>(QuizNotifier.new);

/// Coins from the last finished quiz, for the result screen.
class LastCoins extends Notifier<int> {
  @override
  int build() => 0;

  void setCoins(int v) => state = v;
}

final lastQuizCoinsProvider = NotifierProvider<LastCoins, int>(LastCoins.new);
