# Daily Current Affairs: Flutter app

The mobile app: read today's stories, take the daily quiz, revise with flashcards, track your streak. English and Hindi, light and dark themes, in the Ink Blue design.

## Run it (5 minutes)

You need Flutter 3.27 or newer (`flutter --version`).

```bash
cd app
flutter create . --org app.dailyca --project-name daily_current_affairs --platforms android,ios,web
flutter pub get
flutter run            # pick a phone, emulator or Chrome
```

`flutter create .` only adds the missing `android/`, `ios/` and `web/` folders; it leaves `lib/` alone.

The app starts in **sample mode** with eight built-in exam explainers, so everything works offline before the backend is live.

If `flutter pub get` complains about versions, run `flutter pub upgrade --major-versions`.

### Checks

```bash
flutter analyze
flutter test
```

## Live mode (Firebase)

1. Deploy the backend in `../backend` (see its README) so editor-approved articles land in Firestore.
2. Connect the app to the same Firebase project:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure      # writes google-services.json / GoogleService-Info.plist
   ```
3. Run with live data:
   ```bash
   flutter run --dart-define=USE_FIREBASE=true
   ```

The app reads `articles` where `status == "published"`, newest first. The matching Firestore index is in `../backend/firestore.indexes.json`.

## What's in v1

| Screen | What works |
|---|---|
| Onboarding | Language, optional name, up to 3 exams (guest mode) |
| Home | Today card (Read → Quiz → Revise, one next step), headlines carousel, exam-filtered list, categories, streak and coins |
| News | Category chips, keyword search (English and Hindi), bookmark |
| Article | Summary, Detailed, Why it matters, Practice tabs; EN/हिं toggle; source credit linking to the original |
| Quiz | Daily 10, Daily 25, by category, My mistakes; instant feedback, timer, progress bar |
| Result | Score ring, accuracy, time, coins, streak, accuracy by category |
| Revise | Flashcards from your mistakes and key facts, bookmarks |
| Profile | Level and XP, streak, coins, accuracy by category, badges, theme, language, exams |
| Live from newspapers | Opens each paper's official X account |

Progress (coins, streak, mistakes, history) is stored on the device. Streaks roll over at midnight IST.

## Not yet built

- Google and mobile OTP sign-in (Firebase Auth), so progress syncs across devices
- Server-side quiz grading and leaderboards (`/quizzes/submit` in the spec)
- Monthly magazine PDFs, Ask AI, push notifications, Premium

## Structure

```
lib/
  main.dart, app.dart
  common/      theme (Ink Blue light/dark), router (go_router + bottom-nav shell),
               models (bilingual text), providers (settings, prefs), widgets, utils
  features/
    onboarding/  home/  news/  quiz/  revise/  profile/  live/
      data/    models · providers (Riverpod 3 Notifiers) · repositories
      views/   screens · widgets
```

State is Riverpod 3 `Notifier`s without code generation, so there is no `build_runner` step to run.
