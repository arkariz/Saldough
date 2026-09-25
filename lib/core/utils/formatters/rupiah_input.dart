import 'package:flutter/services.dart';

/// Memformat [rupiah] (rupiah, bukan sen) dengan pemisah ribuan ala
/// Indonesia, mis. `5000000` -> `"5.000.000"`. Dipakai mengisi awal kolom
/// nominal saat menyunting data tersimpan.
String formatRupiahInput(int rupiah) {
  final digits = rupiah.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Membaca balik teks kolom nominal (yang sudah berpemisah ribuan) jadi `int`
/// rupiah biasa, atau `null` kalau kosong/nol/negatif. Kolom nominal wajib
/// lewat sini, bukan `int.tryParse` langsung pada teks yang belum dibersihkan
/// dari titik pemisah.
int? parseRupiahInput(String text) {
  final digits = text.replaceAll('.', '');
  if (digits.isEmpty) return null;
  final value = int.tryParse(digits);
  return value == null || value <= 0 ? null : value;
}

/// Formatter yang menyisipkan pemisah ribuan `.` pada setiap perubahan.
///
/// Selalu menaruh kursor di akhir teks — penyederhanaan yang disengaja,
/// bukan kelalaian: kolom ini secara semantik rata kanan (nominal uang),
/// jadi mempertahankan posisi kursor di tengah string tidak berarti apa-apa
/// bagi pemakainya.
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) return TextEditingValue.empty;

    final formatted = formatRupiahInput(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Label ringkas pilihan cepat: `10000` -> `+10rb`, `5000000` -> `+5jt`;
/// nominal yang tidak bulat ribu/juta ditulis penuh (`+1.500`).
String formatRupiahShort(int rupiah) {
  if (rupiah >= 1000000 && rupiah % 1000000 == 0) return '+${rupiah ~/ 1000000}jt';
  if (rupiah >= 1000 && rupiah % 1000 == 0) return '+${rupiah ~/ 1000}rb';
  return '+${formatRupiahInput(rupiah)}';
}
