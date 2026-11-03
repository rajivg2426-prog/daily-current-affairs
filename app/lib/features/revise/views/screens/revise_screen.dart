import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/models/bilingual.dart';
import '../../../../common/providers/settings_provider.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/dca_widgets.dart';
import '../../../news/data/providers/news_providers.dart';
import '../../../news/views/widgets/dca_news_tile.dart';
import '../../../profile/data/providers/progress_provider.dart';
import '../../data/providers/revise_provider.dart';

/// Flashcards due today, then saved articles.
class ReviseScreen extends ConsumerStatefulWidget {
  const ReviseScreen({super.key});

  static const routePath = '/revise';

  @override
  ConsumerState<ReviseScreen> createState() => _ReviseScreenState();
}

class _ReviseScreenState extends ConsumerState<ReviseScreen> {
  int _pos = 0;
  bool _flipped = false;
  int _known = 0;
  // Resolved at the end of the session, so the deck doesn't shift under the user.
  final Set<String> _fixed = {};

  void _answer(List<Flashcard> deck, {required bool knew}) {
    final card = deck[_pos];
    if (knew && card.fromMistake) _fixed.add(card.id);
    setState(() {
      if (knew) _known++;
      _flipped = false;
      _pos++;
    });
    if (_pos >= deck.length) {
      final progress = ref.read(progressProvider.notifier);
      for (final id in _fixed) {
        progress.resolveMistake(id);
      }
      _fixed.clear();
      progress.completeFlashcards();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider.select((s) => s.lang));
    final deckAsync = ref.watch(deckProvider);
    final bookmarks = ref.watch(progressProvider.select((p) => p.bookmarks));
    final articles = ref.watch(articlesProvider).value ?? const [];
    final saved = articles.where((a) => bookmarks.contains(a.id)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(lang == Lang.hi ? 'दोहराएं' : 'Revise')),
      body: deckAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DcaEmptyState(icon: Icons.error_outline, title: 'Could not build your deck', message: '$e'),
        data: (deck) {
          // The deck can shrink when a mistake is resolved; keep the position valid.
          final done = _pos >= deck.length;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (deck.isEmpty)
                const DcaEmptyState(icon: Icons.layers_outlined, title: 'No cards yet', message: 'Read a story or take a quiz to build your deck.')
              else if (done)
                _DoneCard(
                  known: _known,
                  total: _pos,
                  onRestart: () => setState(() {
                    _pos = 0;
                    _known = 0;
                  }),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(value: _pos / deck.length, minHeight: 6, backgroundColor: context.dca.surfaceHigh),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${_pos + 1} / ${deck.length}', style: context.text.labelMedium),
                  ],
                ),
                const SizedBox(height: 16),
                _FlipCard(card: deck[_pos], flipped: _flipped, lang: lang, onTap: () => setState(() => _flipped = !_flipped)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _answer(deck, knew: false),
                        icon: const Icon(Icons.replay),
                        label: Text(lang == Lang.hi ? 'फिर से' : 'Again'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: context.dca.success, foregroundColor: Colors.white),
                        onPressed: () => _answer(deck, knew: true),
                        icon: const Icon(Icons.check),
                        label: Text(lang == Lang.hi ? 'याद है' : 'I knew it'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              DcaSectionHeader(lang == Lang.hi ? 'सहेजे गए लेख' : 'Bookmarks', action: saved.isEmpty ? null : '${saved.length}'),
              if (saved.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Tap the bookmark on any story to keep it here.',
                      style: context.text.bodyMedium?.copyWith(color: context.dca.inkSecondary)),
                ),
              for (final (i, a) in saved.indexed) DcaNewsTile(a, showDivider: i < saved.length - 1),
            ],
          );
        },
      ),
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({required this.card, required this.flipped, required this.lang, required this.onTap});

  final Flashcard card;
  final bool flipped;
  final Lang lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = flipped;
    return Semantics(
      button: true,
      label: flipped ? 'Answer. Tap to see the question' : 'Question. Tap to see the answer',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(anim), child: FadeTransition(opacity: anim, child: child)),
        child: Material(
          key: ValueKey(flipped),
          color: dark ? const Color(0xFF0B1736) : context.colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: dark ? const Color(0xFF0B1736) : context.colors.outline, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withValues(alpha: 0.12) : context.colors.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        flipped ? 'ANSWER' : (card.fromMistake ? 'FROM YOUR MISTAKES' : 'QUESTION'),
                        style: context.text.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white : context.colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          flipped ? card.back.of(lang) : card.front.of(lang),
                          style: (flipped ? context.text.titleMedium : context.text.headlineSmall)?.copyWith(color: dark ? Colors.white : null),
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text('Tap to flip', style: context.text.labelSmall?.copyWith(color: dark ? const Color(0xFFB9C4E0) : context.dca.inkSecondary)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.known, required this.total, required this.onRestart});

  final int known;
  final int total;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.dca.successContainer, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revision done · +15 coins', style: context.text.titleLarge),
          const SizedBox(height: 6),
          Text('You knew $known of $total cards. Cards you missed come back tomorrow.', style: context.text.bodyMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onRestart, child: const Text('Go again'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () => context.go('/quiz-hub'), child: const Text('Take a quiz'))),
            ],
          ),
        ],
      ),
    );
  }
}
