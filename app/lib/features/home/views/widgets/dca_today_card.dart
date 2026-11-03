import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/models/bilingual.dart';
import '../../../../common/providers/settings_provider.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../news/data/models/article.dart';
import '../../../profile/data/providers/progress_provider.dart';
import '../screens/home_screen.dart';

/// The daily ritual: Read → Quiz → Revise, with one obvious next step.
class DcaTodayCard extends ConsumerWidget {
  const DcaTodayCard({super.key, required this.articles});

  final List<Article> articles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider.select((s) => s.lang));
    final progress = ref.watch(progressProvider);
    final today = istDayKey(DateTime.now());

    final todays = articles.take(8).toList();
    final readCount = todays.where((a) => progress.readArticles.contains(a.id)).length;
    final readDone = todays.isNotEmpty && readCount >= (todays.length / 2).ceil();
    final quizDone = progress.attempts.any((a) => istDayKey(a.date) == today);
    final dueCards = dueCardCount(ref);

    final String cta;
    final VoidCallback action;
    if (!readDone) {
      cta = lang == Lang.hi ? 'आज की ब्रीफ़ पढ़ें · $readCount/${todays.length}' : "Read today's brief · $readCount/${todays.length}";
      action = () {
        final next = todays.firstWhere((a) => !progress.readArticles.contains(a.id), orElse: () => todays.first);
        context.push('/article/${next.id}');
      };
    } else if (!quizDone) {
      cta = lang == Lang.hi ? 'आज की क्विज़ दें · 10 प्रश्न' : "Take today's quiz · 10 Qs";
      action = () => startDailyQuiz(context, ref, articles);
    } else {
      cta = lang == Lang.hi ? '$dueCards फ्लैशकार्ड दोहराएं' : 'Revise $dueCards flashcards';
      action = () => context.go('/revise');
    }

    Widget step(String label, bool done, bool current) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: done ? Colors.white : Colors.white.withValues(alpha: current ? 0.55 : 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (done) const Icon(Icons.check, size: 14, color: Colors.white),
                  if (done) const SizedBox(width: 4),
                  Text(label, style: context.text.labelMedium?.copyWith(color: Colors.white)),
                ],
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.brightness == Brightness.dark ? context.colors.primaryContainer : context.colors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (lang == Lang.hi ? 'डेली ब्रीफ़' : 'DAILY BRIEF'),
            style: context.text.labelMedium?.copyWith(color: const Color(0xFFD6E0FF), letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            lang == Lang.hi ? 'आज की ${todays.length} ज़रूरी ख़बरें' : "Today's ${todays.length} must-know stories",
            style: context.text.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              step(lang == Lang.hi ? 'पढ़ें' : 'Read', readDone, !readDone),
              const SizedBox(width: 8),
              step(lang == Lang.hi ? 'क्विज़' : 'Quiz', quizDone, readDone && !quizDone),
              const SizedBox(width: 8),
              step(lang == Lang.hi ? 'दोहराएं' : 'Revise', false, readDone && quizDone),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF2350E6)),
              onPressed: todays.isEmpty ? null : action,
              child: Text(cta),
            ),
          ),
        ],
      ),
    );
  }
}
