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
    final picked = await showOptionSheet<ThemeMode>(
      context,
      title: t.appearance.modePickerTitle,
      current: current,
      options: [
        for (final mode in ThemeMode.values)
          OptionSheetItem(
            key: ValueKey('appearance-mode-${mode.name}'),
            value: mode,
            label: appearanceModeLabel(mode),
            leading: Icon(switch (mode) {
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.dark => Icons.dark_mode_outlined,
              ThemeMode.system => Icons.brightness_auto_outlined,
            }, color: context.ds.colors.actionPrimary),
          ),
      ],
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
    final picked = await showOptionSheet<String>(
      context,
      title: t.appearance.presetPickerTitle,
      current: current,
      options: [
        for (final preset in presets)
          OptionSheetItem(
            key: ValueKey('appearance-preset-${preset.id}'),
            value: preset.id,
            label: appearancePresetLabel(preset.id),
            leading: _Swatch(color: preset.light.actionPrimary),
          ),
      ],
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
