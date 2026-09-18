import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Pemilih satu dompet dari [wallets], ditampilkan sebagai [AppChip]
/// berjajar lengkap dengan saldo berjalannya. Dipakai ketiga formulir CATAT
/// (pemasukan, pengeluaran, kedua sisi transfer) supaya tampilannya
/// konsisten dan tidak diulang tiga kali.
class WalletChipPicker extends StatelessWidget {
  /// Membuat [WalletChipPicker].
  const WalletChipPicker({required this.label, required this.wallets, required this.selectedId, required this.onSelected, super.key});

  /// Label field, mis. "Masuk ke Dompet" atau "Dari Dompet".
  final String label;

  /// Dompet yang ditawarkan.
  final List<Wallet> wallets;

  /// `id` dompet yang sedang terpilih, atau `null` kalau belum ada.
  final String? selectedId;

  /// Dipanggil dengan `id` dompet yang baru dipilih.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (wallets.isEmpty) {
      return Text(t.record.noWalletsMessage, style: TextStyle(color: context.appColors.textMuted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final wallet in wallets)
              AppChip(
                label: '${wallet.name} · ${AppMoneyFormatter.format(wallet.currentBalance)}',
                selected: wallet.id == selectedId,
                onTap: () => onSelected(wallet.id),
              ),
          ],
        ),
      ],
    );
  }
}
