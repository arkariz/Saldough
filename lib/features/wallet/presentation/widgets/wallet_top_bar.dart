import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';

/// App bar tab Dompet yang "mewarisi" hero saat hero tergulir (ADR-050
/// Revisi 2). Kemajuan [progress] 0 → 1 mengikuti gulir: latar bergradasi ke
/// warna hero, sudut bawah membulat dan berbayang, judul "Dompet" naik dan
/// memudar diganti label TOTAL ASET dan nominalnya, ikon aksi menjadi terang.
/// Gerak dikurangi: tanpa geser, hanya berganti.
class WalletTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Membuat [WalletTopBar].
  const WalletTopBar({
    required this.progress,
    required this.title,
    required this.totalText,
    required this.actions,
    super.key,
  });

  /// Kemajuan peralihan, 0 (judul halaman) sampai 1 (ringkasan hero).
  final ValueListenable<double> progress;

  /// Judul halaman ("Dompet").
  final String title;

  /// Nominal Total aset yang sudah diformat (ikut Sembunyikan nominal).
  final String totalText;

  /// Tombol aksi di kanan; warnanya diatur [IconTheme].
  final List<Widget> actions;

  static const _height = 60.0;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final top = MediaQuery.paddingOf(context).top;
    final reduced = DsMotion.reduced(context);
    final base = c.heroSurface;
    return ValueListenableBuilder<double>(
      valueListenable: progress,
      builder: (context, raw, _) {
        final p = Curves.easeOutCubic.transform(raw.clamp(0, 1));
        // Judul habis dulu (paruh pertama), ringkasan masuk sesudahnya (paruh
        // kedua), supaya keduanya tidak pernah bertumpuk.
        final titleOut = (p / 0.45).clamp(0.0, 1.0);
        final totalIn = ((p - 0.55) / 0.45).clamp(0.0, 1.0);
        final radius = Radius.circular(lerpDouble(0, 24, p)!);
        // Ikon aksi (warna asal textSecondary) diwarnai ulang menuju putih.
        final onBar = Color.lerp(c.textSecondary, Colors.white, p)!;
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          // Ikon bilah status terang di atas gradasi hero.
          value: p > 0.5 || dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Container(
            height: top + _height,
            padding: EdgeInsets.only(top: top),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(bottom: radius),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradasi hero yang muncul bertahap, dengan bayangan hero.
                Positioned(
                  top: -top,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: p,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(bottom: radius),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(base, Colors.white, 0.08)!,
                            Color.lerp(base, Colors.black, 0.22)!,
                            Color.lerp(base, Colors.black, 0.45)!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: base.withValues(alpha: 0.35 * p),
                            offset: const Offset(0, 8),
                            blurRadius: 20,
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // Judul halaman: naik dan memudar.
                            Opacity(
                              opacity: 1 - titleOut,
                              child: Transform.translate(
                                offset: Offset(0, reduced ? 0 : -14 * titleOut),
                                child: Text(title, style: ds.typography.headlineMd),
                              ),
                            ),
                            // Ringkasan hero: masuk dari bawah.
                            IgnorePointer(
                              ignoring: totalIn < 0.5,
                              child: Opacity(
                                opacity: totalIn,
                                child: Transform.translate(
                                  offset: Offset(0, reduced ? 0 : 14 * (1 - totalIn)),
                                  child: Column(
                                    key: const ValueKey('wallet-top-bar-total'),
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.assets.totalAssets.toUpperCase(),
                                        style: ds.typography.pixelCaption.copyWith(
                                          fontSize: 10,
                                          color: Colors.white.withValues(alpha: 0.75),
                                        ),
                                      ),
                                      Text(
                                        totalText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: ds.typography.titleMd.copyWith(
                                          color: Colors.white,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(onBar, BlendMode.srcIn),
                        child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Hero yang sedikit mengecil dan memudar saat tergulir pergi, supaya
/// peralihannya ke [WalletTopBar] terasa menyambung.
class WalletHeroScrollEffect extends StatelessWidget {
  /// Membuat [WalletHeroScrollEffect].
  const WalletHeroScrollEffect({required this.progress, required this.child, super.key});

  /// Kemajuan yang sama dengan [WalletTopBar].
  final ValueListenable<double> progress;

  /// Hero.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (DsMotion.reduced(context)) return child;
    return ValueListenableBuilder<double>(
      valueListenable: progress,
      child: child,
      builder: (context, p, child) => Opacity(
        opacity: (1 - 0.6 * p).clamp(0, 1),
        child: Transform.scale(scale: 1 - 0.06 * p, alignment: Alignment.bottomCenter, child: child),
      ),
    );
  }
}
