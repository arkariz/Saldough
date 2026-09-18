import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Bilah progres tersegmentasi ADR-015 — blok 8px berjarak 2px, bukan bar
/// melengkung kontinu. Dipakai Beranda, Anggaran, dan Ikhtisar Freelance
/// (tiga tempat yang sudah dikonfirmasi ADR-015 §7 memakainya).
///
/// Warnanya mengikuti [value] terhadap ambang semantik ADR-015: `income`
/// di bawah 70%, `pending` 70–100%, `overBudget` di atas 100%. ⚠ ADR-015
/// sendiri hanya menyebut ambang eksplisit "70–90%" untuk `pending` dan
/// "di atas 100%" untuk `overBudget`, tanpa menyebut 90–100% — di sini
/// `pending` diperpanjang sampai tepat di bawah 100% (bukan berhenti di
/// 90%) supaya seluruh rentang 0–100% punya warna, dan `overBudget` hanya
/// mulai persis saat lewat rencana. Tinjau ulang kalau pemilik
/// menginginkan potongan berbeda.
///
/// Dipakai HANYA di dalam subtree `PixelTheme` — sama seperti
/// [AppHardCard], warnanya baru bernilai ADR-015 kalau `PixelTheme`
/// terpasang di atasnya.
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
    if (value >= 1.0) return colors.overBudget;
    if (value >= 0.7) return colors.pending;
    return colors.income;
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
