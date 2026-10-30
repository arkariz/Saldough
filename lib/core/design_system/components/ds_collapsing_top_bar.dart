import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_top_bar.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';

/// [DsTopBar] yang menyusut mengikuti gulir [controller]: logo kata
/// memudar dan [collapsedTitle] (mis. mini saldo) turun masuk antara gulir
/// 110 dan 240px; bayangan tipis muncul setelah 15px.
class DsCollapsingTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Membuat top bar menyusut.
  const DsCollapsingTopBar({
    required this.controller,
    required this.wordmark,
    required this.collapsedTitle,
    this.logo,
    this.badge,
    this.actions = const [],
    super.key,
  });

  /// Pengendali gulir halaman.
  final ScrollController controller;

  /// Logo kata.
  final String wordmark;

  /// Isi yang tampil saat menyusut.
  final Widget collapsedTitle;

  /// Gambar logo.
  final Widget? logo;

  /// Lencana di samping logo kata.
  final Widget? badge;

  /// Tindakan di kanan.
  final List<Widget> actions;

  /// Kemajuan menyusut 0–1 untuk gulir [offset] px.
  static double progressFor(double offset, {double start = DsMotion.collapseStart, double end = DsMotion.collapseEnd}) {
    if (offset <= start) return 0;
    return ((offset - start) / (end - start)).clamp(0.0, 1.0);
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final offset = controller.hasClients ? controller.offset : 0.0;
        return DsTopBar(
          wordmark: wordmark,
          logo: logo,
          badge: badge,
          actions: actions,
          collapsedTitle: collapsedTitle,
          collapse: progressFor(offset),
          elevated: offset > 15,
        );
      },
    );
  }
}

/// Menggeser [child] sedikit searah gulir (parallax). Gerak dimatikan saat
/// gerak dikurangi.
class DsParallax extends StatelessWidget {
  /// Membuat parallax.
  const DsParallax({required this.controller, required this.child, this.factor = 0.06, super.key});

  /// Pengendali gulir halaman.
  final ScrollController controller;

  /// Isi.
  final Widget child;

  /// Pergeseran per px gulir.
  final double factor;

  @override
  Widget build(BuildContext context) {
    if (DsMotion.reduced(context)) return child;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final offset = controller.hasClients ? controller.offset.clamp(0, 400) : 0;
        return Transform.translate(offset: Offset(0, offset * factor), child: child);
      },
      child: child,
    );
  }
}
