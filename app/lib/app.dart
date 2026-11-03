import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'common/providers/settings_provider.dart';
import 'common/router/app_router.dart';
import 'common/theme/app_theme.dart';

class DcaApp extends ConsumerStatefulWidget {
  const DcaApp({super.key});

  @override
  ConsumerState<DcaApp> createState() => _DcaAppState();
}

class _DcaAppState extends ConsumerState<DcaApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Built once: onboarding state only decides the first screen.
    _router = buildRouter(onboarded: ref.read(settingsProvider).onboarded);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      title: 'Daily Current Affairs',
      debugShowCheckedModeBanner: false,
      theme: DcaTheme.light(),
      darkTheme: DcaTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
      supportedLocales: const [Locale('en', 'IN'), Locale('hi', 'IN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
