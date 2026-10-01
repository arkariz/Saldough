import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Bilah progres tersegmentasi ADR-015 — blok 8px berjarak 2px, bukan bar
/// melengkung kontinu. Dipakai Beranda, Anggaran, dan Ikhtisar Freelance
/// (tiga tempat yang sudah dikonfirmasi ADR-015 §7 memakainya).
///
/// Warnanya mengikuti [value] terhadap ambang semantik ADR-020 §3.1 (merevisi
/// ADR-016 baris 136 "belum diputuskan"): NETRAL (`textPrimary`) di bawah
/// 70%, `pending` (amber) 70–100% (termasuk tepat 100%), `overBudget` (merah)
/// di atas 100%. ⚠ Sebelumnya sisi sehat memakai `income` (hijau) --
/// diganti supaya hijau tetap khusus uang masuk (ADR-016 "satu peran, satu
/// warna"), bukan berarti ganda "sehat" DAN "pemasukan". `pending`
/// diperpanjang sampai tepat di bawah 100% (bukan berhenti di 90% seperti
/// disebut ADR-015) supaya seluruh rentang 0–100% punya warna, dan
/// `overBudget` hanya mulai persis saat lewat rencana.
class AppSegmentedProgressBar extends StatelessWidget {
  /// Membuat [AppSegmentedProgressBar] untuk rasio [value] (0.0 = kosong,
  /// 1.0 = 100%, boleh lebih dari 1.0 untuk menyatakan lewat anggaran).
  const AppSegmentedProgressBar({
    required this.value,
    this.segmentCount = 10,
    this.segmentWidth = 8,
    this.segmentHeight = 8,
    this.gap = 2,
    super.key,
  });

  /// Rasio progres, 0.0–1.0 (atau lebih untuk lewat anggaran).
  final double value;

  /// Jumlah segmen penuh bilah — bawaan 10, tiap segmen mewakili 10%.
  final int segmentCount;

  /// Lebar tiap segmen, piksel. Bawaan 8px sesuai ADR-015.
  final double segmentWidth;

  /// Tinggi tiap segmen, piksel.
  final double segmentHeight;

  /// Jarak antar segmen, piksel. Bawaan 2px sesuai ADR-015.
  final double gap;

  /// Warna segmen terisi untuk rasio [value], mengikuti ambang semantik
  /// ADR-015. Diekspos `static` supaya legenda/label di luar bilah (mis.
  /// teks persentase) bisa memakai warna yang sama tanpa menduplikasi
  /// logikanya.
  static Color colorFor(BuildContext context, double value) {
    final colors = context.appColors;
    // `>` bukan `>=`: tepat 100% adalah pos "selesai" (terpakai sama dengan
    // rencana), bukan "lewat anggaran" -- lihat `BudgetItemStatus`.
    if (value > 1.0) return colors.overBudget;
    if (value >= 0.7) return colors.pending;
    return colors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fillColor = colorFor(context, value);
    final filledSegments = (value.clamp(0.0, 1.0) * segmentCount).round();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < segmentCount; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Container(
            width: segmentWidth,
            height: segmentHeight,
            decoration: BoxDecoration(
              color: i < filledSegments ? fillColor : colors.textMuted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ],
    );
  }
}
