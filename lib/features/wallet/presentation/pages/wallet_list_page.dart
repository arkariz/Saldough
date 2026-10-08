import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/features/wallet/presentation/navigation/wallet_route_keys.dart';
import 'package:saldough/features/wallet/presentation/wallet_shares.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_empty_states.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_form_sheet.dart';
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
  Future<void> _addWallet(BuildContext context) => openAddWalletSheet(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.appShell.walletsTabLabel, style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: false,
        actions: [
          const TutorialInfoButton(tour: TourId.wallet),
          AppIconButton(icon: IconKey.add, label: t.wallet.addAction, onPressed: () => _addWallet(context)),
        ],
      ),
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
                padding: const EdgeInsets.all(AppSpacing.space4),
                children: [WalletEmptyState(onAdd: () => _addWallet(context))],
              );
            }

            final active = state.activeWallets;
            final inactive = state.inactiveWallets;
            final colors = context.appColors;
            final textTheme = Theme.of(context).textTheme;
            final shares = walletShares(active);
            // TR-WALLET (ADR-021 §3.4): ringkasan, dompet pertama, tambah.
            return TourTrigger(
              tour: TourId.wallet,
              ready: true,
              child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space2,
                AppSpacing.space4,
                AppSpacing.space12,
              ),
              children: [
                // Prototipe `Dompet.dc.html`: angka utama di atas `bg` tanpa
                // kartu, lalu bar sebaran saldo per dompet.
                SpotlightTarget(
                  spotlightKey: SpotlightKey.walletSummary,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.space1, AppSpacing.space1, AppSpacing.space1, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(t.home.balanceLabel, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
                        HeroAmount(AppMoneyFormatter.format(state.totalBalance)),
                        Text(
                          t.wallet.activeBadge(count: active.length),
                          style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                        ),
                        const SizedBox(height: AppSpacing.space3),
                        WalletSpreadBar(wallets: active, shares: shares),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space6),
                AppSectionHeader(t.wallet.listHeading),
                const SizedBox(height: AppSpacing.space2),
                AppListCard(
                  children: [
                    for (final (i, wallet) in active.indexed)
                      SpotlightTarget(
                        // Hanya dompet pertama yang disorot.
                        spotlightKey: i == 0 ? SpotlightKey.walletCard : null,
                        child: WalletCard(
                          wallet: wallet,
                          sharePercent: shares[wallet.id],
                          onTap: () => context.pushRoute(WalletRouteKeys.detail, WalletDetailInput(wallet)),
                        ),
                      ),
                  ],
                ),
                if (inactive.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space6),
                  AppSectionHeader(t.wallet.inactiveHeading),
                  const SizedBox(height: AppSpacing.space2),
                  AppListCard(
                    children: [
                      for (final wallet in inactive)
                        WalletCard(
                          wallet: wallet,
                          onTap: () => context.pushRoute(WalletRouteKeys.detail, WalletDetailInput(wallet)),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.space6),
                SpotlightTarget(
                  spotlightKey: SpotlightKey.walletAdd,
                  child: AppButton.secondary(
                    label: t.wallet.addAction,
                    icon: IconKey.add,
                    expand: true,
                    onPressed: () => _addWallet(context),
                  ),
                ),
              ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Membuka formulir TAMBAH dompet dan, kalau disimpan, menunggu sampai
/// [WalletBloc] selesai memproses simpanannya. Dipakai tab Dompet dan ajakan
/// "Buat Dompet Pertama" onboarding (ADR-021 §3.2) -- satu formulir yang sama,
/// bukan formulir baru. [context] harus berada di bawah `BlocProvider<WalletBloc>`.
Future<void> openAddWalletSheet(BuildContext context) async {
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
    final processed = bloc.stream.first;
    bloc.add(
      WalletAdded(
        name: name,
        iconKey: iconKey,
        initialBalance: initialBalance ?? 0,
      ),
    );
    await processed;
  }
}
