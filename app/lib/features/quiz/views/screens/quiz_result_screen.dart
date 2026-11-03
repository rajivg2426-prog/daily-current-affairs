import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/models/bilingual.dart';
import '../../../../common/providers/settings_provider.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../../common/utils/category.dart';
import '../../../../common/widgets/dca_widgets.dart';
import '../../../profile/data/providers/progress_provider.dart';
import '../../data/providers/quiz_provider.dart';

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key});

  static const routePath = '/quiz/result';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(quizProvider);
    final coins = ref.watch(lastQuizCoinsProvider);
    final streak = ref.watch(progressProvider.select((p) => p.streak));
    final lang = ref.watch(settingsProvider.select((x) => x.lang));
    if (s == null || !s.isFinished) {
      return Scaffold(appBar: AppBar(), body: const DcaEmptyState(icon: Icons.quiz_outlined, title: 'No result to show'));
    }
    final total = s.items.length;
    final pct = total == 0 ? 0 : (s.score * 100 / total).round();
    final mm = s.seconds ~/ 60;
    final ss = (s.seconds % 60).toString().padLeft(2, '0');
    final headline = pct >= 80
        ? (lang == Lang.hi ? 'शानदार!' : 'Great work!')
        : pct >= 50
            ? (lang == Lang.hi ? 'अच्छा प्रयास' : 'Good effort')
            : (lang == Lang.hi ? 'दोहराने का समय' : 'Time to revise');

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 20, 28),
            decoration: BoxDecoration(
              color: context.colors.brightness == Brightness.dark ? context.colors.primaryContainer : context.colors.primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      ref.read(quizProvider.notifier).clear();
                      context.go('/home');
                    },
                  ),
                ),
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _RingPainter(total == 0 ? 0 : s.score / total),
                    child: Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${s.score}', style: context.text.displaySmall?.copyWith(color: Colors.white, fontSize: 44)),
                            TextSpan(text: '/$total', style: context.text.titleLarge?.copyWith(color: const Color(0xFFD6E0FF))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(headline, style: context.text.headlineSmall?.copyWith(color: Colors.white)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DcaRewardChip(icon: Icons.monetization_on, label: '+$coins coins'),
                    const SizedBox(width: 8),
                    DcaRewardChip(icon: Icons.local_fire_department, label: '$streak-day streak'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: DcaStatTile(label: 'Accuracy', value: '$pct%')),
                    const SizedBox(width: 10),
                    Expanded(child: DcaStatTile(label: 'Time', value: '$mm:$ss')),
                  ],
                ),
                const SizedBox(height: 20),
                Text(lang == Lang.hi ? 'श्रेणी के अनुसार' : 'By category', style: context.text.titleLarge),
                const SizedBox(height: 10),
                for (final e in s.byCategory.entries) ...[
                  Row(
                    children: [
                      Expanded(child: Text(NewsCategory.fromId(e.key).label.of(lang), style: context.text.titleSmall?.copyWith(fontSize: 13))),
                      Text('${e.value.$1} / ${e.value.$2}', style: context.text.labelMedium?.copyWith(color: context.dca.inkSecondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: e.value.$2 == 0 ? 0 : e.value.$1 / e.value.$2,
                      minHeight: 8,
                      backgroundColor: context.dca.surfaceHigh,
                      color: e.value.$1 * 2 < e.value.$2 ? context.dca.error : context.colors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                if (s.wrongIds.isNotEmpty)
                  FilledButton(
                    onPressed: () {
                      ref.read(quizProvider.notifier).clear();
                      context.go('/revise');
                    },
                    child: Text('Revise ${s.wrongIds.length} mistakes'),
                  ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    ref.read(quizProvider.notifier).clear();
                    context.go('/home');
                  },
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arc = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(r, 0, math.pi * 2, false, track);
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * fraction, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.fraction != fraction;
}
