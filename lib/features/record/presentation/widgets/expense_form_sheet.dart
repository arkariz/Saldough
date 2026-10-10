import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_controller.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_budget_item_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_category_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_date_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_draft_card.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_frame.dart';
import 'package:saldough/features/record/presentation/widgets/record_note_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_repeat_field.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wallet/wallet_presentation.dart';

/// Formulir catat pengeluaran (FR-TXN-002) — satu layar, tanpa berpindah
/// halaman (NFR-UX-001). Mengembalikan [ExpenseRecorded] lewat
/// `Navigator.pop` saat disimpan; tombol kembali menutup CATAT.
/// Tata letaknya mengikuti rujukan visual `pixel_kas_catat_pengeluaran`.
///
/// Tautan opsional ke satu pos anggaran (FR-TXN-002, T-4.4) lewat
/// [RecordBudgetItemField]: hanya pos anggaran yang dompetnya sama dengan
/// dompet asal pengeluaran ini dan periodenya mencakup tanggalnya (KT-1).
/// Elemen gamifikasi rujukan
/// ("LVL +10 EXP") tidak dibangun: bukan bagian kebutuhan produk.
class ExpenseFormSheet extends StatefulWidget {
  /// Membuat [ExpenseFormSheet] dengan [wallets] sebagai pilihan asal.
  const ExpenseFormSheet({
    required this.wallets,
    this.initial,
    this.prefill,
    this.draft,
    this.initialWalletId,
    this.frequentCategoryIds = const [],
    this.onCreateCategory,
    this.budgetItems = const [],
    this.initialBudgetItemId,
    this.initialAmountSen,
    this.kindSwitcher,
    this.initialRepeat,
    this.repeatLocked = false,
    this.scheduleOnly = false,
    this.occurrence,
    super.key,
  });

  /// Dompet aktif yang bisa dipilih sebagai asal.
  final List<Wallet> wallets;

  /// Transaksi yang disunting. `null` = mode CATAT (transaksi baru). Kalau
  /// terisi, formulir terisi awal, tombol berjudul "Simpan Perubahan", dan
  /// tombol kembali hanya menutup lembar (tidak ada lembar pilihan CATAT
  /// untuk kembali). Hasil yang dikembalikan sama seperti mode CATAT.
  final ExpenseTransaction? initial;

  /// Transaksi sumber untuk "Catat lagi" (UX-4) -- BEDA dari [initial]:
  /// formulir terisi awal (nominal, kategori, catatan, dompet, pos anggaran)
  /// tapi TETAP mode CATAT dan tanggalnya tetap hari ini, bukan tanggal
  /// transaksi sumber. Pos anggaran yang tidak lagi berlaku untuk hari ini
  /// otomatis tidak ikut terisi ([_validBudgetItemId]). Diabaikan kalau
  /// [initial] terisi.
  final ExpenseTransaction? prefill;

  /// Pengalih jenis CATAT (Keluar/Masuk/Transfer, UX-1) di bawah kop —
  /// dipasang `RecordFormHost`; tidak tampil saat menyunting.
  final Widget? kindSwitcher;

  /// Ulangi awal (chip pembuka atau Jadikan Rutin, T-15.3); `null` = tidak
  /// diulang. Diabaikan saat menyunting.
  final RecurringPattern? initialRepeat;

  /// Jadikan Rutin: Ulangi wajib nyala.
  final bool repeatLocked;

  /// Ubah rutin: tombol selalu "Simpan Jadwal", karena tidak ada transaksi
  /// yang dicatat.
  final bool scheduleOnly;

  /// Kemunculan rutin yang dicatat ("Ubah dulu", T-15.6): menampilkan
  /// pemberitahuan E5/E11 dan menyembunyikan Ulangi.
  final RecordOccurrence? occurrence;

  /// Dompet asal pra-terpilih (FR-REC-002, pintasan dari layar rincian
  /// dompet, atau dompet bawaan CATAT, UX-2). Diabaikan kalau [initial]
  /// atau [prefill] terisi -- keduanya selalu memakai dompet transaksi itu
  /// sendiri.
  final String? initialWalletId;

