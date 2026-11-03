import 'package:flutter/foundation.dart';

/// Levels by lifetime XP (XP = coins ever earned). Matches the spec.
const List<(int, String)> kLevels = [
  (0, 'Beginner'),
  (300, 'Reader'),
  (900, 'Learner'),
  (2000, 'Achiever'),
  (4000, 'Scholar'),
  (8000, 'Expert'),
  (15000, 'Topper'),
  (30000, 'Legend'),
];

/// Coin rules from the spec.
abstract final class CoinRules {
  static const briefRead = 10;
  static const dailyQuiz = 20;
  static const perCorrect = 2;
  static const perfectBonus = 25;
  static const flashcardsDone = 15;
  static const streak7 = 50;
  static const streak30 = 300;
}

@immutable
class QuizAttempt {
  const QuizAttempt({required this.date, required this.score, required this.total, required this.seconds, required this.byCategory});

  final DateTime date;
  final int score;
  final int total;
  final int seconds;
  final Map<String, (int correct, int total)> byCategory;

  Map<String, Object> toJson() => {
        'date': date.toIso8601String(),
        'score': score,
        'total': total,
        'seconds': seconds,
        'byCategory': {for (final e in byCategory.entries) e.key: [e.value.$1, e.value.$2]},
      };

  factory QuizAttempt.fromJson(Map<String, dynamic> j) {
    final cats = <String, (int, int)>{};
    final raw = (j['byCategory'] as Map?) ?? const {};
    for (final e in raw.entries) {
      final v = e.value as List;
      cats[e.key.toString()] = ((v[0] as num).toInt(), (v[1] as num).toInt());
    }
    return QuizAttempt(
      date: DateTime.parse(j['date'] as String),
      score: (j['score'] as num).toInt(),
      total: (j['total'] as num).toInt(),
      seconds: (j['seconds'] as num?)?.toInt() ?? 0,
      byCategory: cats,
    );
  }
}

@immutable
class Progress {
  const Progress({
    this.coins = 0,
    this.xp = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.lastActiveDay,
    this.bookmarks = const <String>{},
    this.readArticles = const <String>{},
    this.mistakes = const <String>{},
    this.attempts = const <QuizAttempt>[],
    this.badges = const <String>{},
  });

  final int coins;
  final int xp;
  final int streak;
  final int bestStreak;
  final String? lastActiveDay; // yyyy-MM-dd in IST
  final Set<String> bookmarks;
  final Set<String> readArticles;
  final Set<String> mistakes; // mcq ids answered wrong
  final List<QuizAttempt> attempts;
  final Set<String> badges;

  String get levelName {
    var name = kLevels.first.$2;
    for (final (min, n) in kLevels) {
      if (xp >= min) name = n;
    }
    return name;
  }

  int get levelNumber => kLevels.lastIndexWhere((l) => xp >= l.$1) + 1;

  /// 0..1 progress to the next level.
  double get levelProgress {
    final i = kLevels.lastIndexWhere((l) => xp >= l.$1);
    if (i >= kLevels.length - 1) return 1;
    final lo = kLevels[i].$1;
    final hi = kLevels[i + 1].$1;
    return (xp - lo) / (hi - lo);
  }

  int get nextLevelXp {
    final i = kLevels.lastIndexWhere((l) => xp >= l.$1);
    return i >= kLevels.length - 1 ? xp : kLevels[i + 1].$1;
  }

  double get accuracy {
    final total = attempts.fold<int>(0, (s, a) => s + a.total);
    if (total == 0) return 0;
    return attempts.fold<int>(0, (s, a) => s + a.score) / total;
  }

  /// Accuracy per category across all attempts.
  Map<String, double> get categoryAccuracy {
    final sums = <String, (int, int)>{};
    for (final a in attempts) {
      for (final e in a.byCategory.entries) {
        final cur = sums[e.key] ?? (0, 0);
        sums[e.key] = (cur.$1 + e.value.$1, cur.$2 + e.value.$2);
      }
    }
    return {for (final e in sums.entries) if (e.value.$2 > 0) e.key: e.value.$1 / e.value.$2};
  }

  Progress copyWith({
    int? coins,
    int? xp,
    int? streak,
    int? bestStreak,
    String? lastActiveDay,
    Set<String>? bookmarks,
    Set<String>? readArticles,
    Set<String>? mistakes,
    List<QuizAttempt>? attempts,
    Set<String>? badges,
  }) =>
      Progress(
        coins: coins ?? this.coins,
        xp: xp ?? this.xp,
        streak: streak ?? this.streak,
        bestStreak: bestStreak ?? this.bestStreak,
        lastActiveDay: lastActiveDay ?? this.lastActiveDay,
        bookmarks: bookmarks ?? this.bookmarks,
        readArticles: readArticles ?? this.readArticles,
        mistakes: mistakes ?? this.mistakes,
        attempts: attempts ?? this.attempts,
        badges: badges ?? this.badges,
      );
}
