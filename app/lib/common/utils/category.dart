import 'package:flutter/material.dart';

import '../models/bilingual.dart';

/// The 11 news categories, with display name, icon and accent colour.
enum NewsCategory {
  national('national', Bi('National', 'राष्ट्रीय'), Icons.flag_outlined, Color(0xFF2350E6)),
  international('international', Bi('International', 'अंतरराष्ट्रीय'), Icons.public, Color(0xFF7C3AED)),
  economy('economy', Bi('Economy', 'अर्थव्यवस्था'), Icons.trending_up, Color(0xFF0E9F6E)),
  scitech('scitech', Bi('Sci & Tech', 'विज्ञान-तकनीक'), Icons.memory, Color(0xFF0E9AA7)),
  environment('environment', Bi('Environment', 'पर्यावरण'), Icons.eco_outlined, Color(0xFF16A34A)),
  awards('awards', Bi('Awards', 'पुरस्कार'), Icons.emoji_events_outlined, Color(0xFFD97706)),
  sports('sports', Bi('Sports', 'खेल'), Icons.sports_cricket_outlined, Color(0xFFEA580C)),
  schemes('schemes', Bi('Schemes', 'योजनाएं'), Icons.account_balance_outlined, Color(0xFF2563EB)),
  defence('defence', Bi('Defence', 'रक्षा'), Icons.shield_outlined, Color(0xFF475569)),
  books('books', Bi('Books & Authors', 'पुस्तकें'), Icons.menu_book_outlined, Color(0xFFBE185D)),
  days('days', Bi('Important Days', 'महत्वपूर्ण दिवस'), Icons.event_outlined, Color(0xFFDB2777));

  const NewsCategory(this.id, this.label, this.icon, this.color);

  final String id;
  final Bi label;
  final IconData icon;
  final Color color;

  /// 12% tint used behind chips and thumbnails.
  Color get tint => color.withValues(alpha: 0.12);

  static NewsCategory fromId(String? id) =>
      NewsCategory.values.firstWhere((c) => c.id == id, orElse: () => NewsCategory.national);
}

/// Exams the user can follow.
enum Exam {
  upsc('upsc', 'UPSC', 'Civil Services, IFS, CAPF', Color(0xFF2350E6)),
  ssc('ssc', 'SSC', 'CGL, CHSL, MTS, GD', Color(0xFF0E9F6E)),
  banking('banking', 'Banking', 'IBPS, SBI, RBI Grade B', Color(0xFF7C3AED)),
  railway('railway', 'Railway', 'RRB NTPC, Group D, ALP', Color(0xFFC2410C)),
  defence('defence', 'Defence', 'NDA, CDS, AFCAT', Color(0xFF475569)),
  statepsc('statepsc', 'State PSC', 'Your state commission', Color(0xFF0E7C86));

  const Exam(this.id, this.label, this.subtitle, this.color);

  final String id;
  final String label;
  final String subtitle;
  final Color color;

  static Exam? fromId(String id) {
    for (final e in Exam.values) {
      if (e.id == id) return e;
    }
    return null;
  }
}
