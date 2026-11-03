import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `flutter run --dart-define=USE_FIREBASE=true` switches to live Firestore data.
const bool kUseFirebase = bool.fromEnvironment('USE_FIREBASE');

/// Overridden in main() once SharedPreferences has loaded.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden in main()'),
);

/// Injectable clock so streak logic can be tested.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
