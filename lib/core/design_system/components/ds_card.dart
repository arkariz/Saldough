import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Kartu tingkat `card`: putih, garis rambut, sudut 16, bayangan nyaris
/// tak terlihat. [onTap] membuatnya bisa diketuk (mengecil 0,99).
class DsCard extends StatelessWidget {
  /// Membuat kartu.
  const DsCard({required this.child, this.padding = const EdgeInsets.all(14), this.onTap, super.key});

  /// Isi.
  final Widget child;

  /// Padding dalam.
  final EdgeInsetsGeometry padding;

  /// Dipanggil saat kartu diketuk.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: context.ds.elevation.card.decoration(),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return DsPressable(onPressed: onTap, pressedScale: 0.99, builder: (_, _) => card);
  }
}

/// Kartu berisi daftar baris dengan pemisah garis rambut, tanpa padding.
class DsListCard extends StatelessWidget {
  /// Membuat kartu daftar.
  const DsListCard({required this.children, super.key});

  /// Baris-baris, biasanya `DsLedgerRow`.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tier = context.ds.elevation.card;
    final divider = context.ds.colors.outlineSubtle.withValues(alpha: 0.7);
    return DecoratedBox(
      decoration: tier.decoration(),
      child: ClipRRect(
        borderRadius: DsRadius.lgAll,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: divider),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
