import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_budget_item_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_date_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_draft_card.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_frame.dart';
import 'package:saldough/features/record/presentation/widgets/record_note_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_repeat_field.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wallet/wallet_presentation.dart';

/// Formulir catat transfer (FR-TXN-003) — satu layar, tanpa berpindah
/// halaman (NFR-UX-001). Mengembalikan [TransferRecorded] lewat
/// `Navigator.pop` saat disimpan; tombol kembali menutup CATAT.
/// Tata letaknya mengikuti rujukan visual
/// `pixel_kas_catat_transfer_antar_dompet`.
///
/// ⚠ Kosakata tombol menyatakan pencatatan, bukan tindakan keuangan —
/// "Catat Transfer", bukan "Transfer Sekarang" atau "Kirim Uang" (UX-05).
/// Tidak ada field kategori di sini -- transfer tidak berkategori (ADR-026),
/// berbeda dari formulir pemasukan dan pengeluaran.
///
/// ⚠ Bagian "Biaya Admin / Transfer" di rujukan visual TIDAK dibangun:
/// `TransferRecorded` tidak punya biaya, dan mencatatnya berarti keputusan
/// domain baru (transaksi pengeluaran pendamping, dengan akibat pada hitungan
/// saldo dan pembatalannya) yang belum diputuskan pemilik.
class TransferFormSheet extends StatefulWidget {
  /// Membuat [TransferFormSheet] dengan [wallets] sebagai pilihan asal/tujuan.
  const TransferFormSheet({
    required this.wallets,
    this.initial,
    this.prefill,
    this.draft,
    this.initialWalletId,
    this.budgetItems = const [],
    this.initialBudgetItemId,
    this.initialAmountSen,
    this.initialToWalletId,
    this.kindSwitcher,
    this.initialRepeat,
    this.repeatLocked = false,
    this.scheduleOnly = false,
    this.occurrence,
    super.key,
  });

  /// Dompet aktif yang bisa dipilih sebagai asal maupun tujuan.
  final List<Wallet> wallets;

  /// Transaksi yang disunting. `null` = mode CATAT (transaksi baru). Kalau
  /// terisi, formulir terisi awal, tombol berjudul "Simpan Perubahan", dan
  /// tombol kembali hanya menutup lembar (tidak ada lembar pilihan CATAT
  /// untuk kembali). Hasil yang dikembalikan sama seperti mode CATAT.
  final TransferTransaction? initial;

  /// Transaksi sumber untuk "Catat lagi" (UX-4) -- BEDA dari [initial]:
  /// formulir terisi awal (nominal, catatan, dompet asal/tujuan, pos
  /// anggaran) tapi TETAP mode CATAT dan tanggalnya tetap hari ini, bukan
  /// tanggal transaksi sumber. Diabaikan kalau [initial] terisi.
  final TransferTransaction? prefill;

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

  /// Dompet ASAL pra-terpilih (FR-REC-002, pintasan dari layar rincian
  /// dompet) -- pintasan dari satu dompet paling wajar berarti "dari dompet
  /// ini", bukan tujuannya. Diabaikan kalau [initial] atau [prefill] terisi.
  final String? initialWalletId;

  /// Seluruh pos anggaran; formulir hanya menawarkan pos TRANSFER yang
  /// dompet anggarannya dompet asal dan dompet tujuannya dompet tujuan
  /// transfer ini (ADR-018).
  final List<BudgetItemOption> budgetItems;

  /// Pos anggaran pra-terpilih (FR-REC-002). Diabaikan kalau [initial]
  /// terisi.
  final String? initialBudgetItemId;

  /// Nominal pra-isi dalam sen (pintasan pos anggaran: sisa pos itu).
  /// Diabaikan kalau [initial] terisi, kalau tidak positif, atau kalau tidak
  /// bisa ditulis utuh di kolom nominal (`isMoneyInputExact`).
  final int? initialAmountSen;

  /// Dompet TUJUAN pra-terpilih (pintasan pos transfer anggaran: dompet
  /// tujuan pos itu). Diabaikan kalau [initial] terisi.
  final String? initialToWalletId;

  /// Draf Catat Cerdas (ADR-027 §3.4): mengisi formulir seperti [prefill]
  /// (mode CATAT, transaksi baru) dan menampilkan teks yang tertangkap serta
  /// hal yang perlu diperiksa. Diabaikan kalau [initial] atau [prefill]
  /// terisi.
  final RecordDraft? draft;

  @override
  State<TransferFormSheet> createState() => _TransferFormSheetState();
}

