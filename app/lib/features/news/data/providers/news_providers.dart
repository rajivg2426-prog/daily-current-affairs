import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/providers/core_providers.dart';
import '../../../../common/providers/settings_provider.dart';
import '../../../../common/utils/category.dart';
import '../models/article.dart';
import '../repositories/news_repository.dart';

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  if (kUseFirebase) return FirestoreNewsRepository(FirebaseFirestore.instance);
  return SampleNewsRepository(clock: ref.read(clockProvider));
});

/// All recent articles, newest first.
final articlesProvider = FutureProvider<List<Article>>((ref) async {
  return ref.watch(newsRepositoryProvider).latest();
});

/// Articles tagged for the exams the user follows (all if none chosen).
final examArticlesProvider = Provider<AsyncValue<List<Article>>>((ref) {
  final exams = ref.watch(settingsProvider.select((s) => s.exams));
  return ref.watch(articlesProvider).whenData((list) => list.where((a) => a.matchesExams(exams)).toList());
});

final articleByIdProvider = Provider.family<Article?, String>((ref, id) {
  final list = ref.watch(articlesProvider).value ?? const <Article>[];
  for (final a in list) {
    if (a.id == id) return a;
  }
  return null;
});

/// Category filter on the News tab (null = all).
class CategoryFilter extends Notifier<NewsCategory?> {
  @override
  NewsCategory? build() => null;

  void select(NewsCategory? c) => state = c;
}

final categoryFilterProvider = NotifierProvider<CategoryFilter, NewsCategory?>(CategoryFilter.new);

final filteredArticlesProvider = Provider<AsyncValue<List<Article>>>((ref) {
  final cat = ref.watch(categoryFilterProvider);
  return ref.watch(articlesProvider).whenData((list) => cat == null ? list : list.where((a) => a.category == cat).toList());
});
