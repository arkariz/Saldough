import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wallet/wallet_presentation.dart';

/// Pemilih satu dompet dari [wallets] lewat dropdown [AppMenuSelectButton] --
/// tombol dan menu yang sama dengan penyaring dompet di layar Transaksi --
/// dengan pratinjau saldo `lama → baru` di bawahnya kalau [previewAmountSen]
/// sudah nominal yang valid.
///
/// Dipakai ketiga formulir CATAT: pemasukan ("Masuk ke Dompet"), pengeluaran
/// ("Dompet Sumber Dana"), dan dua kali di transfer ("Dari"/"Ke"). Bila
/// [caption] diisi, kop berupa titik arah saldo (merah turun, hijau naik) +
/// label + keterangan, dan [showDelta] menambah lencana selisih
/// (`−Rp500.000`) -- gaya kartu Dari/Ke rujukan visual transfer; tanpa
/// [caption], kop berupa judul bagian biasa.
///
/// Nama dompet membungkus ke banyak baris pada tombolnya, tidak dipotong.
class WalletSelectField extends StatelessWidget {
  /// Membuat [WalletSelectField].
  const WalletSelectField({
    required this.label,
    required this.wallets,
    required this.selectedId,
    required this.onSelected,
    this.caption,
    this.showDelta = false,
    this.previewAmountSen,
    this.previewIsCredit = true,
    super.key,
  });

  /// Label field, mis. "Masuk ke Dompet" atau "Dari Dompet".
  final String label;

  /// Keterangan kecil sesudah [label], mis. "Saldo berkurang". Mengubah kop
  /// jadi gaya titik berwarna.
  final String? caption;

  /// Menampilkan lencana selisih saldo di bawah pratinjau.
  final bool showDelta;

  /// Dompet yang ditawarkan.
  final List<Wallet> wallets;

  /// `id` dompet yang sedang terpilih, atau `null` kalau belum ada.
  final String? selectedId;

  /// Dipanggil dengan `id` dompet yang baru dipilih.
  final ValueChanged<String> onSelected;

  /// Nominal yang sedang diisi di formulir (sen), atau `null`/nol kalau
  /// belum nominal yang valid.
  final int? previewAmountSen;

  /// `true` -- saldo dompet ini naik sejumlah [previewAmountSen] (pemasukan,
  /// dompet tujuan transfer). `false` -- saldo turun (pengeluaran, dompet
  /// asal transfer).
  final bool previewIsCredit;

  Wallet? _findSelected() {
    final id = selectedId;
    if (id == null) return null;
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final selected = _findSelected();
    final accent = previewIsCredit ? colors.positive : colors.ink;
    final amount = previewAmountSen;
    final hasDelta = showDelta && selected != null && amount != null && amount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (caption == null)
          AppSectionLabel(label)
        else
          // Titik arah saldo + label + keterangan. `Wrap` supaya keterangan
          // turun baris, bukan meluap, pada teks besar. Label ditampilkan
          // apa adanya (bukan `.toUpperCase()`).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 2,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                Text(label, style: transactionLabelStyle(context, color: accent)),
                Text(
                  '($caption)',
                  style: transactionLabelStyle(context, color: accent).copyWith(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.space1),
        if (wallets.isEmpty)
          Text(t.record.noWalletsMessage, style: TextStyle(color: colors.ink2))
        else
          AppMenuSelectButton<String>(
            icon: selected == null ? IconKey.wallets : walletIconKey(selected.iconKey),
            label: selected?.name ?? t.record.walletNotSelectedPrompt,
            isPlaceholder: selected == null,
            wrapLabel: true,
            options: [
              for (final wallet in wallets) (value: wallet.id, label: wallet.name, icon: walletIconKey(wallet.iconKey)),
            ],
            // Saldo di tiap baris, supaya dompet bisa dipilih tanpa menebak
            // isinya (UX-11).
            detailFor: (id) => AppMoneyFormatter.format(wallets.firstWhere((w) => w.id == id).currentBalance),
            onSelected: (id) {
              if (id != null) onSelected(id);
            },
          ),
        if (selected != null) ...[
          const SizedBox(height: AppSpacing.space1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.space1,
              runSpacing: AppSpacing.space1,
              children: [
                Text(
                  t.record.balanceLabel,
                  style: transactionLabelStyle(context, color: colors.ink2).copyWith(fontWeight: FontWeight.w400),
                ),
                WalletBalancePreview(
                  wallet: selected,
                  previewAmountSen: previewAmountSen,
                  previewIsCredit: previewIsCredit,
                ),
              ],
            ),
          ),
        ],
        if (hasDelta) ...[
          const SizedBox(height: AppSpacing.space1),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2, vertical: 2),
              decoration: BoxDecoration(
                color: colors.tinted(previewIsCredit ? colors.positive : colors.ink2, 0.22),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FitStart(
                child: Text(
                  '${previewIsCredit ? '+' : '−'}${AppMoneyFormatter.format(amount)}',
                  style: transactionLabelStyle(context, color: accent),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
