import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';

/// Label kolom formulir: judul 14/600 di kiri, [hint] kecil di kanan. `Wrap`
/// supaya [hint] turun baris, bukan meluap, pada teks besar.
///
/// Judul bagian di atas kartu memakai `DsSectionHeader`.
class AppSectionLabel extends StatelessWidget {
  /// Membuat [AppSectionLabel].
  const AppSectionLabel(this.label, {this.hint, super.key});

  /// Label kolom.
  final String label;

  /// Keterangan kecil di ujung kanan.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 2,
        children: [
          Text(label, style: ds.typography.labelMd.copyWith(fontSize: 14, color: ds.colors.textPrimary)),
          if (hint != null) Text(hint!, style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary)),
        ],
      ),
    );
  }
}
