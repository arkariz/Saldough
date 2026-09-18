import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/record_date_field.dart';
import 'package:saldough/features/record/presentation/widgets/wallet_chip_picker.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Formulir catat transfer (FR-TXN-003) — satu layar, tanpa berpindah
/// halaman (NFR-UX-001). Mengembalikan [TransferRecorded] lewat
/// `Navigator.pop` saat disimpan.
///
/// ⚠ Kosakata tombol menyatakan pencatatan, bukan tindakan keuangan —
/// "Catat Transfer", bukan "Transfer Sekarang" atau "Kirim Uang" (UX-05).
class TransferFormSheet extends StatefulWidget {
  /// Membuat [TransferFormSheet] dengan [wallets] sebagai pilihan asal/tujuan.
  const TransferFormSheet({required this.wallets, super.key});

  /// Dompet aktif yang bisa dipilih sebagai asal maupun tujuan.
  final List<Wallet> wallets;

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
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? get _amountSen {
    final rupiah = int.tryParse(_amountController.text.trim());
    return rupiah == null || rupiah <= 0 ? null : rupiah * 100;
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
            Text(t.record.transferAction, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: t.record.amountFieldHint),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            WalletChipPicker(
              label: t.record.fromWalletFieldLabel,
              wallets: widget.wallets,
              selectedId: _fromWalletId,
              onSelected: (id) => setState(() => _fromWalletId = id),
            ),
            const SizedBox(height: AppSpacing.sm),
            WalletChipPicker(
              label: t.record.destinationWalletFieldLabel,
              wallets: widget.wallets,
              selectedId: _toWalletId,
              onSelected: (id) => setState(() => _toWalletId = id),
            ),
            if (_sameWallet) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(t.record.sameWalletWarning, style: TextStyle(color: context.appColors.expense)),
            ],
            const SizedBox(height: AppSpacing.sm),
            RecordDateField(date: _date, onChanged: (date) => setState(() => _date = date)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(labelText: t.record.noteFieldHint),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: t.record.transferAction, onPressed: _canSubmit ? _submit : null),
          ],
        ),
      ),
    );
  }
}
