import 'package:flutter/material.dart';

/// Ilustrasi pemilik untuk langkah onboarding (`assets/illustration/`).
///
/// Tiap berkas punya margin transparan yang lebar (maskot hanya di satu sisi
/// atau di separuh bawah), jadi [crop] memotongnya saat ditampilkan --
/// pecahan `left`, `top`, `width`, `height` dari ukuran berkas -- tanpa
/// mengubah berkasnya. Dibaca layar sebagai hiasan, bukan isi.
class OnboardingArt extends StatelessWidget {
  /// Membuat [OnboardingArt].
  const OnboardingArt(this.asset, {this.height = 120, this.crop = const Rect.fromLTWH(0, 0, 1, 1), super.key});

  /// Berkas ilustrasi.
  final String asset;

  /// Tinggi tampil.
  final double height;

  /// Bagian berkas yang ditampilkan, pecahan 0..1.
  final Rect crop;

  @override
  Widget build(BuildContext context) {
    // `Align` dengan faktor lebar/tinggi memotong ke [crop]; titik sejajarnya
    // dihitung supaya sisi kiri/atas bagian itu jatuh di tepi.
    double axis(double start, double size) => size >= 1 ? 0 : 2 * start / (1 - size) - 1;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: FittedBox(
          child: ClipRect(
            child: Align(
              alignment: Alignment(axis(crop.left, crop.width), axis(crop.top, crop.height)),
              widthFactor: crop.width,
              heightFactor: crop.height,
              child: Image.asset(asset, filterQuality: FilterQuality.none),
            ),
          ),
        ),
      ),
    );
  }
}
