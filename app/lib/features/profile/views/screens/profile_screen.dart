import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/models/bilingual.dart';
import '../../../../common/providers/settings_provider.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../../common/utils/category.dart';
import '../../../../common/widgets/dca_widgets.dart';
import '../../data/providers/progress_provider.dart';

const _badgeInfo = <String, (String, IconData)>{
  'first-step': ('First Step', Icons.flag),
  'perfect-score': ('Sharpshooter', Icons.track_changes),
  'week-warrior': ('Week Warrior', Icons.local_fire_department),
  'monthly-master': ('Monthly Master', Icons.workspace_premium),
};

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const routePath = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final settings = ref.watch(settingsProvider);
    final lang = settings.lang;
    final cat = p.categoryAccuracy.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final name = settings.name.isEmpty ? 'Guest learner' : settings.name;

    return Scaffold(
      appBar: AppBar(title: Text(lang == Lang.hi ? 'प्रोफ़ाइल' : 'Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: context.colors.primaryContainer,
                child: Text(name.characters.first.toUpperCase(), style: context.text.headlineSmall?.copyWith(color: context.colors.onPrimaryContainer)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: context.text.headlineSmall),
                    Text('Level ${p.levelNumber} · ${p.levelName}', style: context.text.bodyMedium?.copyWith(color: context.dca.inkSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(value: p.levelProgress, minHeight: 6, color: context.dca.reward, backgroundColor: context.dca.surfaceHigh),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${p.xp} / ${p.nextLevelXp} XP', style: context.text.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              DcaStatTile(label: 'Streak', value: '${p.streak} days', caption: 'Best: ${p.bestStreak}', reward: true),
              DcaStatTile(label: 'Coins', value: '${p.coins}', caption: 'Lifetime XP ${p.xp}', reward: true),
              DcaStatTile(label: 'Quizzes', value: '${p.attempts.length}', caption: '${p.readArticles.length} stories read'),
              DcaStatTile(label: 'Accuracy', value: '${(p.accuracy * 100).round()}%', caption: 'All quizzes'),
            ],
          ),
          const SizedBox(height: 22),
          Text(lang == Lang.hi ? 'श्रेणी के अनुसार सटीकता' : 'Accuracy by category', style: context.text.titleLarge),
          const SizedBox(height: 10),
          if (cat.isEmpty)
            Text('Take a quiz to see where you are strong and weak.', style: context.text.bodyMedium?.copyWith(color: context.dca.inkSecondary)),
          for (final e in cat) ...[
            Row(
              children: [
                SizedBox(width: 110, child: Text(NewsCategory.fromId(e.key).label.of(lang), style: context.text.titleSmall?.copyWith(fontSize: 13))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: e.value,
                      minHeight: 8,
                      backgroundColor: context.dca.surfaceHigh,
                      color: e.value < 0.55 ? context.dca.error : context.colors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 44, child: Text('${(e.value * 100).round()}%', textAlign: TextAlign.end, style: context.text.labelMedium)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          Text('Badges', style: context.text.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              for (final entry in _badgeInfo.entries)
                SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: p.badges.contains(entry.key) ? context.dca.rewardContainer : context.dca.surfaceHigh,
                        child: Icon(
                          p.badges.contains(entry.key) ? entry.value.$2 : Icons.lock_outline,
                          color: p.badges.contains(entry.key) ? context.dca.reward : context.dca.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(entry.value.$1, textAlign: TextAlign.center, style: context.text.labelSmall),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Exam preference'),
            subtitle: Text(settings.exams.isEmpty ? 'All exams' : settings.exams.map((e) => Exam.fromId(e)?.label ?? e).join(', ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/onboarding'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Content language'),
            trailing: const DcaLangToggle(),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox.shrink(),
              onChanged: (m) {
                if (m != null) ref.read(settingsProvider.notifier).setThemeMode(m);
              },
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Live from newspapers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/live'),
          ),
        ],
      ),
    );
  }
}
