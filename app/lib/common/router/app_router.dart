import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/views/screens/home_screen.dart';
import '../../features/live/views/screens/live_newspapers_screen.dart';
import '../../features/news/views/screens/article_screen.dart';
import '../../features/news/views/screens/news_screen.dart';
import '../../features/onboarding/views/screens/onboarding_screen.dart';
import '../../features/profile/views/screens/profile_screen.dart';
import '../../features/quiz/views/screens/quiz_hub_screen.dart';
import '../../features/quiz/views/screens/quiz_result_screen.dart';
import '../../features/quiz/views/screens/quiz_screen.dart';
import '../../features/revise/views/screens/revise_screen.dart';
import '../widgets/dca_shell.dart';

/// Routes. Tabs live inside a StatefulShellRoute so each tab keeps its scroll
/// position; full-screen flows (article, quiz) push over the tabs.
GoRouter buildRouter({required bool onboarded}) {
  return GoRouter(
    initialLocation: onboarded ? HomeScreen.routePath : OnboardingScreen.routePath,
    routes: [
      GoRoute(path: OnboardingScreen.routePath, builder: (context, state) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => DcaShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: HomeScreen.routePath, builder: (c, s) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: NewsScreen.routePath, builder: (c, s) => const NewsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: QuizHubScreen.routePath, builder: (c, s) => const QuizHubScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: ReviseScreen.routePath, builder: (c, s) => const ReviseScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: ProfileScreen.routePath, builder: (c, s) => const ProfileScreen())]),
        ],
      ),
      GoRoute(
        path: ArticleScreen.routePath,
        builder: (context, state) => ArticleScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: QuizScreen.routePath, builder: (context, state) => const QuizScreen()),
      GoRoute(path: QuizResultScreen.routePath, builder: (context, state) => const QuizResultScreen()),
      GoRoute(path: LiveNewspapersScreen.routePath, builder: (context, state) => const LiveNewspapersScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
}
