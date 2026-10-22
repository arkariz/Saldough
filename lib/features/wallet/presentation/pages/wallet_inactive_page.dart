import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/features/wallet/presentation/navigation/wallet_route_keys.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_empty_states.dart';
import 'package:state_management/state_management.dart';

/// Daftar dompet nonaktif (Dompet v2, B-66): dibuka dari baris "Dompet
/// nonaktif" di tab Dompet. Mengetuk dompet membuka rinciannya, tempat dompet
/// bisa diaktifkan lagi. Bila tidak ada lagi dompet nonaktif, halaman
/// menutup sendiri.
class WalletInactivePage extends StatelessWidget {
  /// Membuat [WalletInactivePage].
  const WalletInactivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.wallet.inactiveHeading)),
      body: SafeArea(
        child: BlocConsumer<WalletBloc, WalletState>(
          listenWhen: (previous, current) =>
              previous.inactiveWallets.isNotEmpty && current.inactiveWallets.isEmpty && !current.isLoading,
          listener: (context, _) => Navigator.of(context).maybePop(),
          builder: (context, state) {
            if (state.isLoading) return const AppSkeletonPage();
            if (state.loadFailed) {
              return WalletLoadErrorState(onRetry: () => context.read<WalletBloc>().add(const WalletStarted()));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space2,
                AppSpacing.space4,
                AppSpacing.space12,
              ),
              children: [
                AppListCard(
                  children: [
                    for (final wallet in state.inactiveWallets)
                      WalletCard(
                        wallet: wallet,
                        onTap: () => context.pushRoute(WalletRouteKeys.detail, WalletDetailInput(wallet)),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
