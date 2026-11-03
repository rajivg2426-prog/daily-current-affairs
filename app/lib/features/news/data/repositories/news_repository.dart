import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/article.dart';
import 'sample_data.dart';

/// Where articles come from. The app talks only to this interface.
abstract interface class NewsRepository {
  Future<List<Article>> latest({int limit = 50});
}

/// Offline / demo mode: bundled sample explainers.
class SampleNewsRepository implements NewsRepository {
  SampleNewsRepository({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  Future<List<Article>> latest({int limit = 50}) async {
    final list = sampleArticles(_clock())..sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return list.take(limit).toList();
  }
}

/// Live mode: editor-approved articles written by the ingestion backend.
class FirestoreNewsRepository implements NewsRepository {
  FirestoreNewsRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<List<Article>> latest({int limit = 50}) async {
    final snap = await _db
        .collection('articles')
        .where('status', isEqualTo: 'published')
        .orderBy('publishDate', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => Article.fromFirestore(d.id, d.data())).toList();
  }
}
