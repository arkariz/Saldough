import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_activity_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_activity_state.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/features/wallet/presentation/wallet_shares.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_form_sheet.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_type.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'wallet_detail_sections.dart';

/// Layar rincian satu dompet (T-2.8, FR-WAL-004): nama, ikon, saldo tercatat,
/// transaksi bulan ini yang menyentuh dompet ini, jalan ke daftar transaksi
/// lengkap tersaring, dan pintasan CATAT dengan dompet ini sudah terpilih
/// (FR-REC-002).
///
/// Membaca dompet dari `WalletBloc` milik rutenya (`WalletRouteModule`,
/// ADR-030 §3.3), bukan [wallet] langsung, supaya saldo yang berubah lewat
/// CATAT (pintasan di layar ini sendiri) tampil segar tanpa menutup layar
/// ini -- [wallet] hanya cadangan sebelum `WalletBloc` sempat memancarkan
/// salinan terbarunya. Riwayat bulan ini dari `WalletActivityBloc`.
/// Menyunting MENUTUP layar ini sesudah hasilnya tampil (lihat `_edit`);
/// tab Dompet di belakangnya segar lewat `LedgerChanges`.
///
/// ⚠ Riwayat di sini HANYA transaksi BULAN BERJALAN, sama seperti tab
/// Transaksi (ADR-012 -- buku besar dipartisi per bulan, `listAllTransactions`
/// reserved untuk penghitungan ulang saldo, bukan untuk merender layar).
class WalletDetailPage extends StatelessWidget {
  /// Membuat [WalletDetailPage] untuk [wallet].
  const WalletDetailPage({required this.wallet, super.key});

  /// Dompet yang ditampilkan (cuplikan saat layar dibuka).
  final Wallet wallet;

  /// Riwayat dan saldo di layar ini dimuat ulang oleh `LedgerChanges`
  /// sesudah transaksinya tersimpan (ADR-030 §3.4).
  Future<void> _record(BuildContext context) =>
      context.pushRoute(RecordRouteKeys.sheet, RecordSheetInput(initialWalletId: wallet.id));

  /// Sunting selalu menutup layar ini sesudah hasilnya tampil (bloc rute ini
  /// ikut tertutup; pola yang sama seperti `TransactionDetailPage._edit`).
  /// Hapus BEDA: baru menutup layar ini
  /// kalau penghapusan sungguhan berhasil, karena bisa diblokir (dompet
  /// sudah punya transaksi) dan layar rincian harus tetap menampilkan
  /// dompet yang masih ada beserta pesan blokirnya.
  Future<void> _edit(BuildContext context, Wallet current) async {
    final bloc = context.read<WalletBloc>();
    final navigator = Navigator.of(context);
    final result = await showFullScreenSheet<WalletFormResult>(
      context,
      builder: (_) => WalletFormSheet(initial: current),
    );
    switch (result) {
      case WalletFormSaved(
        :final name,
        :final iconKey,
        :final isActive,
        :final balance,
      ):
        bloc.add(
          WalletEdited(
            original: current,
            name: name,
            iconKey: iconKey,
            isActive: isActive,
            currentBalance: balance,
          ),
        );
        await bloc.stream.firstWhere((s) => s.effect != null);
        navigator.pop();
      case WalletFormDeleted():
        bloc.add(WalletDeleted(current));
        final state = await bloc.stream.firstWhere((s) => s.effect != null);
        if (!state.wallets.any((w) => w.id == current.id)) navigator.pop();
      case null:
        break;
    }
  }

  /// Catat Transfer dengan dompet ini sebagai asal (aturan 8: lewat CATAT).
  Future<void> _recordTransfer(BuildContext context) => context.pushRoute(
    RecordRouteKeys.sheet,
    RecordSheetInput(initialWalletId: wallet.id, initialChoice: RecordChoice.transfer),
  );

  /// Riwayat tersaring dompet ini, terpisah dari tab Riwayat: penyaringnya
  /// tidak lagi terbawa ke tab itu (ADR-030 §3.3).
  Future<void> _viewAllTransactions(BuildContext context, String walletId) =>
      context.pushRoute(TransactionRouteKeys.history, TransactionHistoryInput(walletId: walletId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, walletState) {
            final current = walletState.wallets.firstWhere((w) => w.id == wallet.id, orElse: () => wallet);
            final share = walletShares(walletState.activeWallets)[current.id];
            return ListView(
              padding: const EdgeInsets.all(DsSpacing.md),
              children: [
                _TopBar(onEdit: () => _edit(context, current)),
                const SizedBox(height: DsSpacing.sm),
                BlocBuilder<WalletActivityBloc, WalletActivityState>(
                  buildWhen: (a, b) => a.transactions != b.transactions || a.isLoading != b.isLoading,
                  builder: (context, activity) => _Hero(
                    wallet: current,
                    shareText: current.isActive ? share?.text : null,
                    totals: activity.isLoading ? null : _MonthTotals.of(activity.transactions, current.id),
                  ),
                ),
                const SizedBox(height: DsSpacing.stack),
                _QuickActions(
                  onRecord: () => _record(context),
                  onTransfer: () => _recordTransfer(context),
                  onHistory: () => _viewAllTransactions(context, current.id),
                ),
                const SizedBox(height: DsSpacing.lg),
                BlocBuilder<WalletActivityBloc, WalletActivityState>(
                  builder: (context, activity) {
                    // Kerangka, bukan ruang kosong: kosong terbaca seperti
                    // "belum ada transaksi" padahal masih dimuat (T-7.6).
                    if (activity.isLoading) {
                      return Column(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(height: DsSpacing.sm),
                            const DsSkeleton(height: 64, radius: DsRadius.lgAll),
                          ],
                        ],
                      );
                    }
                    final touched = activity.transactions;
                    final walletsById = {for (final w in walletState.wallets) w.id: w};
                    final totals = _MonthTotals.of(touched, current.id);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MonthSummary(totals: totals),
                        const SizedBox(height: DsSpacing.lg),
                        DsSectionHeader(
                          title: t.wallet.detailRecentHeading,
                          icon: Icons.receipt_long,
                          actionLabel: touched.length > 5 ? t.wallet.detailViewAllAction : null,
                          onAction: touched.length > 5 ? () => _viewAllTransactions(context, current.id) : null,
                        ),
                        const SizedBox(height: DsSpacing.sm),
                        if (touched.isEmpty)
                          const _EmptyRecentTransactions()
                        else
                          DsListCard(
                            children: [
                              for (final transaction in touched.take(5))
                                TransactionLedgerRow(
                                  transaction: transaction,
                                  walletsById: walletsById,
                                  onTap: () => context.pushRoute(
                                    TransactionRouteKeys.detail,
                                    TransactionDetailInput(transaction),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
