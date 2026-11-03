import 'package:daily_current_affairs/features/profile/data/models/progress.dart';
import 'package:daily_current_affairs/features/profile/data/providers/progress_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('istDayKey', () {
    test('rolls over at IST midnight, not UTC', () {
      // 18:29 UTC = 23:59 IST, still the same day in India
      expect(istDayKey(DateTime.utc(2026, 11, 3, 18, 29)), '2026-11-03');
      // 18:31 UTC = 00:01 IST next day
      expect(istDayKey(DateTime.utc(2026, 11, 3, 18, 31)), '2026-11-04');
    });
  });

  group('nextStreak', () {
    test('starts at 1', () => expect(nextStreak(lastDay: null, today: '2026-11-03', current: 0), 1));
    test('same day keeps it', () => expect(nextStreak(lastDay: '2026-11-03', today: '2026-11-03', current: 5), 5));
    test('next day extends it', () => expect(nextStreak(lastDay: '2026-11-02', today: '2026-11-03', current: 5), 6));
    test('a gap resets it', () => expect(nextStreak(lastDay: '2026-10-31', today: '2026-11-03', current: 5), 1));
  });

  group('coins', () {
    test('quiz pays base + per correct', () => expect(coinsForQuiz(correct: 8, total: 10), 20 + 16));
    test('perfect score adds a bonus', () => expect(coinsForQuiz(correct: 10, total: 10), 20 + 20 + 25));
  });

  group('levels', () {
    test('level name follows XP thresholds', () {
      expect(const Progress(xp: 0).levelName, 'Beginner');
      expect(const Progress(xp: 950).levelName, 'Learner');
      expect(const Progress(xp: 4000).levelName, 'Scholar');
    });
    test('progress to next level is a fraction', () {
      expect(const Progress(xp: 600).levelProgress, closeTo(0.5, 0.001)); // 300..900
    });
  });
}
