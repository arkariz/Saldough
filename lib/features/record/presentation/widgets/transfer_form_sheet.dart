import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_date_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_frame.dart';
import 'package:saldough/features/record/presentation/widgets/record_note_field.dart';
import 'package:saldough/features/record/presentation/widgets/wallet_select_field.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Nominal cepat yang ditawarkan formulir transfer (rupiah, bukan sen).
const _quickAmounts = [500000, 1000000, 5000000];

/// Formulir catat transfer (FR-TXN-003) — satu layar, tanpa berpindah
/// halaman (NFR-UX-001). Mengembalikan [TransferRecorded] lewat
/// `Navigator.pop` saat disimpan, atau `BackToChoice` lewat tombol kembali.
/// Tata letaknya mengikuti rujukan visual
/// `pixel_kas_catat_transfer_antar_dompet`.
///
/// ⚠ Kosakata tombol menyatakan pencatatan, bukan tindakan keuangan —
/// "Catat Transfer", bukan "Transfer Sekarang" atau "Kirim Uang" (UX-05).
/// Tidak ada field kategori di sini -- `TransferRecorded` tidak punya
/// `categoryKey` (lihat `RecordEvent`), berbeda dari formulir pemasukan dan
/// pengeluaran.
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
    this.initialWalletId,
    super.key,
  });

  /// Dompet aktif yang bisa dipilih sebagai asal maupun tujuan.
  final List<Wallet> wallets;

  /// Transaksi yang disunting. `null` = mode CATAT (transaksi baru). Kalau
  /// terisi, formulir terisi awal, tombol berjudul "Simpan Perubahan", dan
  /// tombol kembali hanya menutup lembar (tidak ada lembar pilihan CATAT
  /// untuk kembali). Hasil yang dikembalikan sama seperti mode CATAT.
  final TransferTransaction? initial;

  /// Dompet ASAL pra-terpilih (FR-REC-002, pintasan dari layar rincian
  /// dompet) -- pintasan dari satu dompet paling wajar berarti "dari dompet
  /// ini", bukan tujuannya. Diabaikan kalau [initial] terisi.
  final String? initialWalletId;

  @override
  State<TransferFormSheet> createState() => _TransferFormSheetState();
}

class _TransferFormSheetState extends State<TransferFormSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _fromWalletId;
  String? _toWalletId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final tx = widget.initial;
    if (tx == null) {
      _fromWalletId = widget.initialWalletId;
      return;
    }
    _amountController.text = formatRecordAmount(tx.amount ~/ 100);
    _date = tx.date;
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

  int? get _amountSen {
    final rupiah = parseRecordAmount(_amountController.text);
    return rupiah == null ? null : rupiah * 100;
  }

  /// FR-TXN-003: menolak transfer ke dompet yang sama dengan asalnya.
  /// Ditegakkan di sini (tombol dinonaktifkan), bukan hanya lewat `assert`
  /// domain yang tidak berjalan di rilis production.
  bool get _sameWallet => _fromWalletId != null && _fromWalletId == _toWalletId;

  bool get _canSubmit =>
      _amountSen != null &&
      _fromWalletId != null &&
      _toWalletId != null &&
      !_sameWallet;

  Wallet? _find(String? id) {
    for (final wallet in widget.wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

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
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final editing = widget.initial != null;
    final from = _find(_fromWalletId);
    final to = _find(_toWalletId);
    final amount = _amountSen;
    final money = amount == null ? null : AppMoneyFormatter.format(amount);
    return RecordFormFrame(
      kind: TransactionKind.transfer,
      title: editing ? t.transaction.editSheetTitle : t.record.transferAction,
      isEditing: editing,
      onBack: () =>
          Navigator.of(context).pop(editing ? null : const BackToChoice()),
      notice: RecordNotice(
        title: t.record.transferNoticeTitle,
        body: t.record.transferNoticeBody,
      ),
      submitLabel: editing
          ? t.transaction.saveChangesAction
          : t.record.transferAction,
      onSubmit: _canSubmit ? _submit : null,
      children: [
        RecordAmountField(
          controller: _amountController,
          label: t.record.amountLabelTransfer,
          kind: TransactionKind.transfer,
          quickAmounts: _quickAmounts,
          autofocus: true,
          onChanged: () => setState(() {}),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WalletSelectField(
              label: t.record.fromWalletFieldLabel,
              caption: t.record.balanceDecreasesCaption,
              showDelta: true,
              wallets: widget.wallets,
              selectedId: _fromWalletId,
              onSelected: (id) => setState(() => _fromWalletId = id),
              previewAmountSen: amount,
              previewIsCredit: false,
            ),
            const SizedBox(height: AppSpacing.md),
            WalletSelectField(
              label: t.record.destinationWalletFieldLabel,
              caption: t.record.balanceIncreasesCaption,
              showDelta: true,
              wallets: widget.wallets,
              selectedId: _toWalletId,
              onSelected: (id) => setState(() => _toWalletId = id),
              previewAmountSen: amount,
            ),
            if (_sameWallet) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                t.record.sameWalletWarning,
                style: TextStyle(color: colors.expense),
              ),
            ],
          ],
        ),
        RecordDateField(
          date: _date,
          kind: TransactionKind.transfer,
          onChanged: (date) => setState(() => _date = date),
        ),
        RecordNoteField(
          controller: _noteController,
          kind: TransactionKind.transfer,
        ),
        if (_canSubmit && from != null && to != null && money != null)
          RecordSummaryCard(
            kind: TransactionKind.transfer,
            title: t.record.transferSummaryTitle,
            children: [
              Text(
                t.record.transferSummaryFrom(wallet: from.name, amount: money),
                style:
                    Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(
                      color: colors.expense,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                t.record.transferSummaryTo(wallet: to.name, amount: money),
                style:
                    Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(
                      color: colors.income,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
      ],
    );
  }
}
