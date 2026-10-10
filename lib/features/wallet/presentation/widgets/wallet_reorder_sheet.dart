import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_type.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lembar **Urutkan dompet** (B-34): dompet aktif diurutkan dengan menekan
/// lalu menyeret baris (atau pegangannya). Urutan ini dipakai semua daftar
/// dan pemilih dompet.
///
/// Tidak ada di prototipe; disusun dari komponen yang ada (`AppFormHeader`,
/// `AppCard`, `AppListRow`, `AppStickyBar`). Mengembalikan id dompet aktif
/// dalam urutan baru lewat `Navigator.pop`, atau `null` kalau ditutup tanpa
/// disimpan. Dompet nonaktif tidak ikut diurutkan di sini.
class WalletReorderSheet extends StatefulWidget {
  /// Membuat [WalletReorderSheet].
  const WalletReorderSheet({required this.wallets, super.key});

  /// Dompet aktif dalam urutan sekarang.
  final List<Wallet> wallets;

  @override
  State<WalletReorderSheet> createState() => _WalletReorderSheetState();
}

class _WalletReorderSheetState extends State<WalletReorderSheet> {
  late final List<Wallet> _order = [...widget.wallets];

  void _onReorder(int oldIndex, int newIndex) {
    setState(() => _order.insert(newIndex, _order.removeAt(oldIndex)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, 0),
            child: AppFormHeader(title: t.wallet.reorderTitle),
          ),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, AppSpacing.space6),
              header: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: Text(t.wallet.reorderHint, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink2)),
              ),
              itemCount: _order.length,
              onReorderItem: _onReorder,
              itemBuilder: (context, index) {
                final wallet = _order[index];
                return Padding(
                  key: ValueKey(wallet.id),
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: ReorderableDelayedDragStartListener(
                    index: index,
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: AppListRow(
                        leading: AppIconTile(walletIconKey(wallet.iconKey)),
                        title: wallet.name,
                        subtitle: walletTypeLabel(wallet.iconKey),
                        trailing: ReorderableDragStartListener(
                          key: ValueKey('wallet-reorder-handle-${wallet.id}'),
                          index: index,
                          child: Semantics(
                            label: t.wallet.reorderHandleLabel(name: wallet.name),
                            child: SizedBox.square(
                              dimension: AppSize.touch,
                              child: Center(child: AppIcon(IconKey.dragHandle, color: colors.ink2)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          AppStickyBar(
            child: AppButton(
              key: const ValueKey('wallet-reorder-save'),
              label: t.wallet.reorderSaveAction,
              expand: true,
              onPressed: () => Navigator.of(context).pop([for (final w in _order) w.id]),
            ),
          ),
        ],
      ),
    );
  }
}
