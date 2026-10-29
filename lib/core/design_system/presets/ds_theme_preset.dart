import 'package:flutter/foundation.dart';
import 'package:saldough/core/design_system/color/ds_color_scheme.dart';

/// Satu preset tema: palet warna mode terang dan gelap (ADR-043).
///
/// Huruf, sudut, jarak, dan elevasi berlaku global, jadi preset hanya
/// membawa warna. Menambah preset: buat berkas baru di `presets/` berisi
/// `const DsThemePreset(...)`, lalu daftarkan di `DsThemePresets.all`.
@immutable
class DsThemePreset {
  /// Membuat preset.
  const DsThemePreset({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
  });

  /// Kunci tetap untuk disimpan sebagai pilihan pengguna. Jangan diganti
  /// setelah dirilis; `snake_case`.
  final String id;

  /// Nama tampilan sementara. Label pengguna nanti lewat i18n
  /// `appearance.presets.<id>`.
  final String name;

  /// Skema warna mode terang.
  final DsColorScheme light;

  /// Skema warna mode gelap.
  final DsColorScheme dark;
}
