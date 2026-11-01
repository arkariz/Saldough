import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/transaction/presentation/bloc/filtered_transactions_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/filtered_transactions_state.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Daftar tersaring satu periode, dibuka dari Analisis (T-19.3, F4/F5): judul
/// saringannya, jumlah dan total (sama dengan angka di Analisis), lalu
/// transaksinya per hari. Mengetuk transaksi membuka rinciannya; sunting lewat
/// CATAT, dan sekembalinya daftar sudah segar.
class FilteredTransactionsPage extends StatelessWidget {
  /// Membuat [FilteredTransactionsPage].
  const FilteredTransactionsPage({required this.input, super.key});

  /// Saringan yang dibuka.
  final TransactionFilterInput input;

  @override
  Widget build(BuildContext context) {
    final container = ScopeProvider.of(context);
    return BlocProvider<FilteredTransactionsBloc>(
      create: (_) => FilteredTransactionsBloc(
        transactionRepository: container<TransactionRepository>(),
        walletRepository: container<WalletRepository>(),
        ledgerChanges: container<LedgerChanges>(),
        filter: input.filter,
      )..add(const FilteredTransactionsStarted()),
      child: EffectListener<FilteredTransactionsBloc, FilteredTransactionsState>(
        child: Scaffold(
          appBar: AppBar(title: Text(input.title, style: context.ds.typography.headlineMd), centerTitle: false),
          body: SafeArea(child: _Body(input: input)),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.input});

  final TransactionFilterInput input;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return BlocBuilder<FilteredTransactionsBloc, FilteredTransactionsState>(
      builder: (context, state) {
        if (state.isLoading) return const AppSkeletonPage();
        if (state.loadFailed) {
          return DsErrorState(
            title: t.transaction.loadErrorTitle,
            retryLabel: t.common.retry,
            onRetry: () => context.read<FilteredTransactionsBloc>().add(const FilteredTransactionsStarted()),
          );
        }
        final income = input.filter.type == TransactionTypeFilter.income;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
          children: [
            DsCard(
              key: const ValueKey('filtered-summary'),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(input.subtitle, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                        Text(t.transaction.filteredCount(count: state.count), style: ds.typography.titleMd),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppMoneyText(state.total, size: MoneySize.large, color: income ? c.income : null),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.groups.isEmpty)
              DsCard(
                key: const ValueKey('filtered-empty'),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    DsIconTile.asset(asset: ClayIcons.emptyTray, size: DsIconTileSize.lg),
                    const SizedBox(height: 10),
                    Text(
                      t.transaction.filteredEmpty,
                      textAlign: TextAlign.center,
                      style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              )
            else
              for (final (i, group) in state.groups.indexed) ...[
                if (i > 0) const SizedBox(height: 24),
                TransactionDateGroupCard(
                  group: group,
                  walletsById: state.walletsById,
                  onTransactionTap: (transaction) =>
                      context.pushRoute(TransactionRouteKeys.detail, TransactionDetailInput(transaction)),
                ),
              ],
          ],
        );
      },
    );
  }
}
