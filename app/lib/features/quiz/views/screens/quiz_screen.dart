import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/models/bilingual.dart';
import '../../../../common/providers/settings_provider.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/dca_widgets.dart';
import '../../data/models/quiz_session.dart';
import '../../data/providers/quiz_provider.dart';

/// One question per screen, instant feedback, timer, progress bar.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  static const routePath = '/quiz';

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<bool> _confirmQuit() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Quit this quiz?', style: context.text.titleLarge),
              const SizedBox(height: 6),
              Text('Your answers so far will not be saved.', style: context.text.bodyMedium),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep going')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quit')),
            ],
          ),
        ),
      ),
    );
    return ok ?? false;
  }

  void _next(QuizSession s) {
    if (s.isLast) {
      final coins = ref.read(quizProvider.notifier).finish();
      ref.read(lastQuizCoinsProvider.notifier).setCoins(coins);
      context.pushReplacement('/quiz/result');
    } else {
      ref.read(quizProvider.notifier).next();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(quizProvider);
    final lang = ref.watch(settingsProvider.select((x) => x.lang));
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const DcaEmptyState(icon: Icons.quiz_outlined, title: 'No quiz in progress'),
      );
    }
    final item = s.current;
    final chosen = s.chosen;
    final elapsed = s.seconds;
    final mm = (elapsed ~/ 60).toString();
    final ss = (elapsed % 60).toString().padLeft(2, '0');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmQuit() && context.mounted) {
          ref.read(quizProvider.notifier).clear();
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.surfaceContainerLow,
        appBar: AppBar(
          backgroundColor: context.colors.surfaceContainerLow,
          leading: IconButton(
            tooltip: 'Quit quiz',
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _confirmQuit() && context.mounted) {
                ref.read(quizProvider.notifier).clear();
                context.pop();
              }
            },
          ),
          centerTitle: true,
          title: Column(
            children: [
              Text(s.title, style: context.text.labelSmall?.copyWith(color: context.dca.inkSecondary)),
              Text('Question ${s.index + 1} of ${s.items.length}', style: context.text.titleSmall),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: DcaRewardChip(icon: Icons.timer_outlined, label: '$mm:$ss'),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    for (var i = 0; i < s.items.length; i++)
                      Expanded(
                        child: Container(
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _barColor(context, s, i),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  children: [
                    Align(alignment: AlignmentDirectional.centerStart, child: DcaCategoryChip(item.category)),
                    const SizedBox(height: 12),
                    Text(item.mcq.question.of(lang), style: context.text.titleMedium?.copyWith(fontSize: 19, height: 1.45)),
                    const SizedBox(height: 18),
                    for (final (oi, opt) in item.mcq.options.of(lang).indexed) ...[
                      DcaMcqOption(
                        letter: 'ABCD'[oi],
                        text: opt,
                        state: chosen == null
                            ? OptionState.idle
                            : oi == item.mcq.answerIndex
                                ? OptionState.correct
                                : oi == chosen
                                    ? OptionState.wrong
                                    : OptionState.dimmed,
                        onTap: chosen != null
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                ref.read(quizProvider.notifier).answer(oi);
                              },
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (chosen != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.colors.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chosen == item.mcq.answerIndex
                                  ? (lang == Lang.hi ? 'सही · +2 सिक्के' : 'Correct · +2 coins')
                                  : (lang == Lang.hi ? 'गलत · गलतियों में जोड़ा गया' : 'Not quite · added to your Mistakes deck'),
                              style: context.text.labelLarge?.copyWith(
                                color: chosen == item.mcq.answerIndex ? context.dca.success : context.dca.error,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(item.mcq.explanation.of(lang), style: context.text.bodyMedium),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(top: BorderSide(color: context.colors.outline)),
                ),
                child: FilledButton(
                  onPressed: chosen == null ? null : () => _next(s),
                  child: Text(s.isLast ? (lang == Lang.hi ? 'परिणाम देखें' : 'See result') : (lang == Lang.hi ? 'अगला प्रश्न' : 'Next question')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _barColor(BuildContext context, QuizSession s, int i) {
    final a = s.answers[i];
    if (a != null) return a == s.items[i].mcq.answerIndex ? context.dca.success : context.dca.error;
    if (i == s.index) return context.colors.primary;
    return context.colors.outline;
  }
}
