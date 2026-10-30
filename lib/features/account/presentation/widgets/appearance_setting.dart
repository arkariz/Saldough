import 'package:flutter/material.dart';
import 'package:saldough/core/appearance/appearance.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/account/presentation/widgets/setting_row.dart';

/// Nama preset warna untuk pengguna. Preset baru wajib menambah
/// `appearance.presets.<id>` di i18n; id yang belum diterjemahkan jatuh ke
/// `DsThemePreset.name` (uji menjaga semua preset terdaftar punya terjemahan).
String appearancePresetLabel(String id) => switch (id) {
  'matcha' => t.appearance.presets.matcha,
  'pink' => t.appearance.presets.pink,
  _ => DsThemePresets.byId(id).name,
};

/// Nama mode tampilan untuk pengguna.
String appearanceModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.light => t.appearance.modeLight,
  ThemeMode.dark => t.appearance.modeDark,
  ThemeMode.system => t.appearance.modeSystem,
};

/// Pilihan mode terang/gelap/ikut perangkat di bagian "Tampilan" layar Akun
/// (ADR-043). Berlaku seketika dan disimpan lewat [ActiveAppearance].
class AppearanceModeEntry extends StatelessWidget {
  /// Membuat [AppearanceModeEntry].
  const AppearanceModeEntry({super.key});

  Future<void> _choose(BuildContext context) async {
    final current = ActiveAppearance.value.themeMode;
    final picked = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(t.appearance.modePickerTitle),
        children: [
          for (final mode in ThemeMode.values)
            SimpleDialogOption(
              key: ValueKey('appearance-mode-${mode.name}'),
              onPressed: () => Navigator.of(dialogContext).pop(mode),
              child: Row(
                children: [
                  Expanded(child: Text(appearanceModeLabel(mode))),
                  if (mode == current) const AppIcon(IconKey.check),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || picked == current) return;
    ActiveAppearance.notifier.value = ActiveAppearance.value.copyWith(themeMode: picked);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppearanceSettings>(
      valueListenable: ActiveAppearance.notifier,
      builder: (context, settings, _) => SettingRow(
        key: const ValueKey('appearance-mode-setting'),
        icon: IconKey.contrast,
        title: t.appearance.modeLabel,
        subtitle: '${appearanceModeLabel(settings.themeMode)} · ${t.appearance.modeHint}',
        onTap: () => _choose(context),
      ),
    );
  }
}

/// Pilihan preset warna. Tidak tampil bila hanya ada satu preset.
class AppearancePresetEntry extends StatelessWidget {
  /// Membuat [AppearancePresetEntry]. [presets] hanya diganti oleh uji.
  const AppearancePresetEntry({this.presets = DsThemePresets.all, super.key});

  /// Preset yang bisa dipilih.
  final List<DsThemePreset> presets;

  Future<void> _choose(BuildContext context, String current) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(t.appearance.presetPickerTitle),
        children: [
          for (final preset in presets)
            SimpleDialogOption(
              key: ValueKey('appearance-preset-${preset.id}'),
              onPressed: () => Navigator.of(dialogContext).pop(preset.id),
              child: Row(
                children: [
                  _Swatch(color: preset.light.actionPrimary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(appearancePresetLabel(preset.id))),
                  if (preset.id == current) const AppIcon(IconKey.check),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || picked == current) return;
    ActiveAppearance.notifier.value = ActiveAppearance.value.copyWith(presetId: picked);
  }

  @override
  Widget build(BuildContext context) {
    if (presets.length < 2) return const SizedBox.shrink();
    return ValueListenableBuilder<AppearanceSettings>(
      valueListenable: ActiveAppearance.notifier,
      builder: (context, settings, _) {
        final current = DsThemePresets.byId(settings.presetId).id;
        return SettingRow(
          key: const ValueKey('appearance-preset-setting'),
          icon: IconKey.palette,
          title: t.appearance.presetLabel,
          subtitle: '${appearancePresetLabel(current)} · ${t.appearance.presetHint}',
          onTap: () => _choose(context, current),
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
