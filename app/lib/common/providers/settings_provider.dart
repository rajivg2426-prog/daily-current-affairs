import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bilingual.dart';
import 'core_providers.dart';

@immutable
class Settings {
  const Settings({
    this.lang = Lang.en,
    this.themeMode = ThemeMode.system,
    this.exams = const <String>{},
    this.onboarded = false,
    this.name = '',
  });

  final Lang lang;
  final ThemeMode themeMode;
  final Set<String> exams;
  final bool onboarded;
  final String name;

  Settings copyWith({Lang? lang, ThemeMode? themeMode, Set<String>? exams, bool? onboarded, String? name}) => Settings(
        lang: lang ?? this.lang,
        themeMode: themeMode ?? this.themeMode,
        exams: exams ?? this.exams,
        onboarded: onboarded ?? this.onboarded,
        name: name ?? this.name,
      );
}

/// User preferences, persisted to SharedPreferences.
class SettingsNotifier extends Notifier<Settings> {
  static const _kLang = 'settings.lang';
  static const _kTheme = 'settings.theme';
  static const _kExams = 'settings.exams';
  static const _kOnboarded = 'settings.onboarded';
  static const _kName = 'settings.name';

  @override
  Settings build() {
    final p = ref.read(sharedPrefsProvider);
    return Settings(
      lang: p.getString(_kLang) == 'hi' ? Lang.hi : Lang.en,
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == p.getString(_kTheme),
        orElse: () => ThemeMode.system,
      ),
      exams: (p.getStringList(_kExams) ?? const <String>[]).toSet(),
      onboarded: p.getBool(_kOnboarded) ?? false,
      name: p.getString(_kName) ?? '',
    );
  }

  void setLang(Lang lang) {
    state = state.copyWith(lang: lang);
    ref.read(sharedPrefsProvider).setString(_kLang, lang.name);
  }

  void toggleLang() => setLang(state.lang == Lang.en ? Lang.hi : Lang.en);

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    ref.read(sharedPrefsProvider).setString(_kTheme, mode.name);
  }

  /// Toggles an exam; at most three can be followed.
  bool toggleExam(String id) {
    final next = {...state.exams};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      if (next.length >= 3) return false;
      next.add(id);
    }
    state = state.copyWith(exams: next);
    ref.read(sharedPrefsProvider).setStringList(_kExams, next.toList());
    return true;
  }

  /// Re-running onboarding (to change exams) keeps the saved name unless a new one is typed.
  void completeOnboarding({String name = ''}) {
    final keep = name.isEmpty ? state.name : name;
    state = state.copyWith(onboarded: true, name: keep);
    final p = ref.read(sharedPrefsProvider);
    p.setBool(_kOnboarded, true);
    p.setString(_kName, keep);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
