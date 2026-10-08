import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';

/// Permukaan `surface` rata untuk satu kelompok isi (komponen Card,
/// ADR-034): sudut piksel (`pixel-step`), padding `space-4`, tanpa bingkai
/// dan bayangan. Judul bagian duduk di luar kartu ([AppSectionHeader]).
///
/// Jangan menaruh kartu di dalam kartu; kelompokkan isinya dengan jarak dan
/// `Divider`. Dengan [onTap], seluruh kartu jadi satu target sentuh (tekan:
/// `surface2`).
class AppCard extends StatelessWidget {
  /// Membuat [AppCard].
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.space4),
    this.color,
    this.onTap,
    this.semanticsLabel,
    super.key,
  });

  /// Isi kartu.
  final Widget child;

  /// Padding di dalam kartu.
  final EdgeInsetsGeometry padding;

  /// Warna permukaan. Bawaan `surface`.
  final Color? color;

  /// Membuat seluruh kartu dapat diketuk.
  final VoidCallback? onTap;

  /// Label pembaca layar saat kartu dapat diketuk.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final body = Padding(padding: padding, child: child);
    return Material(
      color: color ?? colors.surface,
      shape: const PixelCornerBorder(),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? body
          : Semantics(
              button: true,
              label: semanticsLabel,
              child: InkWell(
                onTap: onTap,
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.pressed)
                      ? colors.surface2
                      : Colors.transparent,
                ),
                child: body,
              ),
            ),
    );
  }
}

/// Kartu daftar (`tk-list`): kartu tanpa padding berisi baris yang
/// dipisahkan garis `line` menjorok sejajar awal teks baris.
class AppListCard extends StatelessWidget {
  /// Membuat [AppListCard] dari [children] (biasanya `AppListRow`).
  const AppListCard({
    required this.children,
    this.dividerIndent = AppListCard.tileIndent,
    super.key,
  });

  /// Jorok garis pemisah untuk baris bertile ikon 40px (16 + 40 + 12).
  static const tileIndent = 68.0;

  /// Jorok garis pemisah untuk baris berikon 24px.
  static const iconIndent = 52.0;

  /// Jorok garis pemisah untuk baris tanpa ikon.
  static const plainIndent = 16.0;

  /// Baris-baris kartu.
  final List<Widget> children;

  /// Jarak garis pemisah dari tepi kiri.
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(indent: dividerIndent),
            children[i],
          ],
        ],
      ),
    );
  }
}
