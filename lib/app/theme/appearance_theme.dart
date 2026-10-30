import 'package:flutter/material.dart';
import 'package:saldough/core/appearance/appearance.dart';
import 'package:saldough/core/design_system/design_system.dart';

/// Membangun tema terang, gelap, dan mode dari [ActiveAppearance] (preset
/// dan mode pilihan pengguna) dan membangun ulang saat pilihannya berganti.
///
/// Dipakai `MaterialApp` di akar dan layar boot ulang, supaya keduanya
/// memakai tema yang sama lewat [AppThemeBridge] (ADR-043).
class AppearanceThemeBuilder extends StatelessWidget {
  /// Membuat pembangun tema.
  const AppearanceThemeBuilder({required this.builder, super.key});

  /// Membangun `MaterialApp` dari [light], [dark], dan [mode].
  final Widget Function(
    BuildContext context,
    ThemeData light,
    ThemeData dark,
    ThemeMode mode,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppearanceSettings>(
      valueListenable: ActiveAppearance.notifier,
      builder: (context, settings, _) {
        final preset = DsThemePresets.byId(settings.presetId);
        return builder(
          context,
          AppThemeBridge.build(preset, Brightness.light),
          AppThemeBridge.build(preset, Brightness.dark),
          settings.themeMode,
        );
      },
    );
  }
}
