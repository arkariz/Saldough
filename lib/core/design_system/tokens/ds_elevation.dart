import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/color/ds_color_scheme.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Satu tingkat permukaan: warna isi, bingkai 1px, dan bayangan.
@immutable
class DsSurfaceTier {
  /// Membuat tingkat permukaan.
  const DsSurfaceTier({required this.color, required this.border, required this.shadows});

  /// Interpolasi dua tingkat.
  factory DsSurfaceTier.lerp(DsSurfaceTier a, DsSurfaceTier b, double t) => DsSurfaceTier(
    color: Color.lerp(a.color, b.color, t)!,
    border: Color.lerp(a.border, b.border, t)!,
    shadows: BoxShadow.lerpList(a.shadows, b.shadows, t) ?? const [],
  );

  /// Warna isi permukaan.
  final Color color;

  /// Warna bingkai 1px; [Colors.transparent] bila tanpa bingkai.
  final Color border;

  /// Bayangan sekitar yang lembut.
  final List<BoxShadow> shadows;

  /// [BoxDecoration] siap pakai dengan sudut [radius].
  BoxDecoration decoration({BorderRadius radius = DsRadius.lgAll}) => BoxDecoration(
    color: color,
    borderRadius: radius,
    border: border.a == 0 ? null : Border.all(color: border),
    boxShadow: shadows,
  );
}

/// Elevasi design system baru (spek bagian "Elevation & Depth", ADR-043):
/// hierarki lewat lapisan nada hangat dan bayangan sekitar yang lembut,
/// bukan bayangan jatuh yang berat.
@immutable
class DsElevation extends ThemeExtension<DsElevation> {
  /// Membuat elevasi.
  const DsElevation({required this.tier0, required this.tier1, required this.tier2, required this.tier3});

  /// Elevasi dari [colors]. Nilai bayangan terang persis spek; di mode gelap
  /// bayangan hampir tak terlihat, jadi bingkai yang membedakan tingkat dan
  /// bayangan hanya dipakai tier 2–3 dengan hitam pekat.
  factory DsElevation.from(DsColorScheme colors, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return DsElevation(
      tier0: DsSurfaceTier(color: colors.surfaceCanvas, border: Colors.transparent, shadows: const []),
      tier1: DsSurfaceTier(
        color: colors.surfaceContainer,
        border: colors.outlineSubtle,
        shadows: dark
            ? const []
            : [BoxShadow(color: colors.shadow.withValues(alpha: 0.04), offset: const Offset(0, 1), blurRadius: 2)],
      ),
      tier2: DsSurfaceTier(
        color: colors.surfaceContainerLow,
        border: colors.warmSand,
        shadows: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: dark ? 0.32 : 0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: -2,
          ),
          if (!dark)
            BoxShadow(
              color: colors.shadowTint.withValues(alpha: 0.05),
              offset: const Offset(0, 2),
              blurRadius: 4,
              spreadRadius: -1,
            ),
        ],
      ),
      tier3: DsSurfaceTier(
        color: colors.surfaceFloating,
        border: colors.outlineFloating,
        shadows: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: dark ? 0.48 : 0.10),
            offset: const Offset(0, 12),
            blurRadius: 28,
            spreadRadius: -4,
          ),
          if (!dark)
            BoxShadow(
              color: colors.shadowAccent.withValues(alpha: 0.06),
              offset: const Offset(0, 4),
              blurRadius: 10,
              spreadRadius: -2,
            ),
        ],
      ),
    );
  }

  /// Tier 0: kanvas dasar, tanpa elevasi.
  final DsSurfaceTier tier0;

  /// Tier 1: kartu dan wadah diam.
  final DsSurfaceTier tier1;

  /// Tier 2: kartu interaktif yang aktif atau ditekan.
  final DsSurfaceTier tier2;

  /// Tier 3: laci, menu, dan dialog mengambang.
  final DsSurfaceTier tier3;

  @override
  DsElevation copyWith({DsSurfaceTier? tier0, DsSurfaceTier? tier1, DsSurfaceTier? tier2, DsSurfaceTier? tier3}) {
    return DsElevation(
      tier0: tier0 ?? this.tier0,
      tier1: tier1 ?? this.tier1,
      tier2: tier2 ?? this.tier2,
      tier3: tier3 ?? this.tier3,
    );
  }

  @override
  DsElevation lerp(ThemeExtension<DsElevation>? other, double t) {
    if (other is! DsElevation) return this;
    return DsElevation(
      tier0: DsSurfaceTier.lerp(tier0, other.tier0, t),
      tier1: DsSurfaceTier.lerp(tier1, other.tier1, t),
      tier2: DsSurfaceTier.lerp(tier2, other.tier2, t),
      tier3: DsSurfaceTier.lerp(tier3, other.tier3, t),
    );
  }
}
