import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Pemilih satu dompet dari [wallets], dengan pratinjau saldo sebelum→sesudah
/// kalau [previewAmountSen] sudah nominal yang valid.
///
/// Menggantikan `WalletChipPicker` (pola "seluruh dompet sebagai baris
/// chip", yang tidak terskala lewat ~3 dompet dan tidak menunjukkan
/// konsekuensi apa pun). Pola di sini: kartu dompet terpilih + tombol
/// "Ganti" yang membuka lembar pemilih, ditambah pratinjau saldo — pratinjau
/// ini SUNGGUHAN, bukan porting dari sesuatu yang sudah teruji: rujukan
/// visual pemilik hanya menampilkannya sebagai ilustrasi statis, tidak
/// pernah sebagai fitur yang terpasang.
class WalletPickerField extends StatelessWidget {
  /// Membuat [WalletPickerField].
  const WalletPickerField({
    required this.label,
    required this.wallets,
    required this.selectedId,
    required this.onSelected,
    this.previewAmountSen,
    this.previewIsCredit = true,
    super.key,
  });

  /// Label field, mis. "Masuk ke Dompet" atau "Dari Dompet".
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

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(label, style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final wallet in wallets)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => Navigator.of(sheetContext).pop(wallet.id),
                  child: AppHardCard(
                    child: Row(
                      children: [
                        const AppIcon(IconKey.wallets, size: 28),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(wallet.name, style: Theme.of(sheetContext).textTheme.titleMedium),
                              Text(AppMoneyFormatter.format(wallet.currentBalance)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (wallets.isEmpty) {
      return Text(t.record.noWalletsMessage, style: TextStyle(color: context.appColors.textMuted));
    }

    final colors = context.appColors;
    final selected = _findSelected();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ditampilkan apa adanya (bukan `.toUpperCase()`) supaya teksnya
        // tetap persis sama dengan [label] yang diteruskan pemanggil --
        // kapitalisasi visual gaya-kop cukup lewat gaya huruf kecil/tebal,
        // tidak perlu mengubah string aslinya.
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.textMuted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: () => _openPicker(context),
          child: AppHardCard(
            child: Row(
              children: [
                // Ikon dompet per jenis (`Wallet.iconKey` -> `IconKey`) belum
                // ada pemetaannya di manapun di kode -- lihat catatan
                // `IconKey.wallets` di `app_icon.dart`. Pemetaan sungguhan
                // adalah pekerjaan T-2.7 saat UI `feature/wallet` dibangun;
                // di sini cukup ikon generik yang selalu valid.
                const AppIcon(IconKey.wallets, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: selected == null
                      ? Text(t.record.walletNotSelectedPrompt, style: TextStyle(color: colors.textMuted))
                      : _SelectedWalletPreview(
                          wallet: selected,
                          previewAmountSen: previewAmountSen,
                          previewIsCredit: previewIsCredit,
                        ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: () => _openPicker(context),
                  child: Text(t.record.changeWalletAction),
                ),
                const AppIcon(IconKey.chevronRight, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedWalletPreview extends StatelessWidget {
  const _SelectedWalletPreview({required this.wallet, required this.previewAmountSen, required this.previewIsCredit});

  final Wallet wallet;
  final int? previewAmountSen;
  final bool previewIsCredit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final amount = previewAmountSen;
    final hasPreview = amount != null && amount > 0;
    final after = hasPreview ? (previewIsCredit ? wallet.currentBalance + amount : wallet.currentBalance - amount) : null;
    final afterColor = previewIsCredit ? colors.income : colors.expense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(wallet.name, style: Theme.of(context).textTheme.titleMedium),
        if (hasPreview && after != null)
          Row(
            children: [
              Text(
                AppMoneyFormatter.format(wallet.currentBalance),
                style: TextStyle(
                  color: colors.textMuted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.arrow_forward, size: 14, color: colors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppMoneyFormatter.format(after),
                style: TextStyle(color: afterColor, fontWeight: FontWeight.w700),
              ),
            ],
          )
        else
          Text(AppMoneyFormatter.format(wallet.currentBalance)),
      ],
    );
  }
}
