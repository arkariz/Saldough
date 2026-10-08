import 'package:flutter/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Sudut piksel design system (ADR-034): tiap sudut dipotong tangga dua
/// langkah selebar [step], padanan `clip-path` `.tk-*` di `bundle.css`.
///
/// [AppSize.pixelStep] (4px) untuk kartu, daftar, banner, kartu saldo,
/// snackbar, dialog, dan tombol Catat; [AppSize.pixelStepSm] (2px) untuk
/// tombol, chip, badge, tile ikon, segmen, tombol keypad, dan kolom input.
/// Tanpa garis tepi kecuali [side] diisi (kolom input).
class PixelCornerBorder extends OutlinedBorder {
  /// Membuat [PixelCornerBorder] dengan langkah [step].
  const PixelCornerBorder({this.step = AppSize.pixelStep, super.side});

  /// Langkah tangga sudut kecil (`pixel-step-sm`).
  const PixelCornerBorder.small({BorderSide side = BorderSide.none})
    : this(step: AppSize.pixelStepSm, side: side);

  /// Lebar satu langkah tangga.
  final double step;

  /// Jalur bersudut tangga untuk [rect]: dua langkah [u] di tiap sudut.
  static Path pathFor(Rect rect, double u) {
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    return Path()
      ..moveTo(l, t + 2 * u)
      ..lineTo(l + u, t + 2 * u)
      ..lineTo(l + u, t + u)
      ..lineTo(l + 2 * u, t + u)
      ..lineTo(l + 2 * u, t)
      ..lineTo(r - 2 * u, t)
      ..lineTo(r - 2 * u, t + u)
      ..lineTo(r - u, t + u)
      ..lineTo(r - u, t + 2 * u)
      ..lineTo(r, t + 2 * u)
      ..lineTo(r, b - 2 * u)
      ..lineTo(r - u, b - 2 * u)
      ..lineTo(r - u, b - u)
      ..lineTo(r - 2 * u, b - u)
      ..lineTo(r - 2 * u, b)
      ..lineTo(l + 2 * u, b)
      ..lineTo(l + 2 * u, b - u)
      ..lineTo(l + u, b - u)
      ..lineTo(l + u, b - 2 * u)
      ..lineTo(l, b - 2 * u)
      ..close();
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      pathFor(rect, step);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      pathFor(rect.deflate(side.strokeInset), step);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    final inset = side.strokeInset / 2;
    canvas.drawPath(pathFor(rect.deflate(inset), step), side.toPaint());
  }

  @override
  PixelCornerBorder copyWith({BorderSide? side, double? step}) =>
      PixelCornerBorder(step: step ?? this.step, side: side ?? this.side);

  @override
  ShapeBorder scale(double t) =>
      PixelCornerBorder(step: step * t, side: side.scale(t));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is PixelCornerBorder) {
      return PixelCornerBorder(
        step: _lerp(a.step, step, t),
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is PixelCornerBorder) {
      return PixelCornerBorder(
        step: _lerp(step, b.step, t),
        side: BorderSide.lerp(side, b.side, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is PixelCornerBorder && other.step == step && other.side == side;

  @override
  int get hashCode => Object.hash(step, side);

  @override
  String toString() => 'PixelCornerBorder(step: $step, side: $side)';
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
