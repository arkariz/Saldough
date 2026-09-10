/// Mengubah nominal bertipe `int` satuan sen menjadi teks Rupiah.
///
/// Uang selalu disimpan dan dihitung dalam sen (lihat DOMAIN_MODEL.md dan
/// aturan arsitektur), dan pembulatan ke rupiah hanya terjadi di sini, saat
/// menampilkan — tidak pernah lebih awal. Memenuhi NFR-ACC-001.
abstract final class AppMoneyFormatter {
  AppMoneyFormatter._();

  /// Memformat [sen] menjadi teks `"Rp1.234.567"`, atau `"−Rp1.234.567"`
  /// untuk nilai negatif (tanda minus U+2212, bukan tanda hubung).
  ///
  /// Pembulatan setengah ke atas dilakukan dengan aritmatika bilangan bulat
  /// murni lewat [_floorDiv] — tidak pernah lewat `double`, supaya tidak ada
  /// galat presisi mengambang pada nominal besar.
  ///
  /// ⚠ `~/` bawaan Dart MEMOTONG ke nol (truncating), bukan pembagian
  /// lantai — `-7 ~/ 2` menghasilkan `-3`, bukan `-4`. Memakainya langsung
  /// untuk pembulatan setengah ke atas akan salah untuk nilai negatif
  /// (dibuktikan lewat `dart run` sebelum kode ini ditulis). [_floorDiv]
  /// mengoreksi ini.
  static String format(int sen) {
    final rupiah = _floorDiv(sen + 50, 100);
    final isNegative = rupiah < 0;
    final grouped = _groupThousands(rupiah.abs());
    return isNegative ? '−Rp$grouped' : 'Rp$grouped';
  }

  /// Pembagian lantai murni bilangan bulat untuk pembagi [b] positif.
  static int _floorDiv(int a, int b) {
    final q = a ~/ b;
    final r = a - q * b;
    return r != 0 && (r < 0) != (b < 0) ? q - 1 : q;
  }

  static String _groupThousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
