import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/domain/budget_item_catalog.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_budget_item_field.dart';
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
/// Tautan opsional ke satu pos anggaran (FR-TXN-002, T-4.4) lewat
/// [RecordBudgetItemField]: hanya pos anggaran aktif yang dompetnya sama
/// dengan dompet asal pengeluaran ini. Elemen gamifikasi rujukan
/// ("LVL +10 EXP") tidak dibangun: bukan bagian kebutuhan produk.
class ExpenseFormSheet extends StatefulWidget {
  /// Membuat [ExpenseFormSheet] dengan [wallets] sebagai pilihan asal.
  const ExpenseFormSheet({
    required this.wallets,
    this.initial,
    this.initialWalletId,
    this.budgetItems = const [],
    this.initialBudgetItemId,
    this.initialAmountSen,
    super.key,
  });

  /// Dompet aktif yang bisa dipilih sebagai asal.
  final List<Wallet> wallets;

  /// Transaksi yang disunting. `null` = mode CATAT (transaksi baru). Kalau
  /// terisi, formulir terisi awal, tombol berjudul "Simpan Perubahan", dan
  /// tombol kembali hanya menutup lembar (tidak ada lembar pilihan CATAT
  /// untuk kembali). Hasil yang dikembalikan sama seperti mode CATAT.
  final ExpenseTransaction? initial;

  /// Dompet asal pra-terpilih (FR-REC-002, pintasan dari layar rincian
  /// dompet). Diabaikan kalau [initial] terisi -- mode sunting selalu memakai
  /// dompet transaksi itu sendiri.
  final String? initialWalletId;

  /// Seluruh pos anggaran; formulir menyaringnya per dompet asal.
  final List<BudgetItemOption> budgetItems;

  /// Pos anggaran pra-terpilih (FR-REC-002, pintasan dari rincian anggaran).
  /// Diabaikan kalau [initial] terisi.
  final String? initialBudgetItemId;

  /// Nominal pra-isi dalam sen (pintasan pos anggaran: sisa pos itu).
  /// Diabaikan kalau [initial] terisi, kalau tidak positif, atau kalau bukan
  /// rupiah utuh (kolom nominal hanya menerima rupiah utuh).
  final int? initialAmountSen;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  String? _walletId;
  String? _budgetItemId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final tx = widget.initial;
    if (tx == null) {
      _walletId = widget.initialWalletId;
      _budgetItemId = widget.initialBudgetItemId;
      final amount = widget.initialAmountSen;
      if (amount != null && amount > 0 && amount % 100 == 0) {
        _amountController.text = formatRecordAmount(amount ~/ 100);
      }
      return;
    }
    _budgetItemId = tx.budgetItemId;
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

  List<BudgetItemOption> get _budgetChoices =>
      budgetItemChoicesFor(widget.budgetItems, _walletId, _budgetItemId);

  /// Pos terpilih kalau masih sah untuk dompet asal saat ini, selain itu
  /// `null` — pos anggaran dompet lain tidak pernah ikut tersimpan.
  String? get _validBudgetItemId =>
      _budgetChoices.any((o) => o.itemId == _budgetItemId) ? _budgetItemId : null;

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
        categoryKey: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        budgetItemId: _validBudgetItemId,
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
      onBack: () =>
          Navigator.of(context).pop(editing ? null : const BackToChoice()),
      notice: RecordNotice(
        title: t.record.expenseRuleTitle,
        body: t.record.expenseRuleBody,
      ),
      submitLabel: editing
          ? t.transaction.saveChangesAction
          : t.record.expenseAction,
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
        if (_budgetChoices.isNotEmpty)
          RecordBudgetItemField(
            choices: _budgetChoices,
            selectedId: _validBudgetItemId,
            onSelected: (id) => setState(() => _budgetItemId = id),
          ),
        RecordDateField(
          date: _date,
          kind: TransactionKind.expense,
          onChanged: (date) => setState(() => _date = date),
        ),
        RecordNoteField(
          controller: _noteController,
          kind: TransactionKind.expense,
        ),
        if (_canSubmit && wallet != null && amount != null)
          RecordSummaryCard(
            kind: TransactionKind.expense,
            children: [
              Text(
                t.record.expenseSummary(
                  wallet: wallet.name,
                  amount: AppMoneyFormatter.format(amount),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
      ],
    );
  }
}
