import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Memformat [rupiah] (rupiah, bukan sen) dengan pemisah ribuan, untuk
/// mengisi awal field saat menyunting transaksi tersimpan.
String formatRecordAmount(int rupiah) => _formatThousands(rupiah);

/// Teks berpemisah ribuan ala Indonesia, mis. `5000000` -> `"5.000.000"`.
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
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Label ringkas pilihan cepat: `10000` -> `+10rb`, `5000000` -> `+5jt`;
/// nominal yang tidak bulat ribu/juta ditulis penuh.
String _quickLabel(int rupiah) {
  if (rupiah >= 1000000 && rupiah % 1000000 == 0) return '+${rupiah ~/ 1000000}jt';
  if (rupiah >= 1000 && rupiah % 1000 == 0) return '+${rupiah ~/ 1000}rb';
  return '+${_formatThousands(rupiah)}';
}

/// Kartu nominal berpemisah ribuan, dengan pilihan cepat nominal umum
/// (rujukan visual: `pixel_kas_catat_pengeluaran` bagian "Nominal").
///
/// Dipakai ketiga formulir CATAT. Kop kartu memuat label dan penanda jenis
/// berwarna ("Uang Keluar"); di bawahnya kotak angka besar dengan awalan "Rp";
/// lalu chip `+10rb` dst. dan "Bersihkan".
class RecordAmountField extends StatelessWidget {
  /// Membuat [RecordAmountField].
  const RecordAmountField({
    required this.controller,
    required this.label,
    required this.kind,
    this.quickAmounts = const [],
    this.autofocus = false,
    this.onChanged,
    super.key,
  });

  /// Pengendali teks, berisi angka berpemisah ribuan.
  final TextEditingController controller;

  /// Judul kartu, mis. "Nominal Pengeluaran".
  final String label;

  /// Jenis transaksi: mewarnai penanda, awalan "Rp", dan kursor.
  final TransactionKind kind;

  /// Nominal (rupiah, bukan sen) yang ditawarkan sebagai pilihan cepat.
  final List<int> quickAmounts;

  /// Fokus otomatis saat formulir dibuka.
  final bool autofocus;

  /// Dipanggil setiap teks berubah (ketikan maupun tap pilihan cepat) --
  /// pemanggil dapat memakainya untuk memicu `setState` yang menghitung
  /// ulang validitas formulir, mengikuti pola field lain di formulir ini.
  final VoidCallback? onChanged;

  void _setText(String formatted) {
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    onChanged?.call();
  }

  void _addQuickAmount(int amount) {
    final current = parseRecordAmount(controller.text) ?? 0;
    _setText(_formatThousands(current + amount));
  }

  String get _pill => switch (kind) {
    TransactionKind.income => t.record.incomeBadge,
    TransactionKind.expense => t.record.expenseBadge,
    TransactionKind.transfer => t.record.transferBadge,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ink = colors.kindInk(kind);
    final bigStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 30, fontWeight: FontWeight.w700);
    return TransactionSlab(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `Wrap`: label dan penanda jenis turun baris pada teks besar.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: 2,
            children: [
              Text(label.toUpperCase(), style: transactionLabelStyle(context, color: colors.textMuted)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(_pill.toUpperCase(), style: transactionLabelStyle(context, color: ink)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Text('Rp', style: PixelTypography.tabularMono(context, fontSize: 16, color: ink)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: autofocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsSeparatorFormatter()],
                    cursorColor: ink,
                    style: bigStyle,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      hintText: '0',
                      hintStyle: bigStyle?.copyWith(color: colors.textMuted.withValues(alpha: 0.5)),
                    ),
                    onChanged: (_) => onChanged?.call(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final amount in quickAmounts)
                _QuickChip(label: _quickLabel(amount), onTap: () => _addQuickAmount(amount)),
              _QuickChip(
                label: t.record.clearAmountAction,
                color: colors.tinted(colors.pending, 0.22),
                onTap: () => _setText(''),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap, this.color});

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
        // `Center(widthFactor: 1)`, BUKAN `Container(alignment: center)`:
        // `alignment` membuat Container mengisi seluruh lebar yang ditawarkan
        // `Wrap`, sehingga tiap chip melebar penuh dan bertumpuk vertikal.
        child: DecoratedBox(
          decoration: BoxDecoration(color: color ?? colors.surfaceMid, borderRadius: BorderRadius.circular(8)),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(label, style: transactionLabelStyle(context, color: colors.textPrimary)),
            ),
          ),
        ),
      ),
    );
  }
}
