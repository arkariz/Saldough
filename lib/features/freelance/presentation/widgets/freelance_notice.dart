import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Kartu aturan freelance: judul kecil dan satu paragraf. Dipakai untuk
/// menyatakan bahwa kerja selesai bukan uang diterima, dan bahwa mencatat
/// pembayaran bukan pembayaran yang dijalankan aplikasi (FR-FRL-004).
class FreelanceNotice extends StatelessWidget {
  /// Membuat [FreelanceNotice].
  const FreelanceNotice({required this.title, required this.body, this.color, super.key});

  /// Judul kecil.
  final String title;

  /// Isi.
  final String body;

  /// Warna aksen; bawaan warna tertunda.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ink = color ?? colors.pending;
    return TransactionSlab(
      color: colors.tinted(ink, 0.1),
      shadow: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 6, height: 40, color: ink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: transactionLabelStyle(context, color: ink)),
                const SizedBox(height: 2),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
