import 'package:daily_current_affairs/features/news/data/repositories/sample_data.dart';
import 'package:daily_current_affairs/features/quiz/data/models/quiz_session.dart';
import 'package:daily_current_affairs/features/quiz/data/providers/quiz_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final articles = sampleArticles(DateTime(2026, 11, 3, 12));

  test('sample questions all have four options and a valid answer', () {
    for (final a in articles) {
      for (final q in a.mcqs) {
        expect(q.options.en.length, 4, reason: q.id);
        expect(q.options.hi.length, 4, reason: q.id);
        expect(q.answerIndex, inInclusiveRange(0, 3), reason: q.id);
        expect(q.options.en.toSet().length, 4, reason: '${q.id} has duplicate options');
      }
    }
  });

  test('daily quiz takes up to 10 questions', () {
    final items = buildQuizItems(articles, count: 10);
    expect(items.length, lessThanOrEqualTo(10));
    expect(items, isNotEmpty);
  });

  test('session scores, splits by category and lists mistakes', () {
    final items = buildQuizItems(articles, count: 3);
    final answers = {
      0: items[0].mcq.answerIndex,
      1: (items[1].mcq.answerIndex + 1) % 4,
      2: items[2].mcq.answerIndex,
    };
    final s = QuizSession(title: 't', items: items, startedAt: DateTime(2026), answers: answers);
    expect(s.score, 2);
    expect(s.wrongIds, {items[1].mcq.id});
    expect(s.byCategory.values.fold<int>(0, (n, v) => n + v.$2), 3);
  });
}