class _TransferFormSheetState extends State<TransferFormSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _fromWalletId;
  String? _toWalletId;
  String? _budgetItemId;
  DateTime _date = DateTime.now();
  late RecurringPattern? _repeat = widget.initial == null ? widget.initialRepeat : null;

  @override
  void initState() {
    super.initState();
    final tx = widget.initial ?? widget.prefill;
    final draft = widget.draft;
    if (tx == null && draft != null) {
      final amount = draft.amountSen;
      if (amount != null && amount > 0 && isMoneyInputExact(amount)) _amountController.text = formatMoneyInput(amount);
      // Tanpa dompet bawaan: transfer dari draf wajib jelas asal dan
      // tujuannya (keputusan pemilik 30 Sep 2026, "top up" = transfer).
      _fromWalletId = draft.walletId;
      _toWalletId = draft.toWalletId;
      _noteController.text = draft.note;
      if (draft.date != null) _date = draft.date!;
      return;
    }
    if (tx == null) {
      _fromWalletId = widget.initialWalletId;
      _toWalletId = widget.initialToWalletId;
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
    _fromWalletId = tx.fromWalletId;
    _toWalletId = tx.toWalletId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? get _amountSen => parseMoneyInput(_amountController.text);

  /// FR-TXN-003: menolak transfer ke dompet yang sama dengan asalnya.
  /// Ditegakkan di sini (tombol dinonaktifkan), bukan hanya lewat `assert`
  /// domain yang tidak berjalan di rilis production.
  bool get _sameWallet => _fromWalletId != null && _fromWalletId == _toWalletId;

  bool get _canSubmit => _amountSen != null && _fromWalletId != null && _toWalletId != null && !_sameWallet;

  List<BudgetItemOption> get _budgetChoices =>
      transferBudgetChoicesFor(widget.budgetItems, _fromWalletId, _toWalletId, _budgetItemId, _date);

  /// Pos terpilih kalau masih sah untuk pasangan dompet asal/tujuan saat
  /// ini, selain itu `null`.
  String? get _validBudgetItemId => _budgetChoices.any((o) => o.itemId == _budgetItemId) ? _budgetItemId : null;


  void _submit() {
    final amount = _amountSen;
    final from = _fromWalletId;
    final to = _toWalletId;
    if (amount == null || from == null || to == null || from == to) return;
    Navigator.of(context).pop(
      TransferRecorded(
        fromWalletId: from,
        toWalletId: to,
        amount: amount,
        date: _date,
        repeat: _repeat,
        note: _noteController.text.trim(),
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
      kind: TransactionKind.transfer,
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
              plain: t.record.transferAction,
            ),
      onSubmit: _canSubmit ? _submit : null,
      children: [
        if (widget.initial == null && widget.prefill == null && widget.draft != null)
          RecordDraftCard(draft: widget.draft!),
        SpotlightTarget(
          spotlightKey: SpotlightKey.recordAmount,
          child: RecordAmountField(controller: _amountController, kind: TransactionKind.transfer),
        ),
        AppListCard(
          dividerIndent: AppListCard.iconIndent,
          children: [
            SpotlightTarget(
              spotlightKey: SpotlightKey.recordWallet,
              child: WalletSelectField(
                label: t.record.fromWalletFieldLabel,
                wallets: widget.wallets,
                selectedId: _fromWalletId,
                onSelected: (id) => setState(() => _fromWalletId = id),
                previewAmountSen: widget.repeatLocked ? null : amount,
                previewIsCredit: false,
              ),
            ),
            WalletSelectField(
              label: t.record.destinationWalletFieldLabel,
              wallets: widget.wallets,
              selectedId: _toWalletId,
              onSelected: (id) => setState(() => _toWalletId = id),
              previewAmountSen: widget.repeatLocked ? null : amount,
            ),
            RecordDateField(
              date: _date,
              kind: TransactionKind.transfer,
              allowFuture: _repeat != null,
              onChanged: (date) => setState(() => _date = date),
            ),
            RecordNoteField(controller: _noteController, kind: TransactionKind.transfer),
            if (_budgetChoices.isNotEmpty)
              SpotlightTarget(
                spotlightKey: SpotlightKey.recordBudgetItem,
                child: RecordBudgetItemField(
                  choices: _budgetChoices,
                  selectedId: _validBudgetItemId,
                  onSelected: (id) => setState(() => _budgetItemId = id),
                ),
              ),
          ],
        ),
        if (_sameWallet)
          AppBanner(message: t.record.sameWalletWarning, tone: AppTone.danger),
        if (budgetItemOutsidePeriod(widget.budgetItems, _budgetItemId, _date) case final dropped?)
          RecordBudgetItemOutOfPeriodNotice(option: dropped),
        if (widget.occurrence case final occurrence?)
          RecordOccurrenceNotice(occurrence: occurrence, amount: _amountSen, date: _date),
        if (!editing && widget.occurrence == null)
          SpotlightTarget(
            spotlightKey: SpotlightKey.recordRepeat,
            child: RecordRepeatField(
              value: _repeat,
              date: _date,
              kind: TransactionKind.transfer,
              locked: widget.repeatLocked,
              onChanged: (repeat) => setState(() {
                _repeat = repeat;
                if (repeat == null) _date = dateWithoutRepeat(_date);
              }),
            ),
          ),
        if (widget.repeatLocked) const RecordNoBalanceChange(),
      ],
    );
  }
}
