import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_category_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_date_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_frame.dart';
import 'package:saldough/features/record/presentation/widgets/record_note_field.dart';
import 'package:saldough/features/record/presentation/widgets/wallet_select_field.dart';
import 'package:saldough/shared/transaction/transaction.dart';
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
  t.record.categorySuggestionInvestment,
];

/// Formulir catat pemasukan (FR-TXN-001) — satu layar, tanpa berpindah
/// halaman (NFR-UX-001). Mengembalikan [IncomeRecorded] lewat
/// `Navigator.pop` saat disimpan, atau `BackToChoice` lewat tombol kembali;
/// `AppShellPage` yang menafsirkan hasilnya, mengikuti pola
/// `IncomeSourceEditSheet` yang sudah ada. Tata letaknya mengikuti rujukan
/// visual `pixel_kas_catat_pemasukan`.
class IncomeFormSheet extends StatefulWidget {
  /// Membuat [IncomeFormSheet] dengan [wallets] sebagai pilihan tujuan.
  const IncomeFormSheet({required this.wallets, this.initial, super.key});

  /// Dompet aktif yang bisa dipilih sebagai tujuan.
  final List<Wallet> wallets;

  /// Transaksi yang disunting. `null` = mode CATAT (transaksi baru). Kalau
  /// terisi, formulir terisi awal, tombol berjudul "Simpan Perubahan", dan
  /// tombol kembali hanya menutup lembar (tidak ada lembar pilihan CATAT
  /// untuk kembali). Hasil yang dikembalikan sama seperti mode CATAT.
  final IncomeTransaction? initial;

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
  void initState() {
    super.initState();
    final tx = widget.initial;
    if (tx == null) return;
    _amountController.text = formatRecordAmount(tx.amount ~/ 100);
    _date = tx.date;
    _noteController.text = tx.note;
    _walletId = tx.walletId;
    _categoryController.text = tx.categoryKey ?? '';
  }

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

  Wallet? get _wallet {
    for (final wallet in widget.wallets) {
      if (wallet.id == _walletId) return wallet;
    }
    return null;
  }

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
    final editing = widget.initial != null;
    final wallet = _wallet;
    final amount = _amountSen;
    return RecordFormFrame(
      kind: TransactionKind.income,
      title: editing ? t.transaction.editSheetTitle : t.record.incomeAction,
      isEditing: editing,
      onBack: () => Navigator.of(context).pop(editing ? null : const BackToChoice()),
      submitLabel: editing ? t.transaction.saveChangesAction : t.record.incomeAction,
      onSubmit: _canSubmit ? _submit : null,
      children: [
        RecordAmountField(
          controller: _amountController,
          label: t.record.amountLabelIncome,
          kind: TransactionKind.income,
          quickAmounts: _quickAmounts,
          autofocus: true,
          onChanged: () => setState(() {}),
        ),
        RecordCategoryField(
          controller: _categoryController,
          suggestions: _categorySuggestions(),
          kind: TransactionKind.income,
        ),
        WalletSelectField(
          label: t.record.toWalletFieldLabel,
          wallets: widget.wallets,
          selectedId: _walletId,
          onSelected: (id) => setState(() => _walletId = id),
          previewAmountSen: amount,
        ),
        RecordDateField(
          date: _date,
          kind: TransactionKind.income,
          onChanged: (date) => setState(() => _date = date),
        ),
        RecordNoteField(controller: _noteController, kind: TransactionKind.income),
        if (_canSubmit && wallet != null && amount != null)
          RecordSummaryCard(
            kind: TransactionKind.income,
            children: [
              Text(
                t.record.incomeSummary(wallet: wallet.name, amount: AppMoneyFormatter.format(amount)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
      ],
    );
  }
}
