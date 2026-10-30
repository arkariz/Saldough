import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_opacity.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Satu tab [DsNavBar].
@immutable
class DsNavItem {
  /// Membuat tab.
  const DsNavItem({required this.icon, required this.label, this.activeIcon});

  /// Ikon.
  final IconData icon;

  /// Ikon saat aktif; bawaan [icon].
  final IconData? activeIcon;

  /// Label.
  final String label;
}

/// Navigasi bawah: tab berlabel piksel dengan titik penanda tab aktif, dan
/// tombol Catat kotak hijau yang menonjol di tengah. Latar kanvas tembus
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
            child: _CenterAction(label: centerLabel, icon: centerIcon, onPressed: onCenterPressed),
          ),
        );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: c.surfaceCanvas.withValues(alpha: DsOpacity.chrome),
            border: Border(top: BorderSide(color: c.outlineSubtle)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap});

  final DsNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final color = active ? ds.colors.actionPrimary : ds.colors.textSecondary;
    return Semantics(
      selected: active,
      child: DsPressable(
        onPressed: onTap,
        pressedScale: 1,
        builder: (context, _) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? (item.activeIcon ?? item.icon) : item.icon, size: 21, color: color),
            const SizedBox(height: 2),
            Text(item.label, style: ds.typography.pixelCaption.copyWith(color: color), maxLines: 1),
            const SizedBox(height: 3),
            AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: DsMotion.standard,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: ds.colors.actionPrimary, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  const _CenterAction({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DsPressable(
      onPressed: onPressed,
      pressedScale: DsMotion.pressScaleTile,
      builder: (context, pressed) => OverflowBox(
        maxHeight: 84,
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: DsMotion.standard,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: pressed ? c.actionPrimaryPressed : c.actionPrimary,
                  borderRadius: DsRadius.lgAll,
                  boxShadow: [
                    BoxShadow(
                      color: c.actionPrimary.withValues(alpha: 0.25),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(icon, size: 24, color: c.onActionPrimary),
              ),
              const SizedBox(height: 4),
              Text(label, style: ds.typography.pixelCaption.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