  /// Id kategori yang paling sering dipakai untuk jenis ini, dari riwayat —
  /// ditawarkan paling atas (UX-3).
  final List<String> frequentCategoryIds;

  /// Membuat kategori baru dari "Tambah kategori" (ADR-026 §3.6); `null`
  /// berarti pilihan itu tidak ditawarkan.
  final Future<Category?> Function(String name, String? iconKey)? onCreateCategory;

  /// Seluruh pos anggaran; formulir menyaringnya per dompet asal.
  final List<BudgetItemOption> budgetItems;

  /// Pos anggaran pra-terpilih (FR-REC-002, pintasan dari rincian anggaran).
  /// Diabaikan kalau [initial] terisi.
  final String? initialBudgetItemId;

  /// Nominal pra-isi dalam sen (pintasan pos anggaran: sisa pos itu).
  /// Diabaikan kalau [initial] terisi, kalau tidak positif, atau kalau tidak
  /// bisa ditulis utuh di kolom nominal (`isMoneyInputExact`).
  final int? initialAmountSen;

  /// Draf Catat Cerdas (ADR-027 §3.4): mengisi formulir seperti [prefill]
  /// (mode CATAT, transaksi baru) dan menampilkan teks yang tertangkap serta
  /// hal yang perlu diperiksa. Diabaikan kalau [initial] atau [prefill]
  /// terisi.
  final RecordDraft? draft;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  final _amountController = RecordAmountController();
  String? _categoryId;
  final _noteController = TextEditingController();
  String? _walletId;
  String? _budgetItemId;
  DateTime _date = DateTime.now();
  late RecurringPattern? _repeat = widget.initial == null ? widget.initialRepeat : null;

  @override
  void initState() {
    super.initState();
    final tx = widget.initial ?? widget.prefill;
    final draft = widget.draft;
    if (tx == null && draft != null) {
      _applyDraft(draft);
      return;
    }
    if (tx == null) {
      _walletId = widget.initialWalletId;
      _budgetItemId = widget.initialBudgetItemId;
      final amount = widget.initialAmountSen;
      if (amount != null && amount > 0 && isMoneyInputExact(amount)) {
        _amountController.text = formatMoneyInput(amount);
      }
      return;
    }
    _budgetItemId = tx.budgetItemId;
    _amountController.text = formatMoneyInput(tx.amount);
    // Tanggal HANYA diambil dari `initial` (mode sunting) -- "Catat lagi"
    // (`prefill`) tetap mencatat hari ini, bukan tanggal transaksi sumber.
    if (widget.initial != null) _date = tx.date;
    _noteController.text = tx.note;
    _walletId = tx.walletId;
    _categoryId = tx.categoryId;
  }

