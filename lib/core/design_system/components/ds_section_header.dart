import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';

/// Kepala bagian: ikon + judul, tautan opsional "Semua ›" di kanan.
class DsSectionHeader extends StatelessWidget {
  /// Membuat kepala bagian.
  const DsSectionHeader({required this.title, this.icon, this.actionLabel, this.onAction, super.key});

  /// Judul bagian.
  final String title;

  /// Ikon 18px di depan judul.
  final IconData? icon;

  /// Teks tautan di kanan ("Semua").
  final String? actionLabel;

  /// Dipanggil saat tautan diketuk.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return LayoutBuilder(
      builder: (context, box) => Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: c.actionPrimary),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: ds.typography.titleMd.copyWith(fontSize: 15), overflow: TextOverflow.ellipsis),
            ),
          ),
          // Tautan menempel di tepi kanan; selebar isinya, paling lebar 40%.
          if (actionLabel != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * 0.4),
              child: DsPressable(
                onPressed: onAction,
                builder: (context, _) => ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          actionLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ds.typography.pixelLabel.copyWith(color: c.actionPrimary),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 13, color: c.actionPrimary),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
