import 'package:flutter/material.dart';

/// Pilihan tampilan pengguna: preset warna dan mode terang/gelap (ADR-043).
@immutable
class AppearanceSettings {
  /// Membuat setelan.
  const AppearanceSettings({required this.presetId, required this.themeMode});

  /// Bawaan: preset bawaan design system, mengikuti mode sistem.
  static const AppearanceSettings initial = AppearanceSettings(presetId: 'matcha', themeMode: ThemeMode.system);

  /// Id preset (`DsThemePreset.id`). Id yang tidak dikenal lagi jatuh ke
  /// preset bawaan saat tema dibangun.
  final String presetId;

  /// Mode terang, gelap, atau mengikuti sistem.
  final ThemeMode themeMode;

  /// Salinan dengan sebagian nilai diganti.
  AppearanceSettings copyWith({String? presetId, ThemeMode? themeMode}) =>
      AppearanceSettings(presetId: presetId ?? this.presetId, themeMode: themeMode ?? this.themeMode);

  @override
  bool operator ==(Object other) =>
      other is AppearanceSettings && other.presetId == presetId && other.themeMode == themeMode;

  @override
  int get hashCode => Object.hash(presetId, themeMode);
}
