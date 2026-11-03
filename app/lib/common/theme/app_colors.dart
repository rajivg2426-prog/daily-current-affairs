import 'package:flutter/material.dart';

/// Ink Blue palette. Saffron is reserved for rewards (streaks, coins).
abstract final class DcaPalette {
  // Light
  static const primary = Color(0xFF2350E6);
  static const primaryDeep = Color(0xFF1636A8);
  static const primaryContainer = Color(0xFFE8EEFF);
  static const ink = Color(0xFF0B1736);
  static const inkSecondary = Color(0xFF5A6685);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F7FC);
  static const surfaceHigh = Color(0xFFECF0F8);
  static const outline = Color(0xFFDDE3EF);

  // Dark
  static const primaryDark = Color(0xFF8AA8FF);
  static const primaryDeepDark = Color(0xFFB9CBFF);
  static const primaryContainerDark = Color(0xFF1C2C66);
  static const inkDark = Color(0xFFE8EDF8);
  static const inkSecondaryDark = Color(0xFF9CA8C6);
  static const backgroundDark = Color(0xFF0A0F1E);
  static const surfaceDark = Color(0xFF121A2E);
  static const surfaceHighDark = Color(0xFF1A2440);
  static const outlineDark = Color(0xFF2A3658);

  // Semantic
  static const reward = Color(0xFFF59E0B);
  static const rewardContainer = Color(0xFFFFF4E0);
  static const success = Color(0xFF12A15E);
  static const successText = Color(0xFF0B7A45);
  static const successContainer = Color(0xFFE5F6EE);
  static const error = Color(0xFFE5484D);
  static const errorText = Color(0xFFC42B30);
  static const errorContainer = Color(0xFFFDECEC);
}

/// Colours that Material's ColorScheme has no slot for.
@immutable
class DcaColors extends ThemeExtension<DcaColors> {
  const DcaColors({
    required this.inkSecondary,
    required this.surfaceHigh,
    required this.outline,
    required this.reward,
    required this.rewardContainer,
    required this.onRewardContainer,
    required this.success,
    required this.successContainer,
    required this.error,
    required this.errorContainer,
  });

  final Color inkSecondary;
  final Color surfaceHigh;
  final Color outline;
  final Color reward;
  final Color rewardContainer;
  final Color onRewardContainer;
  final Color success;
  final Color successContainer;
  final Color error;
  final Color errorContainer;

  static const light = DcaColors(
    inkSecondary: DcaPalette.inkSecondary,
    surfaceHigh: DcaPalette.surfaceHigh,
    outline: DcaPalette.outline,
    reward: DcaPalette.reward,
    rewardContainer: DcaPalette.rewardContainer,
    onRewardContainer: Color(0xFF6B4A10),
    success: DcaPalette.successText,
    successContainer: DcaPalette.successContainer,
    error: DcaPalette.errorText,
    errorContainer: DcaPalette.errorContainer,
  );

  static const dark = DcaColors(
    inkSecondary: DcaPalette.inkSecondaryDark,
    surfaceHigh: DcaPalette.surfaceHighDark,
    outline: DcaPalette.outlineDark,
    reward: Color(0xFFFBBF24),
    rewardContainer: Color(0xFF2A2210),
    onRewardContainer: Color(0xFFFBBF24),
    success: Color(0xFF4ADE80),
    successContainer: Color(0xFF0F2A1E),
    error: Color(0xFFFF6B6F),
    errorContainer: Color(0xFF2A1418),
  );

  @override
  DcaColors copyWith({
    Color? inkSecondary,
    Color? surfaceHigh,
    Color? outline,
    Color? reward,
    Color? rewardContainer,
    Color? onRewardContainer,
    Color? success,
    Color? successContainer,
    Color? error,
    Color? errorContainer,
  }) {
    return DcaColors(
      inkSecondary: inkSecondary ?? this.inkSecondary,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      outline: outline ?? this.outline,
      reward: reward ?? this.reward,
      rewardContainer: rewardContainer ?? this.rewardContainer,
      onRewardContainer: onRewardContainer ?? this.onRewardContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
    );
  }

  @override
  DcaColors lerp(ThemeExtension<DcaColors>? other, double t) {
    if (other is! DcaColors) return this;
    return DcaColors(
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      reward: Color.lerp(reward, other.reward, t)!,
      rewardContainer: Color.lerp(rewardContainer, other.rewardContainer, t)!,
      onRewardContainer: Color.lerp(onRewardContainer, other.onRewardContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
    );
  }
}

extension DcaThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  DcaColors get dca => Theme.of(this).extension<DcaColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
