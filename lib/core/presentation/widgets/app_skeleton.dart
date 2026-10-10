import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Placeholder animasi untuk pemuatan PERTAMA (belum ada data sama sekali).
///
/// Bukan untuk pemuatan ulang (data sudah ada) — itu memakai indikator halus
/// yang tidak membuang konten (lihat UX-17). Berdenyut antara `surface2` dan
/// `surface3`; tanpa denyut saat kurangi gerakan aktif.
class AppSkeleton extends StatefulWidget {
  /// Membuat satu blok [AppSkeleton] selebar [width] (`null` = mengisi induk)
  /// dan setinggi [height].
  const AppSkeleton({
    required this.height,
    this.width,
    this.borderRadius,
    super.key,
  });

  /// Lebar blok. `null` mengisi lebar yang tersedia.
  final double? width;

  /// Tinggi blok.
  final double height;

  /// Sudut blok. `null` bawaan ke [AppRadius.smAll] (getter, bukan
  /// konstanta -- tidak bisa jadi nilai bawaan parameter langsung).
  final BorderRadius? borderRadius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    // Denyut pelan 1,4 detik per siklus (design system Skeleton).
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Kurangi gerakan: tanpa denyut.
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_controller.isAnimating) _controller.stop();
      return _box(colors.surface2);
    }
    if (!_controller.isAnimating) _controller.repeat(reverse: true);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _box(Color.lerp(colors.surface2, colors.surface3, _controller.value)!),
    );
  }

  Widget _box(Color color) => Container(
    width: widget.width,
    height: widget.height,
    decoration: BoxDecoration(color: color, borderRadius: widget.borderRadius ?? AppRadius.smAll),
  );
}

/// Susunan [AppSkeleton] meniru layar berisi angka utama dan daftar
/// (design system Skeleton): blok angka di atas, lalu kartu berisi baris
/// tile 40px, dua garis teks, dan nominal di kanan.
///
/// Data lokal biasanya siap di bawah [delay]; skeleton baru tampil sesudah
/// itu supaya layar tidak berkedip.
class AppSkeletonPage extends StatefulWidget {
  /// Membuat [AppSkeletonPage].
  const AppSkeletonPage({this.rowCount = 4, super.key});

  /// Jumlah baris tiruan.
  final int rowCount;

  /// Jeda sebelum skeleton tampil.
  static const delay = Duration(milliseconds: 300);

  @override
  State<AppSkeletonPage> createState() => _AppSkeletonPageState();
}

class _AppSkeletonPageState extends State<AppSkeletonPage> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(AppSkeletonPage.delay, () {
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
    final colors = context.appColors;
    final line = BorderRadius.circular(AppSize.pixelStepSm);
    return Semantics(
      container: true,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeleton(height: 14, width: 96, borderRadius: line),
            const SizedBox(height: AppSpacing.space2),
            AppSkeleton(height: 36, width: 200, borderRadius: line),
            const SizedBox(height: AppSpacing.space6),
            DecoratedBox(
              decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(AppSize.pixelStep)),
              child: Column(
                children: [
                  for (var i = 0; i < widget.rowCount; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: 12),
                      child: Row(
                        children: [
                          AppSkeleton(height: AppSize.tile, width: AppSize.tile, borderRadius: line),
                          const SizedBox(width: AppSpacing.space3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FractionallySizedBox(
                                  widthFactor: 0.6,
                                  child: AppSkeleton(height: 14, borderRadius: line),
                                ),
                                const SizedBox(height: AppSpacing.space2),
                                FractionallySizedBox(
                                  widthFactor: 0.35,
                                  child: AppSkeleton(height: 12, borderRadius: line),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space4),
                          AppSkeleton(height: 14, width: 72, borderRadius: line),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
