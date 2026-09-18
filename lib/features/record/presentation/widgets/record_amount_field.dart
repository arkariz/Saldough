import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Mengubah [value] (rupiah, bukan sen) jadi teks berpemisah ribuan ala
/// Indonesia, mis. `5000000` -> `"5.000.000"`.
String _formatThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Membaca balik teks [RecordAmountField] (yang sudah berpemisah ribuan)
/// jadi `int` rupiah biasa, atau `null` kalau kosong/nol/negatif. Formulir
/// yang memakai widget ini wajib lewat sini, bukan `int.tryParse` langsung
/// pada teks yang belum dibersihkan dari titik pemisah.
int? parseRecordAmount(String text) {
  final digits = text.replaceAll('.', '');
  if (digits.isEmpty) return null;
  final value = int.tryParse(digits);
  return value == null || value <= 0 ? null : value;
}

/// Formatter yang menyisipkan pemisah ribuan `.` pada setiap perubahan.
///
/// Selalu menaruh kursor di akhir teks — penyederhanaan yang disengaja,
/// bukan kelalaian: field ini secara semantik rata kanan (nominal uang),
/// jadi mempertahankan posisi kursor di tengah string tidak berarti apa-apa
/// bagi pemakainya.
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) return TextEditingValue.empty;

    final formatted = _formatThousands(int.parse(digits));
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

/// Field nominal berpemisah ribuan, dengan pilihan cepat nominal umum.
///
/// Dipakai ketiga formulir CATAT, menggantikan `TextField` mentah dengan
/// `FilteringTextInputFormatter.digitsOnly` yang tidak memberi konfirmasi
/// visual besaran nominal sebelum dicatat.
class RecordAmountField extends StatelessWidget {
  /// Membuat [RecordAmountField].
  const RecordAmountField({
    required this.controller,
    required this.label,
    this.quickAmounts = const [],
    this.autofocus = false,
    this.onChanged,
    super.key,
  });

  /// Pengendali teks, berisi angka berpemisah ribuan.
  final TextEditingController controller;

  /// Label field.
  final String label;

  /// Nominal (rupiah, bukan sen) yang ditawarkan sebagai pilihan cepat.
  final List<int> quickAmounts;

  /// Fokus otomatis saat formulir dibuka.
  final bool autofocus;

  /// Dipanggil setiap teks berubah (ketikan maupun tap pilihan cepat) —
  /// pemanggil dapat memakainya untuk memicu `setState` yang menghitung
  /// ulang validitas formulir, mengikuti pola field lain di formulir ini.
  final VoidCallback? onChanged;

  void _addQuickAmount(int amount) {
    final current = parseRecordAmount(controller.text) ?? 0;
    final formatted = _formatThousands(current + amount);
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: TextInputType.number,
          inputFormatters: [_ThousandsSeparatorFormatter()],
          decoration: InputDecoration(prefixText: 'Rp', labelText: label),
          onChanged: (_) => onChanged?.call(),
        ),
        if (quickAmounts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final amount in quickAmounts)
                AppChip(label: '+Rp${_formatThousands(amount)}', onTap: () => _addQuickAmount(amount)),
            ],
          ),
        ],
      ],
    );
  }
}
