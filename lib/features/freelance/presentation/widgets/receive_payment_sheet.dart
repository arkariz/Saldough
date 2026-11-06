import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/freelance/domain/entities/net_pay_breakdown.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_form_fields.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_notice.dart';
import 'package:saldough/features/freelance/presentation/widgets/net_pay_breakdown_card.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wallet/wallet_presentation.dart';

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
    final ds = context.ds;
    final c = ds.colors;
    final netPay = widget.breakdown.netPay;
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFormHeader(title: t.freelance.receiveTitle),
              const SizedBox(height: 16),
              FreelanceNotice(
                title: t.freelance.receiveRuleTitle,
                body: t.freelance.receiveRuleBody,
                tone: FreelanceNoticeTone.positive,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: c.heroSurface, borderRadius: DsRadius.lgAll),
                child: Column(
                  children: [
                    Text(
                      t.freelance.receiveAmountLabel,
                      style: ds.typography.pixelCaption.copyWith(color: c.onHeroMuted),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppMoneyFormatter.format(netPay),
                        style: ds.typography.pixelDisplay.copyWith(color: c.onHero),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              NetPayBreakdownCard(breakdown: widget.breakdown),
              const SizedBox(height: 16),
              DsFieldGroup(
                children: [
                  WalletSelectField(
                    useDs: true,
                    label: t.freelance.receiveWalletLabel,
                    wallets: widget.wallets,
                    selectedId: _walletId,
                    onSelected: (id) => setState(() => _walletId = id),
                    previewAmountSen: netPay,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FreelanceDateButton(
                label: t.freelance.receiveDateLabel,
                date: _date,
                onChanged: (date) => setState(() => _date = date),
              ),
              const SizedBox(height: 16),
              AppSectionLabel(t.freelance.noteLabel),
              const SizedBox(height: 8),
              AppFormTextField(controller: _note, hint: t.freelance.noteHint, maxLength: 120, onChanged: (_) {}),
              const SizedBox(height: 24),
              DsButton(
                label: t.freelance.receiveAction,
                expand: true,
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
