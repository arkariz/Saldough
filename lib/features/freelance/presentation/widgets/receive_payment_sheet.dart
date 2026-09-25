import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_fields.dart';
import 'package:saldough/features/freelance/domain/entities/net_pay_breakdown.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_form_fields.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_notice.dart';
import 'package:saldough/features/freelance/presentation/widgets/net_pay_breakdown_card.dart';
import 'package:saldough/features/record/presentation/widgets/wallet_select_field.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Hasil [ReceivePaymentSheet] saat disimpan; `null` berarti dibatalkan.
final class ReceivePaymentConfirmed {
  /// Membuat [ReceivePaymentConfirmed].
  const ReceivePaymentConfirmed({required this.walletId, required this.date, required this.note});

  /// Dompet tujuan.
  final String walletId;

  /// Tanggal diterima.
  final DateTime date;

  /// Catatan transaksi pemasukannya.
  final String note;
}

/// Formulir mencatat pembayaran diterima (FR-FRL-004, rujukan
/// `pixel_kas_catat_pembayaran_freelance`): gaji bersih, dompet tujuan,
/// tanggal, dan catatan.
///
/// Kartu aturannya menyatakan bahwa ini **pencatatan** uang yang sudah
/// diterima, bukan pembayaran yang dijalankan aplikasi. Nominalnya tidak bisa
/// diubah: selalu gaji bersih pembayaran itu.
class ReceivePaymentSheet extends StatefulWidget {
  /// Membuat [ReceivePaymentSheet].
  const ReceivePaymentSheet({
    required this.projectName,
    required this.breakdown,
    required this.wallets,
    super.key,
  });

  /// Nama proyek, untuk catatan bawaan.
  final String projectName;

  /// Rincian gaji pembayaran ini.
  final NetPayBreakdown breakdown;

  /// Dompet aktif yang bisa dipilih.
  final List<Wallet> wallets;

  @override
  State<ReceivePaymentSheet> createState() => _ReceivePaymentSheetState();
}

class _ReceivePaymentSheetState extends State<ReceivePaymentSheet> {
  final _note = TextEditingController();
  String? _walletId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _note.text = t.freelance.receiveNoteDefault(project: widget.projectName);
    if (widget.wallets.length == 1) _walletId = widget.wallets.single.id;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final netPay = widget.breakdown.netPay;
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BudgetFormHeader(stepLabel: t.freelance.paymentStepLabel, title: t.freelance.receiveTitle),
              const SizedBox(height: AppSpacing.md),
              FreelanceNotice(
                title: t.freelance.receiveRuleTitle,
                body: t.freelance.receiveRuleBody,
                color: colors.income,
              ),
              const SizedBox(height: AppSpacing.md),
              TransactionSlab(
                color: colors.income,
                child: Column(
                  children: [
                    Text(
                      t.freelance.receiveAmountLabel.toUpperCase(),
                      style: transactionLabelStyle(context, color: colors.cardBackground),
                    ),
                    const SizedBox(height: 4),
                    FitStart(
                      child: Text(
                        AppMoneyFormatter.format(netPay),
                        style: PixelTypography.tabularMono(context, fontSize: 30, color: colors.cardBackground),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              NetPayBreakdownCard(breakdown: widget.breakdown),
              const SizedBox(height: AppSpacing.md),
              WalletSelectField(
                label: t.freelance.receiveWalletLabel,
                wallets: widget.wallets,
                selectedId: _walletId,
                onSelected: (id) => setState(() => _walletId = id),
                previewAmountSen: netPay,
              ),
              const SizedBox(height: AppSpacing.md),
              FreelanceDateButton(
                label: t.freelance.receiveDateLabel,
                date: _date,
                onChanged: (date) => setState(() => _date = date),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSectionLabel(t.freelance.noteLabel),
              const SizedBox(height: AppSpacing.xs),
              BudgetTextField(controller: _note, hint: t.freelance.noteHint, maxLength: 120, onChanged: (_) {}),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: t.freelance.receiveAction,
                color: colors.income,
                onPressed: _walletId == null
                    ? null
                    : () => Navigator.of(context).pop(
                        ReceivePaymentConfirmed(walletId: _walletId!, date: _date, note: _note.text.trim()),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
