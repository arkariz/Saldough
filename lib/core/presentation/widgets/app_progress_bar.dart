import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Status bar anggaran (komponen ProgressBar, ADR-034).
enum AppBarStatus {
  /// Di bawah 85%: isi `ink`, badge `positive` "Aman".
  safe,

  /// 85–100%: isi `warningFill`, badge `warning` "Hampir habis".
  nearlyOut,

  /// Di atas 100%: isi penuh `danger`, badge `danger` menyebut selisihnya.
  over,
}

/// Bar anggaran tersusun dari kotak 6px berjarak 2px, dengan penanda
/// seberapa jauh periode sudah berjalan (komponen ProgressBar, ADR-034).
///
/// Tinggi 10px di kartu, 6px dengan [thin] di baris pos. [pace] (0..1)
/// hanya untuk anggaran berperiode yang sedang berjalan. Bar tidak pernah
/// berdiri sendiri: pemakai menaruh angka "terpakai dari rencana" di
/// dekatnya. Dibaca pembaca layar sebagai persen terpakai.
class AppProgressBar extends StatelessWidget {
  /// Membuat [AppProgressBar] untuk rasio [value] (0.0 kosong, 1.0 = 100%,
  /// lebih dari 1.0 berarti lewat).
  const AppProgressBar({
    required this.value,
    this.pace,
    this.thin = false,
    super.key,
  });

  /// Rasio terpakai terhadap rencana.
  final double value;

  /// Rasio periode yang sudah berjalan, atau `null` tanpa penanda.
  final double? pace;

  /// Varian tipis (6px) untuk baris pos.
  final bool thin;

  /// Ambang "Hampir habis".
  static const nearlyOutThreshold = 0.85;

  /// Status untuk rasio [value]. Tepat 100% belum lewat (pos "selesai").
  static AppBarStatus statusFor(double value) {
    if (value > 1.0) return AppBarStatus.over;
    if (value >= nearlyOutThreshold) return AppBarStatus.nearlyOut;
    return AppBarStatus.safe;
  }

  /// Warna isi bar untuk rasio [value]; dipakai juga oleh teks dan badge
  /// pendampingnya supaya tidak menduplikasi ambang.
  static Color colorFor(BuildContext context, double value) {
    final colors = context.appColors;
    return switch (statusFor(value)) {
      AppBarStatus.safe => colors.ink,
      AppBarStatus.nearlyOut => colors.warningFill,
      AppBarStatus.over => colors.danger,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final height = thin ? 6.0 : 10.0;
    final percent = (value * 100).round();
    return Semantics(
      value: '$percent%',
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _BarPainter(
              value: value.clamp(0, 1).toDouble(),
              pace: pace?.clamp(0, 1).toDouble(),
              fill: colorFor(context, value),
              track: colors.track,
              paceColor: colors.ink,
              paceRing: colors.surface,
            ),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.value,
    required this.pace,
    required this.fill,
    required this.track,
    required this.paceColor,
    required this.paceRing,
  });

  final double value;
  final double? pace;
  final Color fill;
  final Color track;
  final Color paceColor;
  final Color paceRing;

  static const _square = 6.0;
  static const _step = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final filledWidth = size.width * value;
    final trackPaint = Paint()..color = track;
    final fillPaint = Paint()..color = fill;
    for (var x = 0.0; x < size.width; x += _step) {
      final width = (size.width - x).clamp(0, _square).toDouble();
      final square = Rect.fromLTWH(x, 0, width, size.height);
      canvas.drawRect(square, trackPaint);
      if (x < filledWidth) {
        canvas.drawRect(
          Rect.fromLTWH(
            x,
            0,
            (filledWidth - x).clamp(0, width).toDouble(),
            size.height,
          ),
          fillPaint,
        );
      }
    }
    if (pace case final p?) {
      final x = size.width * p;
      final overhang = size.height <= 6 ? 3.0 : 4.0;
      final marker = Rect.fromLTWH(
        x - 1,
        -overhang,
        2,
        size.height + overhang * 2,
      );
      canvas
        ..drawRect(marker.inflate(2), Paint()..color = paceRing)
        ..drawRect(marker, Paint()..color = paceColor);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.value != value ||
      old.pace != pace ||
      old.fill != fill ||
      old.track != track;
}
