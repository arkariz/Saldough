import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_date_field.dart';
import 'package:saldough/features/record/presentation/widgets/wallet_picker_field.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Nominal cepat yang ditawarkan formulir transfer (rupiah, bukan sen).
const _quickAmounts = [500000, 1000000, 5000000];

/// Formulir catat transfer (FR-TXN-003) — satu layar, tanpa berpindah
/// halaman (NFR-UX-001). Mengembalikan [TransferRecorded] lewat
/// `Navigator.pop` saat disimpan, atau `BackToChoice` lewat tombol kembali.
///
/// ⚠ Kosakata tombol menyatakan pencatatan, bukan tindakan keuangan —
/// "Catat Transfer", bukan "Transfer Sekarang" atau "Kirim Uang" (UX-05).
/// Tidak ada field kategori di sini -- `TransferRecorded` tidak punya
/// `categoryKey` (lihat `RecordEvent`), berbeda dari formulir pemasukan dan
/// pengeluaran.
class TransferFormSheet extends StatefulWidget {
  /// Membuat [TransferFormSheet] dengan [wallets] sebagai pilihan asal/tujuan.
  const TransferFormSheet({required this.wallets, this.initial, super.key});

  /// Dompet aktif yang bisa dipilih sebagai asal maupun tujuan.
  final List<Wallet> wallets;

  /// Transaksi yang disunting. `null` = mode CATAT (transaksi baru). Kalau
  /// terisi, formulir terisi awal, tombol berjudul "Simpan Perubahan", dan
  /// tombol kembali hanya menutup lembar (tidak ada lembar pilihan CATAT
  /// untuk kembali). Hasil yang dikembalikan sama seperti mode CATAT.
  final TransferTransaction? initial;

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
    if (tx == null) return;
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

  bool get _canSubmit => _amountSen != null && _fromWalletId != null && _toWalletId != null && !_sameWallet;

  void _submit() {
    final amount = _amountSen;
    final from = _fromWalletId;
    final to = _toWalletId;
    if (amount == null || from == null || to == null || from == to) return;
    Navigator.of(context).pop(
      TransferRecorded(fromWalletId: from, toWalletId: to, amount: amount, date: _date, note: _noteController.text.trim()),
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
                  onPressed: () => Navigator.of(context).pop(widget.initial == null ? const BackToChoice() : null),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.initial == null ? t.record.transferAction : t.transaction.editSheetTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
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
              label: t.record.fromWalletFieldLabel,
              wallets: widget.wallets,
              selectedId: _fromWalletId,
              onSelected: (id) => setState(() => _fromWalletId = id),
              previewAmountSen: _amountSen,
              previewIsCredit: false,
            ),
            const SizedBox(height: AppSpacing.sm),
            WalletPickerField(
              label: t.record.destinationWalletFieldLabel,
              wallets: widget.wallets,
              selectedId: _toWalletId,
              onSelected: (id) => setState(() => _toWalletId = id),
              previewAmountSen: _amountSen,
            ),
            if (_sameWallet) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(t.record.sameWalletWarning, style: TextStyle(color: context.appColors.expense)),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppHardCard(
              child:RecordDateField(date: _date, onChanged: (date) => setState(() => _date = date)),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppHardCard(
              child:TextField(
                controller: _noteController,
                decoration: InputDecoration(labelText: t.record.noteFieldHint),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: widget.initial == null ? t.record.transferAction : t.transaction.saveChangesAction,
              color: context.appColors.transfer,
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
