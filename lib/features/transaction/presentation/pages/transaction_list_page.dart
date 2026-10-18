import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/transaction/domain/history_segment.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_empty_states.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_filter_bar.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_period_header.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Layar riwayat transaksi (T-2.5, FR-TXN-004) -- tab "Riwayat" di
/// `AppShellPage`. Menampilkan transaksi bulan berjalan, terbaru dulu,
/// dikelompokkan per tanggal, dengan penyaring jenis, dompet, dan kategori.
///
/// Pencarian teks mencocokkan kategori, catatan, dan nama dompet. Ilustrasi
/// "streak" dan tanda tren "vs bulan lalu" pada rujukan visual TIDAK dibangun
/// -- keduanya bukan bagian FR-TXN-004.
///
/// Baris transaksi bisa diketuk dan membuka `TransactionDetailPage` (T-2.11),
/// tempat sunting dan hapus (T-2.6).
class TransactionListPage extends StatefulWidget {
  /// Membuat [TransactionListPage].
  const TransactionListPage({this.notice, this.analysis, this.segmentRepository, super.key});

  /// Banner kotak masuk notifikasi, disisipkan akar komposisi (prototipe
  /// `Riwayat.dc.html`); `null` = tidak ada.
  final Widget? notice;

  /// Isi segmen Analisis, disisipkan akar komposisi (ADR-030: `transaction` tidak
  /// mengimpor `analysis`). `null` = tanpa segmen, hanya daftar.
  final Widget? analysis;

