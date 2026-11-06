import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';

/// Nada [FreelanceNotice].
enum FreelanceNoticeTone {
  /// Kuning lembut: kerja selesai bukan uang diterima (bawaan).
  warning,

  /// Hijau lembut: uang sudah diterima.
  positive,
}

/// Kartu aturan freelance (rupa v2): tile ikon, judul kecil, dan satu
/// paragraf. Dipakai untuk menyatakan bahwa kerja selesai bukan uang
/// diterima, dan bahwa mencatat pembayaran bukan pembayaran yang dijalankan
/// aplikasi (FR-FRL-004).
class FreelanceNotice extends StatelessWidget {
  /// Membuat [FreelanceNotice].
  const FreelanceNotice({required this.title, required this.body, this.tone = FreelanceNoticeTone.warning, super.key});

  /// Judul kecil.
  final String title;

  /// Isi.
  final String body;

  /// Nada.
  final FreelanceNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final (background, ink) = switch (tone) {
      FreelanceNoticeTone.warning => (c.warningContainer, c.onWarningContainer),
      FreelanceNoticeTone.positive => (c.incomeContainer, c.onIncomeContainer),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background.withValues(alpha: 0.6), borderRadius: DsRadius.lgAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ds.typography.titleMd.copyWith(fontSize: 14, color: ink)),
                const SizedBox(height: 2),
                Text(body, style: ds.typography.bodySm.copyWith(color: c.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
