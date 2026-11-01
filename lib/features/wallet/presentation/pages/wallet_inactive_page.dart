import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/features/wallet/presentation/navigation/wallet_route_keys.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_empty_states.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Daftar dompet nonaktif (Dompet v2, B-66): dibuka dari baris "Dompet
/// nonaktif" di tab Dompet. Mengetuk dompet membuka rinciannya, tempat dompet
/// bisa diaktifkan lagi. Bila tidak ada lagi dompet nonaktif, halaman
/// menutup sendiri.
class WalletInactivePage extends StatelessWidget {
  /// Membuat [WalletInactivePage].
  const WalletInactivePage({super.key});

  Widget _card(BuildContext context, Wallet wallet) => WalletBentoCard(
    wallet: wallet,
    onTap: () => context.pushRoute(WalletRouteKeys.detail, WalletDetailInput(wallet)),
  );

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
              padding: const EdgeInsets.fromLTRB(DsSpacing.md, DsSpacing.sm, DsSpacing.md, DsSpacing.xl),
              children: [
                for (var i = 0; i < state.inactiveWallets.length; i += 2) ...[
                  if (i > 0) const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _card(context, state.inactiveWallets[i])),
                        const SizedBox(width: 12),
                        Expanded(
                          child: i + 1 < state.inactiveWallets.length
                              ? _card(context, state.inactiveWallets[i + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
