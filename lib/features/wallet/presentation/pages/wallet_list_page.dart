import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/features/wallet/presentation/pages/wallet_detail_page.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_empty_states.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_form_sheet.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_summary_card.dart';
import 'package:state_management/state_management.dart';

/// Layar Dompet (T-2.7; FR-WAL-001..003): total saldo dompet aktif, daftar
/// dompet dengan saldo tercatatnya, tambah dompet, serta dompet nonaktif di
/// bagian tersendiri.
///
/// `WalletBloc` dipasang di level shell (bukan di halaman ini) karena tab
/// persisten selama shell hidup (`IndexedStack` membangun seluruh tab sekali).
/// Halaman memuat dompet sekali saat dibuat; saldo disegarkan tiap tab ini
/// dibuka serta sesudah alur CATAT (lihat `AppShellPage`).
///
/// Mengetuk kartu dompet membuka [WalletDetailPage] (T-2.8) -- rincian
/// dompet, riwayat tersaring bulan berjalan, sunting/hapus, dan pintasan
/// CATAT. Formulir sunting tidak lagi dibuka langsung dari sini.
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

  /// Membuka formulir TAMBAH dompet baru. Sunting/hapus dompet yang sudah
  /// ada pindah ke [WalletDetailPage] (T-2.8) -- kartu dompet membuka layar
  /// rincian, bukan langsung formulir sunting.
  Future<void> _addWallet(BuildContext context) async {
    final bloc = context.read<WalletBloc>();
    final result = await showFullScreenSheet<WalletFormResult>(
      context,
      builder: (_) => const WalletFormSheet(),
    );
    if (result case WalletFormSaved(
      :final name,
      :final iconKey,
      :final initialBalance,
    )) {
      bloc.add(
        WalletAdded(
          name: name,
          iconKey: iconKey,
          initialBalance: initialBalance ?? 0,
        ),
      );
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
              return WalletLoadErrorState(
                onRetry: () =>
                    context.read<WalletBloc>().add(const WalletStarted()),
              );
            }
            if (state.wallets.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [WalletEmptyState(onAdd: () => _addWallet(context))],
              );
            }

            final active = state.activeWallets;
            final inactive = state.inactiveWallets;
            final colors = context.appColors;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              children: [
                WalletSummaryCard(
                  activeCount: active.length,
                  totalBalance: state.totalBalance,
                ),
                const SizedBox(height: AppSpacing.md),
                AppSectionLabel(t.wallet.listHeading),
                const SizedBox(height: AppSpacing.xs),
                for (final wallet in active) ...[
                  WalletCard(
                    wallet: wallet,
                    onTap: () => openWalletDetail(context, wallet),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  label: t.wallet.addAction,
                  onPressed: () => _addWallet(context),
                ),
                if (inactive.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppSectionLabel(t.wallet.inactiveHeading),
                  const SizedBox(height: AppSpacing.xs),
                  for (final wallet in inactive) ...[
                    WalletCard(
                      wallet: wallet,
                      onTap: () => openWalletDetail(context, wallet),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  t.wallet.privacyNote,
                  textAlign: TextAlign.center,
                  style: transactionLabelStyle(
                    context,
                    color: colors.textMuted,
                  ).copyWith(fontWeight: FontWeight.w400),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
