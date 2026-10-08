import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';

/// Satu tujuan [AppNavBar].
typedef AppNavDestination = ({IconKey icon, String label});

/// Navigasi bawah design system (komponen NavBar, ADR-034): empat tujuan dan
/// tombol Catat di tengah (Beranda, Riwayat, [Catat], Rencana, Dompet).
///
/// Latar `surface` dengan garis `line` di atasnya (`shadow-bar`), tinggi
/// `size-navbar`. Tujuan aktif: pil `brandSoft` 56×32 berisi ikon terisi
/// `brandInk`, label `ink`; lainnya `ink2`. Tombol Catat kotak `brand`
/// bersudut piksel dengan bayangan piksel keras `brandDeep`, naik 24px dari
/// bar; [onRecordLongPress] membuka Catat pakai suara.
///
/// [recordWrapper] membungkus tombol Catat (mis. `SpotlightTarget`) tanpa
/// widget ini perlu tahu tur.
class AppNavBar extends StatelessWidget {
  /// Membuat [AppNavBar]. [destinations] berisi tepat empat tujuan; dua
  /// pertama di kiri tombol Catat, dua terakhir di kanan.
  const AppNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.recordLabel,
    required this.onRecord,
    this.recordHint,
    this.onRecordLongPress,
    this.recordWrapper,
    super.key,
  }) : assert(destinations.length == 4, 'AppNavBar butuh tepat empat tujuan');

  /// Empat tujuan, urut kiri ke kanan.
  final List<AppNavDestination> destinations;

  /// Indeks tujuan aktif (0..3).
  final int selectedIndex;

  /// Dipanggil dengan indeks tujuan yang diketuk.
  final ValueChanged<int> onSelected;

  /// Label di bawah tombol Catat.
  final String recordLabel;

  /// Petunjuk pembaca layar untuk tekan lama ("Tekan lama untuk ...").
  final String? recordHint;

  /// Ketuk tombol Catat.
  final VoidCallback onRecord;

  /// Tekan lama tombol Catat.
  final VoidCallback? onRecordLongPress;

  /// Pembungkus tombol Catat.
  final Widget Function(Widget button)? recordWrapper;

  /// Seberapa jauh tombol Catat naik di atas bar.
  static const catatRise = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final button = _CatatButton(
      label: recordLabel,
      hint: recordHint,
      onTap: onRecord,
      onLongPress: onRecordLongPress,
    );
    // Tombol Catat naik di atas bar. Supaya bagian yang naik tetap bisa
    // diketuk, tinggi widget ini mencakupnya: pita transparan [_rise] di atas
    // bar, dan isi halaman berhenti di atas pita itu.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: _rise + AppSize.navbar + bottomInset,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: AppSize.navbar + bottomInset,
            child: Material(
              color: colors.surface,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.line)),
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final i in [0, 1]) Expanded(child: _item(context, i)),
                      const Spacer(),
                      for (final i in [2, 3]) Expanded(child: _item(context, i)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: recordWrapper?.call(button) ?? button),
          ),
        ],
      ),
    );
  }

  /// Bagian tombol Catat yang berada di atas bar.
  static const double _rise = catatRise - AppSpacing.space2;

  Widget _item(BuildContext context, int index) {
    final colors = context.appColors;
    final destination = destinations[index];
    final selected = index == selectedIndex;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(index),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppDurations.fast,
                width: 56,
                height: 32,
                decoration: ShapeDecoration(
                  color: selected ? colors.brandSoft : colors.surface.withValues(alpha: 0),
                  shape: const PixelCornerBorder.small(),
                ),
                child: Center(
                  child: AppIcon(
                    destination.icon,
                    fill: selected,
                    color: selected ? colors.brandInk : colors.ink2,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              // Label navigasi dibatasi 1,3× ukuran teks sistem supaya bar
              // setinggi `size-navbar` tetap utuh di teks 200% (pola yang sama
              // dengan NavigationBar Material).
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.3),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? colors.ink : colors.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatatButton extends StatefulWidget {
  const _CatatButton({
    required this.label,
    required this.onTap,
    this.hint,
    this.onLongPress,
  });

  final String label;
  final String? hint;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_CatatButton> createState() => _CatatButtonState();
}

class _CatatButtonState extends State<_CatatButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: widget.label,
      hint: widget.hint,
      excludeSemantics: true,
      onLongPress: widget.onLongPress,
      child: GestureDetector(
        key: const ValueKey('nav-catat'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bayangan piksel keras (`shadow-pixel`, 0 4px 0 brandDeep): satu-
            // satunya sisa gaya bayangan lama. Ditekan, tombol turun menutup
            // bayangannya.
            SizedBox(
              width: AppSize.catat,
              height: AppSize.catat + AppSize.pixelStep,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: AppSize.catat,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: colors.brandDeep,
                        shape: const PixelCornerBorder(),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: AppDurations.fast,
                    left: 0,
                    right: 0,
                    top: _pressed ? AppSize.pixelStep : 0,
                    height: AppSize.catat,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: _pressed ? colors.brandPressed : colors.brand,
                        shape: const PixelCornerBorder(),
                      ),
                      child: Center(
                        child: AppIcon(
                          IconKey.record,
                          size: 30,
                          color: colors.onBrand,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              widget.label,
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.3),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
