import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Baris form pemilih satu dompet dari [wallets] (design system ListRow,
/// baris form): label kecil di atas nama dompet, menu bergambar saat
/// diketuk, dan di kanan akibatnya ke saldo, ditulis satu kali: "Saldo jadi
/// Rp331.000" kalau [previewAmountSen] sudah nominal yang valid, selain itu
/// saldo saat ini. Saldo yang jadi negatif ditulis `danger`.
///
/// Dipakai ketiga formulir CATAT: pemasukan ("Masuk ke"), pengeluaran
/// ("Dompet"), dan dua kali di transfer ("Dari"/"Ke"), serta pembayaran
/// freelance dan pola notifikasi.
class WalletSelectField extends StatelessWidget {
  /// Membuat [WalletSelectField].
  const WalletSelectField({
    required this.label,
    required this.wallets,
    required this.selectedId,
    required this.onSelected,
    this.previewAmountSen,
    this.previewIsCredit = true,
    super.key,
  });

  /// Label baris, mis. "Masuk ke" atau "Dari".
  final String label;

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
    if (wallets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Text(t.record.noWalletsMessage, style: TextStyle(color: colors.ink2)),
      );
    }
    Widget? trailing;
    if (selected != null) {
      final amount = previewAmountSen;
      final hasPreview = amount != null && amount > 0;
      final after = !hasPreview
          ? selected.currentBalance
          : (previewIsCredit ? selected.currentBalance + amount : selected.currentBalance - amount);
      final text = hasPreview
          ? t.record.balanceAfter(amount: AppMoneyFormatter.format(after))
          : AppMoneyFormatter.format(after);
      trailing = Text(
        text,
        key: const ValueKey('wallet-balance-after'),
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: hasPreview && after < 0 ? colors.danger : colors.ink2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }
    return AppMenuSelectButton<String>(
      fieldLabel: label,
      rowIcon: IconKey.wallets,
      icon: selected == null ? IconKey.wallets : walletIconKey(selected.iconKey),
      label: selected?.name ?? t.record.walletNotSelectedPrompt,
      isPlaceholder: selected == null,
      wrapLabel: true,
      trailing: trailing,
      options: [
        for (final wallet in wallets) (value: wallet.id, label: wallet.name, icon: walletIconKey(wallet.iconKey)),
      ],
      // Saldo di tiap baris, supaya dompet bisa dipilih tanpa menebak
      // isinya (UX-11).
      detailFor: (id) => AppMoneyFormatter.format(wallets.firstWhere((w) => w.id == id).currentBalance),
      onSelected: (id) {
        if (id != null) onSelected(id);
      },
    );
  }
}
