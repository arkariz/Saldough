import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_category_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_date_field.dart';
import 'package:saldough/features/record/presentation/widgets/wallet_picker_field.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Nominal cepat yang ditawarkan formulir pemasukan (rupiah, bukan sen) --
/// mengikuti pola pilihan cepat yang sungguhan terpasang di rujukan visual
/// `pixel_kas_catat_pemasukan`.
const _quickAmounts = [500000, 1000000, 5000000];

/// Saran kategori pemasukan yang sering dipakai.
List<String> _categorySuggestions() => [
      t.record.categorySuggestionSalary,
      t.record.categorySuggestionBonus,
      t.record.categorySuggestionSales,
      t.record.categorySuggestionGift,
    ];

// `IconKey` belum punya kunci per-kategori pemasukan (Gaji/Bonus/Penjualan/
// Hadiah) -- `IconKey.income` generik dipakai sebagai placeholder untuk
// semuanya sampai daftar kategori pemasukan final diputuskan pemilik,
// mengikuti pola yang sama seperti catatan `Wallet.iconKey` di
// `wallet_picker_field.dart`.
List<IconKey?> _categoryIcons() => const [IconKey.income, IconKey.income, IconKey.income, IconKey.income];

/// Formulir catat pemasukan (FR-TXN-001) — satu layar, tanpa berpindah
/// halaman (NFR-UX-001). Mengembalikan [IncomeRecorded] lewat
/// `Navigator.pop` saat disimpan, atau `BackToChoice` lewat tombol kembali;
/// `AppShellPage` yang menafsirkan hasilnya, mengikuti pola
/// `IncomeSourceEditSheet` yang sudah ada.
class IncomeFormSheet extends StatefulWidget {
  /// Membuat [IncomeFormSheet] dengan [wallets] sebagai pilihan tujuan.
  const IncomeFormSheet({required this.wallets, super.key});

  /// Dompet aktif yang bisa dipilih sebagai tujuan.
  final List<Wallet> wallets;

  @override
  State<IncomeFormSheet> createState() => _IncomeFormSheetState();
}

class _IncomeFormSheetState extends State<IncomeFormSheet> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  String? _walletId;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? get _amountSen {
    final rupiah = parseRecordAmount(_amountController.text);
    return rupiah == null ? null : rupiah * 100;
  }

  bool get _canSubmit => _amountSen != null && _walletId != null;

  void _submit() {
    final amount = _amountSen;
    final walletId = _walletId;
    if (amount == null || walletId == null) return;
    Navigator.of(context).pop(
      IncomeRecorded(
        walletId: walletId,
        amount: amount,
        date: _date,
        note: _noteController.text.trim(),
        categoryKey: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(const BackToChoice()),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(t.record.incomeAction, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppHardCard(
              child:RecordAmountField(
                controller: _amountController,
                label: t.record.amountFieldHint,
                quickAmounts: _quickAmounts,
                autofocus: true,
                onChanged: () => setState(() {}),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            WalletPickerField(
              label: t.record.toWalletFieldLabel,
              wallets: widget.wallets,
              selectedId: _walletId,
              onSelected: (id) => setState(() => _walletId = id),
              previewAmountSen: _amountSen,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppHardCard(
              child:RecordDateField(date: _date, onChanged: (date) => setState(() => _date = date)),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppHardCard(
              child:RecordCategoryField(
                controller: _categoryController,
                suggestions: _categorySuggestions(),
                icons: _categoryIcons(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppHardCard(
              child:TextField(
                controller: _noteController,
                decoration: InputDecoration(labelText: t.record.noteFieldHint),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: t.record.incomeAction, onPressed: _canSubmit ? _submit : null),
          ],
        ),
      ),
    );
  }
}
