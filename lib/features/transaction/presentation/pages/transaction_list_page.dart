import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/open_record_sheet.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_date_group_card.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_empty_states.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_filter_bar.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_month_header.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Layar riwayat transaksi (T-2.5, FR-TXN-004) -- tab "Transaksi" di
/// `AppShellPage`. Menampilkan transaksi bulan berjalan, terbaru dulu,
/// dikelompokkan per tanggal, dengan penyaring jenis, dompet, dan kategori.
///
/// Pencarian teks mencocokkan kategori, catatan, dan nama dompet. Ilustrasi
/// "streak" dan tanda tren "vs bulan lalu" pada rujukan visual TIDAK dibangun
/// -- keduanya bukan bagian FR-TXN-004.
///
/// Baris transaksi TIDAK bisa diketuk -- T-2.11 (layar rincian transaksi)
/// belum ada, lihat `TransactionRow`.
class TransactionListPage extends StatefulWidget {
  /// Membuat [TransactionListPage].
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(const TransactionStarted());
  }

  void _clearFilters() {
    context.read<TransactionBloc>()
      ..add(const TransactionSearchChanged(''))
      ..add(const TransactionTypeFilterChanged(TransactionTypeFilter.all))
      ..add(const TransactionWalletFilterChanged(null))
      ..add(const TransactionCategoryFilterChanged(null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.transaction.pageTitle)),
      body: SafeArea(
        child: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            if (state.isLoading) return const AppSkeletonPage();

            if (state.loadFailed) {
              return TransactionLoadErrorState(
                onRetry: () => context.read<TransactionBloc>().add(
                  const TransactionStarted(),
                ),
              );
            }

            final walletsById = {
              for (final wallet in state.wallets) wallet.id: wallet,
            };

            final bloc = context.read<TransactionBloc>();
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TransactionMonthHeader(
                          month: state.month,
                          rawTransactions: state.rawTransactions,
                          onPreviousMonth: () => bloc.add(
                            TransactionMonthChanged(
                              DateTime(state.month.year, state.month.month - 1),
                            ),
                          ),
                          onNextMonth: () => bloc.add(
                            TransactionMonthChanged(
                              DateTime(state.month.year, state.month.month + 1),
                            ),
                          ),
                        ),
                        // Pencarian, dompet, dan kategori TETAP disembunyikan
                        // saat bulan ini genuinely kosong (tidak ada gunanya
                        // menyaring nol transaksi, dan rujukan visual
                        // `pixel_kas_riwayat_transaksi_kosong` juga tidak
                        // menampilkannya). Baris filter jenis tetap tampil
                        // dengan angka nol ("Semua 0").
                        if (state.rawTransactions.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          TransactionSearchField(
                            query: state.searchQuery,
                            onQueryChanged: (query) => bloc.add(TransactionSearchChanged(query)),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TransactionWalletCategoryRow(
                            wallets: state.wallets,
                            walletFilter: state.walletFilter,
                            onWalletChanged: (id) => bloc.add(TransactionWalletFilterChanged(id)),
                            categoryOptions: state.categoryOptions,
                            categoryFilter: state.categoryFilter,
                            onCategoryChanged: (key) => bloc.add(TransactionCategoryFilterChanged(key)),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        TransactionTypeFilterRow(
                          typeFilter: state.typeFilter,
                          typeCounts: state.typeCounts,
                          onChanged: (filter) => bloc.add(TransactionTypeFilterChanged(filter)),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
                _Body(
                  state: state,
                  walletsById: walletsById,
                  onClearFilters: _clearFilters,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.walletsById,
    required this.onClearFilters,
  });

  final TransactionState state;
  final Map<String, Wallet> walletsById;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (state.rawTransactions.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        sliver: SliverToBoxAdapter(
          child: TransactionEmptyMonthState(
            onRecord: () => openRecordSheet(context),
          ),
        ),
      );
    }
    if (state.groups.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: TransactionEmptyFilterState(onClearFilters: onClearFilters),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      sliver: SliverList.separated(
        itemCount: state.groups.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, index) => TransactionDateGroupCard(
          group: state.groups[index],
          walletsById: walletsById,
        ),
      ),
    );
  }
}
