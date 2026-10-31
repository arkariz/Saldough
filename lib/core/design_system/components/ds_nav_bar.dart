import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_opacity.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Satu tab [DsNavBar].
@immutable
class DsNavItem {
  /// Membuat tab.
  const DsNavItem({required this.icon, required this.label, this.activeIcon, this.asset});

  /// Ikon.
  final IconData icon;

  /// Ikon saat aktif; bawaan [icon].
  final IconData? activeIcon;

  /// Ilustrasi SVG clay yang menggantikan [icon]: berwarna penuh saat aktif,
  /// dipudarkan saat tidak.
  final String? asset;

  /// Label.
  final String label;
}

/// Navigasi bawah: tab berlabel piksel dengan latar pil lembut di tab aktif,
/// dan tombol Catat bulat bergradasi hijau bertanda daun yang menonjol di
/// tengah (KT-DS6: satu-satunya elemen bertimbul). Latar kanvas tembus
/// pandang dengan blur dan garis rambut atas. Tinggi 64 + area aman.
class DsNavBar extends StatelessWidget {
  /// Membuat navigasi bawah.
  const DsNavBar({
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    required this.centerLabel,
    required this.onCenterPressed,
    this.centerIcon = Icons.add,
    this.centerSlot,
    this.onCenterLongPress,
    this.centerHint,
    this.centerWrapper,
    super.key,
  });

  /// Tab, tanpa tombol tengah.
  final List<DsNavItem> items;

  /// Indeks tab aktif di [items].
  final int currentIndex;

  /// Dipanggil dengan indeks tab yang diketuk.
  final ValueChanged<int> onSelected;

  /// Label tombol tengah ("Catat").
  final String centerLabel;

  /// Ikon tombol tengah.
  final IconData centerIcon;

  /// Dipanggil saat tombol tengah diketuk.
  final VoidCallback onCenterPressed;

  /// Dipanggil saat tombol tengah ditekan lama (mis. Catat lewat suara).
  final VoidCallback? onCenterLongPress;

  /// Petunjuk pembaca layar tombol tengah ("Tekan lama untuk suara").
  final String? centerHint;

  /// Pembungkus tombol tengah, mis. target sorot tur.
  final Widget Function(Widget button)? centerWrapper;

  /// Posisi tombol tengah di antara tab; bawaan di tengah (`items.length ~/ 2`).
  final int? centerSlot;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final slot = centerSlot ?? items.length ~/ 2;
    final children =
        <Widget>[
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _Tab(item: items[i], active: i == currentIndex, onTap: () => onSelected(i)),
            ),
        ]..insert(
          slot,
          Expanded(
            child: _CenterAction(
              label: centerLabel,
              icon: centerIcon,
              onPressed: onCenterPressed,
              onLongPress: onCenterLongPress,
              hint: centerHint,
              wrapper: centerWrapper,
            ),
          ),
        );

    // Zona 12px di atas bilah dipakai tombol tengah yang menonjol; latar
    // dan garis atas dimulai di bawahnya, jadi tombol tidak terpotong.
    return Stack(
      children: [
        Positioned.fill(
          top: _bump,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surfaceCanvas.withValues(alpha: DsOpacity.chrome),
                  border: Border(top: BorderSide(color: c.outlineSubtle)),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: SizedBox(
            height: 64 + _bump,
            child: Padding(
              padding: const EdgeInsets.only(top: _bump),
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ),
        ),
      ],
    );
  }

  /// Tinggi zona tonjolan tombol tengah di atas bilah.
  static const double _bump = 12;
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap});

  final DsNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final color = active ? c.actionPrimary : c.textSecondary;
    return Semantics(
      selected: active,
      button: true,
      child: DsPressable(
        onPressed: onTap,
        pressedScale: 0.95,
        builder: (context, _) => Center(
          child: AnimatedContainer(
            duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.standard,
            constraints: const BoxConstraints(minWidth: 56, minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: active ? c.incomeContainer.withValues(alpha: 0.8) : Colors.transparent,
              borderRadius: DsRadius.lgAll,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TabIcon(item: item, active: active, color: color),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    style: ds.typography.pixelCaption.copyWith(color: color, fontSize: 10),
                    maxLines: 1,
                    textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ikon tab: ilustrasi clay (pudar dan keabuan bila tidak aktif) atau ikon
/// biasa bila tab tidak punya aset.
class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.item, required this.active, required this.color});

  final DsNavItem item;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final asset = item.asset;
    if (asset == null) {
      return Icon(active ? (item.activeIcon ?? item.icon) : item.icon, size: 22, color: color);
    }
    final picture = SvgPicture.asset(asset, width: 28, height: 28);
    if (active) return picture;
    return Opacity(
      opacity: 0.6,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.55, 0.35, 0.1, 0, 0, //
          0.55, 0.35, 0.1, 0, 0,
          0.55, 0.35, 0.1, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: picture,
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  const _CenterAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.onLongPress,
    this.hint,
    this.wrapper,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final String? hint;
  final Widget Function(Widget button)? wrapper;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final button = Semantics(
      button: true,
      label: label,
      hint: hint,
      excludeSemantics: true,
      onLongPress: onLongPress,
      child: GestureDetector(
        key: const ValueKey('nav-catat'),
        behavior: HitTestBehavior.opaque,
        onLongPress: onLongPress,
        child: DsPressable(
          onPressed: onPressed,
          pressedScale: 0.9,
          builder: (context, pressed) => OverflowBox(
            maxHeight: 76,
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surfaceCard, width: 2),
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          c.actionPrimaryPressed,
                          if (pressed) c.actionPrimaryPressed else c.actionPrimary,
                          Color.lerp(c.actionPrimary, c.primaryFixed, 0.45)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(color: c.actionPrimary.withValues(alpha: 0.4), offset: const Offset(0, 6), blurRadius: 14),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Kilap clay di tepi atas.
                        Positioned(
                          top: 3,
                          left: 9,
                          right: 9,
                          height: 14,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: DsRadius.fullAll,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)],
                              ),
                            ),
                          ),
                        ),
                        Icon(icon, size: 28, color: c.onActionPrimary),
                        Positioned(
                          right: 9,
                          bottom: 7,
                          child: Icon(Icons.eco, size: 10, color: c.primaryFixed),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: ds.typography.pixelCaption.copyWith(color: c.textSecondary, fontSize: 10),
                      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return wrapper == null ? button : wrapper!(button);
  }
}
