import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/theme/app_colors.dart';

/// Newspapers' own X accounts. v1 opens each timeline on X; a later version
/// can show X's official embedded timeline in a WebView (free, display-only).
/// We never copy or store their posts.
class LiveNewspapersScreen extends StatelessWidget {
  const LiveNewspapersScreen({super.key});

  static const routePath = '/live';

  // Check each handle before release; publishers occasionally rename accounts.
  static const _papers = <(String, String)>[
    ('The Hindu', 'the_hindu'),
    ('The Indian Express', 'IndianExpress'),
    ('Hindustan Times', 'htTweets'),
    ('The Times of India', 'timesofindia'),
    ('Mint', 'livemint'),
    ('DD News', 'DDNewslive'),
    ('PIB India', 'PIB_India'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live from newspapers')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: context.colors.primaryContainer, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: context.colors.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Exam notes in this app come from official sources. This page shows what newspapers are posting right now, on X.',
                    style: context.text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final (name, handle) in _papers)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: context.dca.surfaceHigh, child: Text(name.characters.first)),
                title: Text(name, style: context.text.titleSmall),
                subtitle: Text('@$handle', style: context.text.labelSmall?.copyWith(color: context.dca.inkSecondary)),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => launchUrl(Uri.parse('https://x.com/$handle'), mode: LaunchMode.externalApplication),
              ),
            ),
        ],
      ),
    );
  }
}
