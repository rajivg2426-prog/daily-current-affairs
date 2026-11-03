import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

import '../../../../common/models/bilingual.dart';
import '../../../../common/utils/category.dart';

/// One multiple-choice question with four options.
class Mcq {
  const Mcq({
    required this.id,
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explanation,
    this.difficulty = 2,
  });

  final String id;
  final Bi question;
  final BiList options;
  final int answerIndex;
  final Bi explanation;
  final int difficulty;

  factory Mcq.fromJson(String id, Map<String, dynamic> json) => Mcq(
        id: id,
        question: Bi.fromJson(json['question']),
        options: BiList.fromJson(json['options']),
        answerIndex: (json['answerIndex'] as num?)?.toInt() ?? 0,
        explanation: Bi.fromJson(json['explanation']),
        difficulty: (json['difficulty'] as num?)?.toInt() ?? 2,
      );
}

/// Credit shown on every article ("Source: PIB").
class SourceCredit {
  const SourceCredit({required this.name, required this.url, required this.attribution});

  final String name;
  final String url;
  final String attribution;

  factory SourceCredit.fromJson(Object? json) {
    final m = json is Map ? json : const {};
    return SourceCredit(
      name: (m['name'] ?? '').toString(),
      url: (m['url'] ?? '').toString(),
      attribution: (m['attribution'] ?? '').toString(),
    );
  }
}

class Article {
  const Article({
    required this.id,
    required this.category,
    required this.examTags,
    required this.headline,
    required this.summary,
    required this.keyPoints,
    required this.body,
    required this.whyImportant,
    required this.syllabus,
    required this.relevance,
    required this.source,
    required this.publishDate,
    required this.mcqs,
    required this.facts,
    this.readMinutes = 4,
    this.isBreaking = false,
  });

  final String id;
  final NewsCategory category;
  final List<String> examTags;
  final Bi headline;
  final Bi summary;
  final BiList keyPoints;
  final Bi body;
  final Bi whyImportant;
  final String syllabus;
  final String relevance; // prelims | mains | both
  final SourceCredit source;
  final DateTime publishDate;
  final List<Mcq> mcqs;
  final List<Bi> facts;
  final int readMinutes;
  final bool isBreaking;

  bool matchesExams(Set<String> exams) => exams.isEmpty || examTags.any(exams.contains);

  /// Reads a published article written by the ingestion backend and approved by an editor.
  factory Article.fromFirestore(String id, Map<String, dynamic> json) {
    final mcqJson = (json['practice'] ?? json['draftMcqs'] ?? const []) as List;
    final factsJson = (json['facts'] ?? json['draftFacts'] ?? const []) as List;
    final ts = json['publishDate'];
    final DateTime date;
    if (ts is DateTime) {
      date = ts;
    } else if (ts is Timestamp) {
      date = ts.toDate();
    } else {
      date = DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now();
    }
    final bodyText = Bi.fromJson(json['body']);
    return Article(
      id: id,
      category: NewsCategory.fromId(json['category'] as String?),
      examTags: ((json['examTags'] ?? const []) as List).map((e) => e.toString()).toList(),
      headline: Bi.fromJson(json['headline']),
      summary: Bi.fromJson(json['summary']),
      keyPoints: BiList.fromJson(json['keyPoints']),
      body: bodyText,
      whyImportant: Bi.fromJson(json['whyImportant']),
      syllabus: (json['syllabus'] ?? '').toString(),
      relevance: (json['relevance'] ?? 'prelims').toString(),
      source: SourceCredit.fromJson(json['source']),
      publishDate: date,
      mcqs: [
        for (var i = 0; i < mcqJson.length; i++)
          Mcq.fromJson('$id-q$i', Map<String, dynamic>.from(mcqJson[i] as Map)),
      ],
      facts: factsJson.map(Bi.fromJson).toList(),
      readMinutes: ((bodyText.en.split(' ').length) / 200).ceil().clamp(1, 15),
      isBreaking: json['isBreaking'] == true,
    );
  }
}
