import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/rupiah_input.dart';

/// Memformat [rupiah] (rupiah, bukan sen) dengan pemisah ribuan, untuk
/// mengisi awal field saat menyunting transaksi tersimpan.
String formatRecordAmount(int rupiah) => formatRupiahInput(rupiah);

/// Membaca balik teks [RecordAmountField] jadi `int` rupiah, atau `null`
/// kalau kosong/nol/negatif. Lihat `parseRupiahInput`.
int? parseRecordAmount(String text) => parseRupiahInput(text);

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
    _setText(formatRupiahInput(current + amount));
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
                    inputFormatters: [RupiahInputFormatter()],
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
                AppQuickChip(label: formatRupiahShort(amount), onTap: () => _addQuickAmount(amount)),
              AppQuickChip(
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
