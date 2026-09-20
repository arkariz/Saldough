import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_empty_states.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_form_sheet.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_summary_card.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Layar Dompet (T-2.7; FR-WAL-001..003): total saldo dompet aktif, daftar
/// dompet dengan saldo tercatatnya, tambah dan sunting dompet, serta dompet
/// nonaktif di bagian tersendiri.
///
/// `WalletBloc` dipasang di level shell (bukan di halaman ini) karena tab
/// persisten selama shell hidup (`IndexedStack` membangun seluruh tab sekali).
/// Halaman memuat dompet sekali saat dibuat; saldo disegarkan tiap tab ini
/// dibuka serta sesudah alur CATAT (lihat `AppShellPage`).
///
/// Mengetuk kartu dompet membuka formulir sunting. Layar rincian dompet
/// (riwayat tersaring + pintasan CATAT) dibangun di T-2.8 dan akan menjadi
/// tujuan ketukan ini; sunting pindah ke dalamnya.
class WalletListPage extends StatefulWidget {
  /// Membuat [WalletListPage].
  const WalletListPage({super.key});

  @override
  State<WalletListPage> createState() => _WalletListPageState();
}

class _WalletListPageState extends State<WalletListPage> {
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(const WalletStarted());
  }

  Future<void> _openForm(BuildContext context, {Wallet? wallet}) async {
    final bloc = context.read<WalletBloc>();
    final result = await showFullScreenSheet<WalletFormResult>(
      context,
      builder: (_) => WalletFormSheet(initial: wallet),
    );
    switch (result) {
      case WalletFormSaved(:final name, :final iconKey, :final isActive, :final initialBalance):
        bloc.add(
          wallet == null
              ? WalletAdded(name: name, iconKey: iconKey, initialBalance: initialBalance ?? 0)
              : WalletEdited(
                  original: wallet,
                  name: name,
                  iconKey: iconKey,
                  isActive: isActive,
                  initialBalance: initialBalance,
                ),
        );
      case WalletFormDeleted():
        if (wallet != null) bloc.add(WalletDeleted(wallet));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.appShell.walletsTabLabel)),
      body: SafeArea(
        child: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            
            if (state.isLoading) return const AppSkeletonPage();
            if (state.loadFailed) {
              return WalletLoadErrorState(onRetry: () => context.read<WalletBloc>().add(const WalletStarted()));
            }
            if (state.wallets.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [WalletEmptyState(onAdd: () => _openForm(context))],
              );
            }

            final active = state.activeWallets;
            final inactive = state.inactiveWallets;
            final colors = context.appColors;
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
              children: [
                WalletSummaryCard(activeCount: active.length, totalBalance: state.totalBalance),
                const SizedBox(height: AppSpacing.md),
                AppSectionLabel(t.wallet.listHeading),
                const SizedBox(height: AppSpacing.xs),
                for (final wallet in active) ...[
                  WalletCard(
                    wallet: wallet,
                    onTap: () => _openForm(context, wallet: wallet),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.xs),
                AppButton(label: t.wallet.addAction, onPressed: () => _openForm(context)),
                if (inactive.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppSectionLabel(t.wallet.inactiveHeading),
                  const SizedBox(height: AppSpacing.xs),
                  for (final wallet in inactive) ...[
                    WalletCard(
                      wallet: wallet,
                      onTap: () => _openForm(context, wallet: wallet),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  t.wallet.privacyNote,
                  textAlign: TextAlign.center,
                  style: transactionLabelStyle(context, color: colors.textMuted).copyWith(fontWeight: FontWeight.w400),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
