import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/models/bilingual.dart';
import '../../../../common/providers/settings_provider.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../../common/utils/category.dart';

/// Welcome → language → exams. Guest mode only in v1; Google and phone
/// sign-in arrive with Firebase Auth (see README).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const routePath = '/onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(settingsProvider.notifier).completeOnboarding(name: _name.text.trim());
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_step) {
            0 => _Welcome(key: const ValueKey(0), name: _name, onNext: () => setState(() => _step = 1)),
            _ => _ExamPicker(key: const ValueKey(1), onBack: () => setState(() => _step = 0), onDone: _finish),
          },
        ),
      ),
    );
  }
}

class _Welcome extends ConsumerWidget {
  const _Welcome({super.key, required this.name, required this.onNext});

  final TextEditingController name;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider.select((s) => s.lang));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(28)),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.auto_stories, color: Color(0xFF2350E6)),
                  ),
                  const SizedBox(width: 10),
                  Text('Daily CA', style: context.text.titleLarge?.copyWith(color: Colors.white)),
                ],
              ),
              const Spacer(),
              Text(
                lang == Lang.hi ? 'रोज़ 6 मिनट में करेंट अफेयर्स' : "Today's current affairs in 6 minutes",
                style: context.text.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                lang == Lang.hi ? 'पढ़ें, अभ्यास करें, दोहराएं।' : 'Read, practise, revise. Every day.',
                style: context.text.bodyLarge?.copyWith(color: const Color(0xFFD6E0FF)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Choose your language', style: context.text.titleMedium),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _LangCard(label: 'English', value: Lang.en, selected: lang == Lang.en)),
            const SizedBox(width: 12),
            Expanded(child: _LangCard(label: 'हिंदी', value: Lang.hi, selected: lang == Lang.hi)),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Your first name (optional)'),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: onNext, child: const Text('Continue as guest')),
        const SizedBox(height: 10),
        Text(
          'Google and mobile OTP sign-in will save your progress across devices. Your progress stays on this phone until then.',
          style: context.text.labelSmall?.copyWith(color: context.dca.inkSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LangCard extends ConsumerWidget {
  const _LangCard({required this.label, required this.value, required this.selected});

  final String label;
  final Lang value;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: selected ? context.colors.primaryContainer : context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? context.colors.primary : context.colors.outline, width: selected ? 2 : 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ref.read(settingsProvider.notifier).setLang(value),
        child: SizedBox(
          height: 64,
          child: Center(child: Text(label, style: context.text.titleMedium)),
        ),
      ),
    );
  }
}

class _ExamPicker extends ConsumerWidget {
  const _ExamPicker({super.key, required this.onBack, required this.onDone});

  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picked = ref.watch(settingsProvider.select((s) => s.exams));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back), tooltip: 'Back'),
              const Spacer(),
              TextButton(onPressed: onDone, child: const Text('Skip')),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text('Which exams are you preparing for?', style: context.text.headlineMedium),
              const SizedBox(height: 6),
              Text(
                "Pick up to 3. We'll tag every story and quiz for them.",
                style: context.text.bodyMedium?.copyWith(color: context.dca.inkSecondary),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  for (final exam in Exam.values)
                    _ExamCard(
                      exam: exam,
                      selected: picked.contains(exam.id),
                      onTap: () {
                        final ok = ref.read(settingsProvider.notifier).toggleExam(exam.id);
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('You can follow up to 3 exams. Remove one first.')),
                          );
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Text('${picked.length} of 3 selected', style: context.text.labelMedium?.copyWith(color: context.dca.inkSecondary)),
              const SizedBox(height: 8),
              FilledButton(onPressed: onDone, child: const Text('Start learning')),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.selected, required this.onTap});

  final Exam exam;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? context.colors.primaryContainer : context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? context.colors.primary : context.colors.outline, width: selected ? 2 : 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: exam.color, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        exam.label.substring(0, 2).toUpperCase(),
                        style: context.text.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Spacer(),
                    if (selected) Icon(Icons.check_circle, color: context.colors.primary, size: 22),
                  ],
                ),
                const Spacer(),
                Text(exam.label, style: context.text.titleSmall),
                Text(exam.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelSmall?.copyWith(color: context.dca.inkSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
