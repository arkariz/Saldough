import 'package:saldough/core/design_system/presets/ds_theme_preset.dart';
import 'package:saldough/core/design_system/presets/matcha.dart';

/// Registri preset tema. Satu-satunya tempat mendaftarkan preset baru.
abstract final class DsThemePresets {
  DsThemePresets._();

  /// Seluruh preset yang bisa dipilih, urut tampil.
  static const List<DsThemePreset> all = [matcha];

  /// Preset bawaan, juga dipakai bila pilihan tersimpan tidak dikenal lagi.
  static const DsThemePreset fallback = matcha;

  /// Preset dengan [id], atau [fallback] bila tidak ada.
  static DsThemePreset byId(String? id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return fallback;
  }
}
