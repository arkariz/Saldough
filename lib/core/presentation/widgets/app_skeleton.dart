import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Placeholder animasi untuk pemuatan PERTAMA (belum ada data sama sekali).
///
/// Bukan untuk pemuatan ulang (data sudah ada) — itu memakai indikator halus
/// yang tidak membuang konten (lihat UX-17). Memakai `shimmerBase`/
/// `shimmerHighlight` dari [AppColorsExtension], yang sebelumnya tidak
/// pernah dipakai satu widget pun sejak ADR-0006 menyiapkan slotnya.
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
    duration: AppDurations.slow * 3,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(colors.shimmerBase, colors.shimmerHighlight, _controller.value),
          borderRadius: widget.borderRadius ?? AppRadius.smAll,
        ),
      ),
    );
  }
}

/// Susunan [AppSkeleton] meniru bentuk kasar layar berisi kartu (hero +
/// beberapa baris) — dipakai sebagai pengganti spinner penuh saat pemuatan
/// pertama, di layar yang isinya memang berbentuk itu (Siklus, Belanja).
class AppSkeletonPage extends StatelessWidget {
  /// Membuat [AppSkeletonPage].
  const AppSkeletonPage({this.rowCount = 4, super.key});

  /// Jumlah baris skeleton di bawah blok hero.
  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          AppSkeleton(height: 88, borderRadius: AppRadius.mdAll),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < rowCount; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppSkeleton(height: 56, borderRadius: AppRadius.mdAll),
            ),
        ],
      ),
    );
  }
}
