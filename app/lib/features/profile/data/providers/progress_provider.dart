import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/providers/core_providers.dart';
import '../models/progress.dart';

/// Day key in Indian Standard Time, so streaks roll over at IST midnight
/// wherever the phone's clock is set.
String istDayKey(DateTime t) {
  final ist = t.toUtc().add(const Duration(hours: 5, minutes: 30));
  final m = ist.month.toString().padLeft(2, '0');
  final d = ist.day.toString().padLeft(2, '0');
  return '${ist.year}-$m-$d';
}

/// Streak after activity today: same day keeps it, next day extends it,
/// any gap resets it to 1.
int nextStreak({required String? lastDay, required String today, required int current}) {
  if (lastDay == today) return current == 0 ? 1 : current;
  if (lastDay == null) return 1;
  final last = DateTime.parse(lastDay);
  final now = DateTime.parse(today);
  return now.difference(last).inDays == 1 ? current + 1 : 1;
}

/// Coins earned for one quiz.
int coinsForQuiz({required int correct, required int total}) {
  var coins = CoinRules.dailyQuiz + correct * CoinRules.perCorrect;
  if (total > 0 && correct == total) coins += CoinRules.perfectBonus;
  return coins;
}

/// Local progress: coins, XP, streak, bookmarks, mistakes, quiz history.
/// Kept on device in v1; the backend's /quizzes/submit takes over once live.
class ProgressNotifier extends Notifier<Progress> {
  static const _key = 'progress.v1';

  @override
  Progress build() {
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return const Progress();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      Set<String> set(String k) => ((j[k] as List?) ?? const []).map((e) => e.toString()).toSet();
      return Progress(
        coins: (j['coins'] as num?)?.toInt() ?? 0,
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        streak: (j['streak'] as num?)?.toInt() ?? 0,
        bestStreak: (j['bestStreak'] as num?)?.toInt() ?? 0,
        lastActiveDay: j['lastActiveDay'] as String?,
        bookmarks: set('bookmarks'),
        readArticles: set('readArticles'),
        mistakes: set('mistakes'),
        badges: set('badges'),
        attempts: ((j['attempts'] as List?) ?? const [])
            .map((e) => QuizAttempt.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (_) {
      return const Progress();
    }
  }

  void _save(Progress p) {
    state = p;
    ref.read(sharedPrefsProvider).setString(
          _key,
          jsonEncode({
            'coins': p.coins,
            'xp': p.xp,
            'streak': p.streak,
            'bestStreak': p.bestStreak,
            'lastActiveDay': p.lastActiveDay,
            'bookmarks': p.bookmarks.toList(),
            'readArticles': p.readArticles.toList(),
            'mistakes': p.mistakes.toList(),
            'badges': p.badges.toList(),
            'attempts': p.attempts.take(200).map((a) => a.toJson()).toList(),
          }),
        );
  }

  /// Records activity for today and pays streak milestones once.
  Progress _touch(Progress p, {int earn = 0}) {
    final today = istDayKey(ref.read(clockProvider)());
    final streak = nextStreak(lastDay: p.lastActiveDay, today: today, current: p.streak);
    var bonus = 0;
    final badges = {...p.badges};
    if (streak != p.streak) {
      if (streak == 7 && badges.add('week-warrior')) bonus += CoinRules.streak7;
      if (streak == 30 && badges.add('monthly-master')) bonus += CoinRules.streak30;
    }
    final total = earn + bonus;
    return p.copyWith(
      coins: p.coins + total,
      xp: p.xp + total,
      streak: streak,
      bestStreak: streak > p.bestStreak ? streak : p.bestStreak,
      lastActiveDay: today,
      badges: badges,
    );
  }

  void toggleBookmark(String articleId) {
    final b = {...state.bookmarks};
    if (!b.remove(articleId)) b.add(articleId);
    _save(state.copyWith(bookmarks: b));
  }

  void markRead(String articleId) {
    if (state.readArticles.contains(articleId)) return;
    final read = {...state.readArticles, articleId};
    _save(_touch(state.copyWith(readArticles: read)));
  }

  void completeBrief() => _save(_touch(state, earn: CoinRules.briefRead));

  /// Returns coins earned so the result screen can show them.
  int recordQuiz({required QuizAttempt attempt, required Set<String> wrongIds, required Set<String> rightIds}) {
    final earned = coinsForQuiz(correct: attempt.score, total: attempt.total);
    final mistakes = {...state.mistakes, ...wrongIds}..removeAll(rightIds);
    final badges = {...state.badges, 'first-step'};
    if (attempt.total > 0 && attempt.score == attempt.total) badges.add('perfect-score');
    final before = state.coins;
    _save(_touch(
      state.copyWith(attempts: [attempt, ...state.attempts], mistakes: mistakes, badges: badges),
      earn: earned,
    ));
    return state.coins - before;
  }

  void resolveMistake(String mcqId) {
    final m = {...state.mistakes}..remove(mcqId);
    _save(state.copyWith(mistakes: m));
  }

  void completeFlashcards() => _save(_touch(state, earn: CoinRules.flashcardsDone));
}

final progressProvider = NotifierProvider<ProgressNotifier, Progress>(ProgressNotifier.new);