  /// Pengingat segmen terakhir; `null` = selalu mulai di Daftar.
  final HistorySegmentRepository? segmentRepository;

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  /// Segmen terpilih; `null` sampai preferensinya terbaca.
  HistorySegment? _segment;

  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(const TransactionStarted());
    if (widget.analysis == null) {
      _segment = HistorySegment.list;
    } else if (widget.segmentRepository case final repository?) {
      unawaited(_restoreSegment(repository));
    } else {
      _segment = HistorySegment.list;
    }
  }

  Future<void> _restoreSegment(HistorySegmentRepository repository) async {
    final saved = (await repository.load()).getOrElse((_) => HistorySegment.list);
    if (mounted) setState(() => _segment = saved);
  }

  void _selectSegment(HistorySegment segment) {
    if (segment == _segment) return;
    setState(() => _segment = segment);
    if (widget.segmentRepository case final repository?) unawaited(repository.save(segment));
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
      appBar: AppBar(
        title: Text(t.transaction.pageTitle, style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: false,
        actions: const [TutorialInfoButton(tour: TourId.transaction)],
        // Daftar | Analisis (A1, SubTabs): navigasi, isi di bawahnya berganti seluruhnya.
        bottom: widget.analysis == null || _segment == null
            ? null
            : AppSubTabs<HistorySegment>(
                options: [
                  (HistorySegment.list, t.transaction.listSegment),
                  (HistorySegment.analysis, t.analysis.segment),
                ],
                selected: _segment!,
                onChanged: _selectSegment,
                tabWrap: (segment, tab) => SpotlightTarget(
                  spotlightKey: segment == HistorySegment.analysis ? SpotlightKey.txnAnalysisSegment : null,
                  child: tab,
                ),
              ),
      ),
      body: SafeArea(
        child: _segment == null
            ? const AppSkeletonPage()
            : _segment == HistorySegment.analysis
            ? widget.analysis!
            : BlocBuilder<TransactionBloc, TransactionState>(
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
            // TR-TXN (ADR-021 §3.4): hanya saat bulan ini punya transaksi.
            return TourTrigger(
              tour: TourId.transaction,
              ready: state.rawTransactions.isNotEmpty,
              child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space4,
                    AppSpacing.space4,
                    AppSpacing.space4,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SpotlightTarget(
                          spotlightKey: SpotlightKey.txnMonth,
                          child: TransactionPeriodHeader(
                            period: state.period,
                            rawTransactions: state.rawTransactions,
                            onPrevious: state.canGoBack
                                ? () => bloc.add(const TransactionPeriodStepped(forward: false))
                                : null,
                            onNext: state.isCurrent
                                ? null
                                : () => bloc.add(const TransactionPeriodStepped(forward: true)),
                          ),
                        ),
                        // Pencarian, dompet, dan kategori TETAP disembunyikan
                        // saat bulan ini genuinely kosong (tidak ada gunanya
                        // menyaring nol transaksi, dan rujukan visual
                        // `pixel_kas_riwayat_transaksi_kosong` juga tidak
                        // menampilkannya). Baris filter jenis tetap tampil
                        // dengan angka nol ("Semua 0").
                        if (state.rawTransactions.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.space4),
                          // UX-21: dompet dan kategori digabung ke SATU
                          // tombol "Filter" di samping kolom cari (dulu
                          // baris dropdown terpisah di bawahnya) supaya kop
                          // Transaksi lebih pendek.
                          SpotlightTarget(
                            spotlightKey: SpotlightKey.txnFilter,
                            child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TransactionSearchField(
                                  query: state.searchQuery,
                                  onQueryChanged: (query) => bloc.add(TransactionSearchChanged(query)),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.space1),
                              TransactionFilterButton(
                                wallets: state.wallets,
                                walletFilter: state.walletFilter,
                                onWalletChanged: (id) => bloc.add(TransactionWalletFilterChanged(id)),
                                categoryOptions: state.categoryOptions,
                                categoryFilter: state.categoryFilter,
                                onCategoryChanged: (key) => bloc.add(TransactionCategoryFilterChanged(key)),
                              ),
                            ],
                          ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.space2),
                        TransactionTypeFilterRow(
                          typeFilter: state.typeFilter,
                          typeCounts: state.typeCounts,
                          onChanged: (filter) => bloc.add(TransactionTypeFilterChanged(filter)),
                        ),
                        ?widget.notice,
                        const SizedBox(height: AppSpacing.space4),
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
              ),
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
          AppSpacing.space4,
          0,
          AppSpacing.space4,
          AppSpacing.space12,
        ),
        sliver: SliverToBoxAdapter(
          child: TransactionEmptyMonthState(
            // Daftar dimuat ulang oleh `LedgerChanges` (ADR-030 §3.4).
            onRecord: () => context.pushRoute(RecordRouteKeys.sheet, const RecordSheetInput()),
          ),
        ),
      );
    }
    if (state.groups.isEmpty) {
      // Bukan `SliverFillRemaining`: ia meminta dimensi intrinsik, dan kartu hasil
      // pencarian lintas periode memakai `LayoutBuilder` (galat layout, T-19.12).
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.space4, 0, AppSpacing.space4, AppSpacing.space12),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              TransactionEmptyFilterState(onClearFilters: onClearFilters),
              if (state.searchQuery.trim().isNotEmpty) _crossMonthSection(context),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        0,
        AppSpacing.space4,
        AppSpacing.space12,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverList.separated(
            itemCount: state.groups.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space6),
            itemBuilder: (context, index) => TransactionDateGroupCard(
              group: state.groups[index],
              walletsById: walletsById,
              onTransactionTap: (transaction) =>
                        context.pushRoute(TransactionRouteKeys.detail, TransactionDetailInput(transaction)),
              firstRowSpotlightKey: index == 0 ? SpotlightKey.txnRow : null,
            ),
          ),
          // Mencari di periode lain tetap ditawarkan walau periode ini punya hasil (T-19.12).
          if (state.searchQuery.trim().isNotEmpty) SliverToBoxAdapter(child: _crossMonthSection(context)),
        ],
      ),
    );
  }

  /// Pencarian lintas periode (T-8.2): tombol "Cari di bulan lain", pemindaian,
  /// dan hasilnya. Aktif hanya saat kata kunci pencarian terisi.
  Widget _crossMonthSection(BuildContext context) {
    final bloc = context.read<TransactionBloc>();
    return TransactionCrossMonthSearchSection(
      hasScanned: state.crossMonthScannedMonths.isNotEmpty,
      isSearching: state.isSearchingCrossMonth,
      exhausted: state.crossMonthExhausted,
      groups: state.crossMonthGroups,
      walletsById: walletsById,
      onSearch: () => bloc.add(const TransactionSearchAcrossMonthsRequested()),
      onTransactionTap: (transaction) =>
          context.pushRoute(TransactionRouteKeys.detail, TransactionDetailInput(transaction)),
    );
  }
}