  void _applyDraft(RecordDraft draft) {
    final amount = draft.amountSen;
    if (amount != null && amount > 0 && isMoneyInputExact(amount)) _amountController.text = formatMoneyInput(amount);
    // Dompet yang disebut tapi tidak dikenal: biarkan kosong supaya dipilih,
    // bukan diam-diam memakai dompet bawaan.
    _walletId = draft.walletId ?? (draft.issues.contains(DraftIssue.walletUnknown) ? null : widget.initialWalletId);
    _categoryId = draft.categoryId;
    _noteController.text = draft.note;
    if (draft.date != null) _date = draft.date!;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? get _amountSen => parseMoneyInput(_amountController.text);

  bool get _canSubmit => _amountSen != null && _walletId != null;

  /// Tanggal yang menentukan pos anggaran (KT-1): tanggal kemunculan bila
  /// transaksi ini tertaut rutin dan selisihnya paling banyak 7 hari
  /// (ADR-038 §3.5), selain itu tanggal transaksi.
  DateTime get _periodDate =>
      periodDateFor(_date, widget.initial?.recurrence?.occurrenceDate ?? widget.occurrence?.date);

  List<BudgetItemOption> get _budgetChoices =>
      expenseBudgetChoicesFor(widget.budgetItems, _walletId, _budgetItemId, _periodDate);

  /// Pos terpilih kalau masih sah untuk dompet asal saat ini, selain itu
  /// `null` — pos anggaran dompet lain tidak pernah ikut tersimpan.
  String? get _validBudgetItemId => _budgetChoices.any((o) => o.itemId == _budgetItemId) ? _budgetItemId : null;


  void _submit() {
    final amount = _amountSen;
    final walletId = _walletId;
    if (amount == null || walletId == null) return;
    Navigator.of(context).pop(
      ExpenseRecorded(
        walletId: walletId,
        amount: amount,
        date: _date,
        repeat: _repeat,
        note: _noteController.text.trim(),
        categoryId: _categoryId,
        budgetItemId: _validBudgetItemId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    final amount = _amountSen;
    return RecordFormFrame(
      kindSwitcher: editing ? null : widget.kindSwitcher,
      kind: TransactionKind.expense,
      title: editing ? t.transaction.editSheetTitle : t.appShell.recordAction,
      isEditing: editing,
      onBack: () => Navigator.of(context).pop(),
      amountController: _amountController,
      onAmountChanged: () => setState(() {}),
      submitLabel: editing
          ? t.transaction.saveChangesAction
          : repeatSubmitLabel(
              repeat: _repeat,
              date: _date,
              scheduleOnly: widget.scheduleOnly,
              plain: t.record.expenseAction,
            ),
      onSubmit: _canSubmit ? _submit : null,
      children: [
        if (widget.initial == null && widget.prefill == null && widget.draft != null)
          RecordDraftCard(draft: widget.draft!),
        SpotlightTarget(
          spotlightKey: SpotlightKey.recordAmount,
          child: RecordAmountField(controller: _amountController, kind: TransactionKind.expense),
        ),
        RecordCategoryField(
          value: _categoryId,
          onChanged: (id) => setState(() => _categoryId = id),
          categoryKind: CategoryKind.expense,
          frequentIds: widget.frequentCategoryIds,
          onCreate: widget.onCreateCategory,
          title: _noteController.text,
        ),
        AppListCard(
          dividerIndent: AppListCard.iconIndent,
          children: [
            SpotlightTarget(
              spotlightKey: SpotlightKey.recordWallet,
              child: WalletSelectField(
                label: t.record.expenseWalletSectionLabel,
                wallets: widget.wallets,
                selectedId: _walletId,
                onSelected: (id) => setState(() => _walletId = id),
                previewAmountSen: widget.repeatLocked ? null : amount,
                previewIsCredit: false,
              ),
            ),
            RecordDateField(
              date: _date,
              kind: TransactionKind.expense,
              allowFuture: _repeat != null,
              onChanged: (date) => setState(() => _date = date),
            ),
            RecordNoteField(
              controller: _noteController,
              kind: TransactionKind.expense,
              onChanged: (_) => setState(() {}),
            ),
            if (_budgetChoices.isNotEmpty)
              SpotlightTarget(
                spotlightKey: SpotlightKey.recordBudgetItem,
                child: RecordBudgetItemField(
                  choices: _budgetChoices,
                  selectedId: _validBudgetItemId,
                  onSelected: (id) => setState(() => _budgetItemId = id),
                ),
              ),
            if (!editing && widget.occurrence == null)
              SpotlightTarget(
                spotlightKey: SpotlightKey.recordRepeat,
                child: RecordRepeatField(
                  value: _repeat,
                  date: _date,
                  kind: TransactionKind.expense,
                  locked: widget.repeatLocked,
                  onChanged: (repeat) => setState(() {
                    _repeat = repeat;
                    if (repeat == null) _date = dateWithoutRepeat(_date);
                  }),
                ),
              ),
          ],
        ),
        if (budgetItemOutsidePeriod(widget.budgetItems, _budgetItemId, _periodDate) case final dropped?)
          RecordBudgetItemOutOfPeriodNotice(option: dropped),
        if (widget.occurrence case final occurrence?)
          RecordOccurrenceNotice(occurrence: occurrence, amount: _amountSen, date: _date),
        // Jadikan Rutin / ubah rutin tidak mencatat transaksi baru.
        if (widget.repeatLocked) const RecordNoBalanceChange(),
      ],
    );
  }
}
