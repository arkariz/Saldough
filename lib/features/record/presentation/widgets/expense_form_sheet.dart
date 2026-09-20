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

/// Nominal cepat yang ditawarkan formulir pengeluaran (rupiah, bukan sen).
const _quickAmounts = [10000, 50000, 100000];

/// Saran kategori pengeluaran yang sering dipakai.
List<String> _categorySuggestions() => [
  t.record.categorySuggestionFood,
  t.record.categorySuggestionShopping,
  t.record.categorySuggestionTransport,
  t.record.categorySuggestionBills,
  t.record.categorySuggestionEntertainment,
];

/// Formulir catat pengeluaran (FR-TXN-002) — satu layar, tanpa berpindah
/// halaman (NFR-UX-001). Mengembalikan [ExpenseRecorded] lewat
/// `Navigator.pop` saat disimpan, atau `BackToChoice` lewat tombol kembali.
/// Tata letaknya mengikuti rujukan visual `pixel_kas_catat_pengeluaran`.
///
/// ⚠ Tautan ke pos anggaran (bagian FR-TXN-002 yang menyebut "tautan
/// opsional ke satu pos anggaran", kartu "Alokasikan ke Anggaran Bulanan?"
/// di rujukan visual) belum ada di sini — `Budget` belum dibangun sampai
/// Fase 4. Tautan itu ditambahkan di T-4.4, bukan ditampilkan kosong
/// sekarang, mengikuti pola yang sama seperti baris anggaran di layar rincian
/// transaksi (T-2.11). Elemen gamifikasi rujukan ("LVL +10 EXP") tidak
/// dibangun: bukan bagian kebutuhan produk.
class ExpenseFormSheet extends StatefulWidget {
  /// Membuat [ExpenseFormSheet] dengan [wallets] sebagai pilihan asal.
  const ExpenseFormSheet({required this.wallets, this.initial, super.key});

  /// Dompet aktif yang bisa dipilih sebagai asal.
  final List<Wallet> wallets;

  /// Transaksi yang disunting. `null` = mode CATAT (transaksi baru). Kalau
  /// terisi, formulir terisi awal, tombol berjudul "Simpan Perubahan", dan
  /// tombol kembali hanya menutup lembar (tidak ada lembar pilihan CATAT
  /// untuk kembali). Hasil yang dikembalikan sama seperti mode CATAT.
  final ExpenseTransaction? initial;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
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
      ExpenseRecorded(
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
      kind: TransactionKind.expense,
      title: editing ? t.transaction.editSheetTitle : t.record.expenseAction,
      isEditing: editing,
      onBack: () => Navigator.of(context).pop(editing ? null : const BackToChoice()),
      notice: RecordNotice(title: t.record.expenseRuleTitle, body: t.record.expenseRuleBody),
      submitLabel: editing ? t.transaction.saveChangesAction : t.record.expenseAction,
      onSubmit: _canSubmit ? _submit : null,
      children: [
        RecordAmountField(
          controller: _amountController,
          label: t.record.amountLabelExpense,
          kind: TransactionKind.expense,
          quickAmounts: _quickAmounts,
          autofocus: true,
          onChanged: () => setState(() {}),
        ),
        RecordCategoryField(
          controller: _categoryController,
          suggestions: _categorySuggestions(),
          kind: TransactionKind.expense,
        ),
        WalletSelectField(
          label: t.record.expenseWalletSectionLabel,
          wallets: widget.wallets,
          selectedId: _walletId,
          onSelected: (id) => setState(() => _walletId = id),
          previewAmountSen: amount,
          previewIsCredit: false,
        ),
        RecordDateField(
          date: _date,
          kind: TransactionKind.expense,
          onChanged: (date) => setState(() => _date = date),
        ),
        RecordNoteField(controller: _noteController, kind: TransactionKind.expense),
        if (_canSubmit && wallet != null && amount != null)
          RecordSummaryCard(
            kind: TransactionKind.expense,
            children: [
              Text(
                t.record.expenseSummary(wallet: wallet.name, amount: AppMoneyFormatter.format(amount)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
      ],
    );
  }
}
