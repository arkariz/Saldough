import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_opacity.dart';

/// Jenis nominal di [DsLedgerRow], menentukan warnanya.
enum DsLedgerKind {
  /// Pengeluaran: tinta biasa.
  expense,

  /// Pemasukan: hijau, termasuk judul.
  income,

  /// Transfer: tinta sekunder.
  transfer,
}

/// Baris transaksi: tile, judul + nominal piksel rata kanan, keterangan +
/// badge. Nominal tidak pernah terpotong; judul dan keterangan yang
/// mengalah.
class DsLedgerRow extends StatelessWidget {
  /// Membuat baris.
  const DsLedgerRow({
    required this.leading,
    required this.title,
    required this.amount,
    this.subtitle,
    this.badge,
    this.kind = DsLedgerKind.expense,
    this.onTap,
    super.key,
  });

  /// Tile ikon (`DsIconTile` ukuran md).
  final Widget leading;

  /// Judul transaksi.
  final String title;

  /// Nominal yang sudah diformat, termasuk tanda.
  final String amount;

  /// Keterangan ("Kafe Koma · Hari ini, 14:20").
  final String? subtitle;

  /// Badge kategori di kanan bawah.
  final Widget? badge;

  /// Jenis nominal.
  final DsLedgerKind kind;

  /// Dipanggil saat baris diketuk.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final amountColor = switch (kind) {
      DsLedgerKind.expense => c.textPrimary,
      DsLedgerKind.income => c.income,
      DsLedgerKind.transfer => c.textSecondary,
    };
    final titleColor = kind == DsLedgerKind.income ? c.income : c.textPrimary;

    Widget row({required bool pressed}) => AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: pressed ? c.surfaceHover.withValues(alpha: DsOpacity.rowPressed) : Colors.transparent,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, box) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: ds.typography.bodyMd.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontVariations: const [FontVariation.weight(600)],
                            color: titleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Nominal tidak pernah terpotong: mengecil dulu (maks.
                      // 60% lebar baris) bila sempit, baru judul yang mengalah.
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: box.maxWidth * 0.6),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(amount, style: ds.typography.pixelAmount.copyWith(color: amountColor)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (subtitle != null || badge != null) ...[
                  const SizedBox(height: 2),
                  LayoutBuilder(
                    builder: (context, box) => Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle ?? '',
                            style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Badge dibatasi 45% lebar baris supaya keterangan
                        // tetap terbaca di layar sempit.
                        if (badge != null) ...[
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: box.maxWidth * 0.45),
                            child: badge,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return row(pressed: false);
    return DsPressable(
      onPressed: onTap,
      pressedScale: 1,
      builder: (_, pressed) => row(pressed: pressed),
    );
  }
}
