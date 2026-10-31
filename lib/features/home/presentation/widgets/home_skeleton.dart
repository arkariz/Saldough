import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';

/// Kerangka pemuatan pertama Beranda: meniru susunan sebenarnya (sapaan,
/// kartu saldo, empat aksi cepat, satu slide, dan daftar transaksi).
///
/// Data lokal biasanya siap di bawah [delay]; kerangka baru tampil sesudah
/// itu supaya layar tidak berkedip.
class HomeSkeleton extends StatefulWidget {
  /// Membuat [HomeSkeleton].
  const HomeSkeleton({super.key});

  /// Jeda sebelum kerangka tampil.
  static const delay = Duration(milliseconds: 300);

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(HomeSkeleton.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.expand();
    Widget gap([double h = DsSpacing.stack]) => SizedBox(height: h);
    return Semantics(
      container: true,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(DsSpacing.md, DsSpacing.sm, DsSpacing.md, DsSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DsSkeleton(height: 24, width: 180),
            gap(DsSpacing.sm),
            const DsSkeleton(height: 14, width: 240),
            gap(),
            const DsSkeleton(height: 200, radius: DsRadius.xlAll),
            gap(),
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  const Expanded(child: DsSkeleton(height: 84, radius: DsRadius.lgAll)),
                ],
              ],
            ),
            gap(),
            const DsSkeleton(height: 72, radius: DsRadius.lgAll),
            gap(DsSpacing.lg),
            const DsSkeleton(height: 16, width: 140),
            gap(DsSpacing.sm),
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) gap(DsSpacing.sm),
              const Row(
                children: [
                  DsSkeleton.circle(size: 40),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DsSkeleton(height: 14, width: 140),
                        SizedBox(height: 6),
                        DsSkeleton(height: 12, width: 90),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  DsSkeleton(height: 14, width: 64),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
