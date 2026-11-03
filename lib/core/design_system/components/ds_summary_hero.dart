import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/components/ds_count_up.dart';
import 'package:saldough/core/design_system/components/ds_idle_motion.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Satu kotak kaca di dasar [DsSummaryHero]: label kecil dan nominal.
class DsSummaryStat {
  /// Membuat kotak statistik.
  const DsSummaryStat({required this.label, required this.value});

  /// Label ("Rencana").
  final String label;

  /// Nominal terformat.
  final String value;
}

/// Kartu ringkasan hero gelap (acuan kartu saldo Beranda): label kapital dan
/// lencana, angka utama yang berhitung naik, bilah terpakai yang tumbuh,
/// kotak kaca statistik, dan ilustrasi clay yang melayang. Gerak berhenti
/// saat gerak dikurangi.
class DsSummaryHero extends StatelessWidget {
  /// Membuat [DsSummaryHero].
  const DsSummaryHero({
    required this.label,
    required this.amount,
    required this.format,
    required this.ratio,
    required this.stats,
    required this.asset,
    required this.semanticLabel,
    this.badge,
    this.negative = false,
    this.footer,
    super.key,
  });

  /// Label kapital kecil.
  final String label;

  /// Lencana di samping label ("3 aktif").
  final String? badge;

  /// Angka utama (sen) yang berhitung naik.
  final int amount;

  /// Mengubah angka berjalan jadi teks nominal.
  final String Function(int value) format;

  /// Angka utama sedang minus (bernuansa merah).
  final bool negative;

  /// Bagian terpakai 0–1 untuk bilah.
  final double ratio;

  /// Kotak statistik, berdampingan.
  final List<DsSummaryStat> stats;

  /// Ilustrasi clay yang melayang di pojok.
  final String asset;

  /// Label pembaca layar seluruh kartu.
  final String semanticLabel;

  /// Isi tambahan di bawah statistik.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final base = c.heroSurface;
    final barEnd = negative ? c.errorContainer : c.surfaceTint;
    final reduced = DsMotion.reduced(context);
    final clamped = ratio.clamp(0.0, 1.0);

    Widget glass(DsSummaryStat stat) => Expanded(
      child: DsSummaryGlass(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stat.label, style: ds.typography.bodySm.copyWith(color: c.onHeroMuted)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(stat.value, style: ds.typography.amount.copyWith(color: c.onHero)),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: DsRadius.xlAll,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(base, Colors.white, 0.08)!,
              Color.lerp(base, Colors.black, 0.22)!,
              Color.lerp(base, Colors.black, 0.5)!,
            ],
            stops: const [0, 0.45, 1],
          ),
          border: Border.all(color: c.primaryFixed.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: base.withValues(alpha: 0.35),
              offset: const Offset(0, 14),
              blurRadius: 28,
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: DsRadius.xlAll,
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [c.primaryFixed.withValues(alpha: 0.28), c.primaryFixed.withValues(alpha: 0)],
                      ),
                    ),
                    child: const SizedBox.square(dimension: 190),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 14,
                child: ExcludeSemantics(
                  child: DsIdleMotion(
                    kind: DsIdleKind.float,
                    child: SvgPicture.asset(asset, width: 52, height: 52),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: ds.typography.pixelCaption.copyWith(color: c.onHeroMuted),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: DsRadius.fullAll,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              child: Text(badge!, style: ds.typography.labelMd.copyWith(fontSize: 11, color: c.onHero)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: DsCountUp(
                        value: amount,
                        builder: (context, current) => Text(
                          format(current),
                          style: ds.typography.numericalDisplay.copyWith(color: negative ? c.errorContainer : c.onHero),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: DsRadius.fullAll,
                      child: SizedBox(
                        height: 8,
                        child: Stack(
                          children: [
                            Positioned.fill(child: ColoredBox(color: Colors.white.withValues(alpha: 0.18))),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: reduced ? clamped : 0, end: clamped),
                              duration: const Duration(milliseconds: 1100),
                              curve: DsMotion.easeOutExpo,
                              builder: (context, value, _) => FractionallySizedBox(
                                alignment: AlignmentDirectional.centerStart,
                                widthFactor: value,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [c.primaryFixed, barEnd]),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(spacing: 10, children: [for (final stat in stats) glass(stat)]),
                    if (footer != null) ...[const SizedBox(height: 12), footer!],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kotak kaca di dalam [DsSummaryHero] (isi bebas): latar putih 10%, garis
/// putih 14%, sudut 12.
class DsSummaryGlass extends StatelessWidget {
  /// Membuat [DsSummaryGlass].
  const DsSummaryGlass({required this.child, super.key});

  /// Isi.
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: DsRadius.mdAll,
      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
    ),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: child),
  );
}
