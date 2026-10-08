import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/kind_surfaces.dart';
import 'package:saldough/core/theme/theme.dart';

/// Judul bagian formulir: label di kiri, [hint] kecil di
/// kanan. `Wrap` supaya [hint] turun baris, bukan meluap, pada teks besar.
///
/// Dipakai formulir CATAT dan formulir dompet, supaya judul bagian di seluruh
/// formulir tampil seragam.
class AppSectionLabel extends StatelessWidget {
  /// Membuat [AppSectionLabel].
  const AppSectionLabel(this.label, {this.hint, super.key});

  /// Judul bagian.
  final String label;

  /// Keterangan kecil di ujung kanan.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.space2,
          runSpacing: 2,
          children: [
            Text(label.toUpperCase(), style: transactionLabelStyle(context, color: colors.ink)),
            if (hint != null)
              Text(
                hint!,
                style: transactionLabelStyle(context, color: colors.ink2).copyWith(fontWeight: FontWeight.w400),
              ),
          ],
        ),
      ),
    );
  }
}
