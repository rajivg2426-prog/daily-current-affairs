/// Content language. UI strings and article content switch independently.
enum Lang { en, hi }

/// A string available in English and Hindi.
class Bi {
  const Bi(this.en, this.hi);

  final String en;
  final String hi;

  String of(Lang lang) => lang == Lang.hi && hi.isNotEmpty ? hi : en;

  factory Bi.fromJson(Object? json) {
    if (json is Map) {
      return Bi((json['en'] ?? '').toString(), (json['hi'] ?? '').toString());
    }
    final s = (json ?? '').toString();
    return Bi(s, s);
  }

  Map<String, String> toJson() => {'en': en, 'hi': hi};
}

/// A list of strings available in English and Hindi.
class BiList {
  const BiList(this.en, this.hi);

  final List<String> en;
  final List<String> hi;

  List<String> of(Lang lang) => lang == Lang.hi && hi.isNotEmpty ? hi : en;

  factory BiList.fromJson(Object? json) {
    if (json is Map) {
      List<String> list(Object? v) => v is List ? v.map((e) => e.toString()).toList() : const <String>[];
      return BiList(list(json['en']), list(json['hi']));
    }
    return const BiList(<String>[], <String>[]);
  }
}
