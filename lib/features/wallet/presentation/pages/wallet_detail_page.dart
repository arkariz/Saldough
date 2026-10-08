import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_activity_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_activity_state.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
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
        :final initialBalance,
      ):
        bloc.add(
          WalletEdited(
            original: current,
            name: name,
            iconKey: iconKey,
            isActive: isActive,
            initialBalance: initialBalance,
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
            final current = walletState.wallets.firstWhere(
              (w) => w.id == wallet.id,
              orElse: () => wallet,
            );
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                _TopBar(onEdit: () => _edit(context, current)),
                const SizedBox(height: AppSpacing.space4),
                _HeroCard(wallet: current),
                const SizedBox(height: AppSpacing.space4),
                AppButton(
                  label: t.wallet.detailRecordAction,
                  onPressed: () => _record(context),
                ),
                const SizedBox(height: AppSpacing.space6),
                AppSectionLabel(t.wallet.detailRecentHeading),
                const SizedBox(height: AppSpacing.space1),
                BlocBuilder<WalletActivityBloc, WalletActivityState>(
                  builder: (context, activity) {
                    // Kerangka, bukan ruang kosong: kosong terbaca seperti
                    // "belum ada transaksi" padahal masih dimuat (T-7.6).
                    if (activity.isLoading) {
                      return Column(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(height: AppSpacing.space2),
                            const AppSkeleton(height: 64),
                          ],
                        ],
                      );
                    }
                    final touched = activity.transactions;
                    final recent = touched;
                    final walletsById = {
                      for (final w in walletState.wallets) w.id: w,
                    };
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MonthSummaryRow(
                          transactions: touched,
                          walletId: current.id,
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        if (recent.isEmpty)
                          const _EmptyRecentTransactions()
                        else
                          AppListCard(
                            children: [
                              for (final transaction in recent.take(5))
                                TransactionRow(
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
                const SizedBox(height: AppSpacing.space4),
                AppButton.secondary(
                  label: t.wallet.detailViewAllAction,
                  onPressed: () => _viewAllTransactions(context, current.id),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
