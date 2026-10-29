import 'package:saldough/core/design_system/presets/autumn_kyoto.dart';
import 'package:saldough/core/design_system/presets/ds_theme_preset.dart';

/// Registri preset tema. Satu-satunya tempat mendaftarkan preset baru.
abstract final class DsThemePresets {
  DsThemePresets._();

  /// Seluruh preset yang bisa dipilih, urut tampil.
  static const List<DsThemePreset> all = [autumnKyoto];

  /// Preset bawaan, juga dipakai bila pilihan tersimpan tidak dikenal lagi.
  static const DsThemePreset fallback = autumnKyoto;

  /// Preset dengan [id], atau [fallback] bila tidak ada.
  static DsThemePreset byId(String? id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return fallback;
  }
}
