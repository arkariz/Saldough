import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/presentation/navigation/budget_route_keys.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'transaction_detail_sections.dart';

/// Layar rincian satu transaksi (T-2.11, FR-TXN-006): jenis, nominal,
/// kategori, dompet, tanggal, catatan, beserta aksi ubah dan hapus (T-2.6,
/// FR-TXN-005) -- rujukan visual `pixel_kas_detail_transaksi_1`.
///
/// Transfer memakai judul "Transfer tercatat" dan tata letak Dari / Ke /
/// Jumlah. Kosakata yang menyiratkan aplikasi menjalankan transaksi
/// ("Transfer berhasil", "Pembayaran berhasil", "Kirim Uang") DILARANG di
/// mana pun -- Saldough hanya mencatat.
///
/// Baris "Anggaran" (T-4.11) tampil kalau transaksi tertaut ke pos anggaran
/// yang masih ada, beserta jalan ke rincian anggarannya.
///
/// TIDAK ditampilkan: "ID catatan" (transaksi tidak punya nomor tampilan)
/// dan kartu "Format Entri Transfer" (ilustrasi desain, bukan fitur).
///
/// Membaca dompet dari [TransactionBloc] (nama dan "saldo saat ini"), jadi
/// harus berada di bawah `BlocProvider<TransactionBloc>` -- dipasang
/// `TransactionRouteModule` bersama `TransactionScope` milik rute ini
/// (ADR-030 §3.3). Sunting dan hapus menunggu hasilnya sebelum layar ini
/// ditutup, supaya snackbar hasilnya tampil walau bloc rute ini ikut
/// tertutup sesudahnya.
class TransactionDetailPage extends StatelessWidget {
  /// Membuat [TransactionDetailPage] untuk [transaction].
  const TransactionDetailPage({required this.transaction, super.key});

  /// Transaksi yang ditampilkan (cuplikan saat layar dibuka; layar ini
  /// ditutup setelah sunting/hapus, jadi tidak perlu mengikuti perubahan).
  final Transaction transaction;

  Set<String> get _walletIds => switch (transaction) {
    IncomeTransaction(:final walletId) => {walletId},
    ExpenseTransaction(:final walletId) => {walletId},
    TransferTransaction(:final fromWalletId, :final toWalletId) => {fromWalletId, toWalletId},
  };

  Future<void> _edit(BuildContext context, TransactionState state) async {
    final bloc = context.read<TransactionBloc>();
    final navigator = Navigator.of(context);
    // Dompet nonaktif tetap ditawarkan kalau transaksi ini memakainya, supaya
    // pilihan awal formulir tidak hilang.
    final wallets = [
      for (final w in state.wallets)
        if (w.isActive || _walletIds.contains(w.id)) w,
    ];
    final updated = await context.pushRoute<RecordEditInput, Transaction>(
      RecordRouteKeys.edit,
      RecordEditInput(transaction: transaction, wallets: wallets, budgetItems: state.budgetItems),
    );
    if (updated == null || updated == transaction) return;
    bloc.add(TransactionUpdated(original: transaction, updated: updated));
    await bloc.stream.firstWhere((s) => s.effect != null);
    navigator.pop();
  }

  /// Jalan ke rincian anggaran [item] (T-4.11). Pos yang ditawarkan katalog
  /// selalu milik anggaran yang masih ada.
  VoidCallback _budgetOpener(BuildContext context, BudgetItemOption item) =>
      () => context.pushRoute(BudgetRouteKeys.detail, BudgetDetailInput(budgetId: item.budgetId));

  /// "Catat lagi" (UX-4): membuka CATAT terisi dari transaksi ini, tapi
  /// sebagai transaksi BARU bertanggal hari ini -- lewat `openRecordSheet`
  /// yang sama seperti alur CATAT biasa (CLAUDE.md aturan 8), bukan
  /// formulir pencatatan tersendiri.
  Future<void> _recordAgain(BuildContext context) =>
      context.pushRoute(RecordRouteKeys.sheet, RecordSheetInput(prefillFrom: transaction));

  /// **Jadikan Rutin** (T-15.3, J2): CATAT mode jadwal terisi dari
  /// transaksi ini, yang lalu ditautkan sebagai kemunculan pertama. Rincian
  /// ini ditutup sesudahnya karena transaksinya sudah berubah (bertaut).
  Future<void> _makeRecurring(BuildContext context) async {
    final navigator = Navigator.of(context);
    final saved = await context.pushRoute<RecordSheetInput, bool>(
      RecordRouteKeys.sheet,
      RecordSheetInput(makeRecurringFrom: transaction),
    );
    if (saved ?? false) navigator.pop();
  }

  /// UX-8: hapus LANGSUNG tanpa dialog konfirmasi -- pemakai bisa
  /// mengurungkannya lewat aksi "Urungkan" pada snackbar yang tampil
  /// sesudahnya (`TransactionBloc._effectDeletedWithUndo`). Konfirmasi
  /// tetap dipakai untuk hapus dompet, anggaran, dan proyek (keputusan
  /// pemilik, UX_REVIEW_FIXES.md UX-8) -- transaksi TIDAK bisa dibatalkan
  /// tak bisa dibalik, karena Urungkan menyimpannya kembali persis (id
  /// sama, saldo dihitung ulang).
  Future<void> _delete(BuildContext context) async {
    final bloc = context.read<TransactionBloc>();
    final navigator = Navigator.of(context);
    bloc.add(TransactionDeleted(transaction));
    await bloc.stream.firstWhere((s) => s.effect != null);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            // Bloc milik rute ini baru dimuat: tanpa kerangka, nama dompet
            // sempat tampil kosong.
            if (state.isLoading) return const AppSkeletonPage();
            final walletsById = {for (final wallet in state.wallets) wallet.id: wallet};
            final budgetItem = state.budgetItemOf(switch (transaction) {
              ExpenseTransaction(:final budgetItemId) || TransferTransaction(:final budgetItemId) => budgetItemId,
              IncomeTransaction() => null,
            });
            // Pemasukan milik pembayaran freelance hanya diubah lewat
            // pembayarannya (ADR-019): tanpa sunting dan hapus di sini.
            final ownedByFreelance = switch (transaction) {
              IncomeTransaction(isFreelancePayment: true) => true,
              _ => false,
            };
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (ownedByFreelance)
                  const _TopBar()
                else
                  _TopBar(onEdit: () => _edit(context, state), onDelete: () => _delete(context)),
                const SizedBox(height: AppSpacing.md),
                _HeroCard(transaction: transaction),
                const SizedBox(height: AppSpacing.md),
                _DetailsCard(
                  transaction: transaction,
                  walletsById: walletsById,
                  budgetItem: budgetItem,
                  onOpenBudget: budgetItem == null ? null : _budgetOpener(context, budgetItem),
                ),
                const SizedBox(height: AppSpacing.md),
                if (ownedByFreelance)
                  _ManualNote(text: t.transaction.detailFreelanceNote)
                else ...[
                  _ManualNote(text: t.transaction.detailManualNote),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(label: t.transaction.editAction, onPressed: () => _edit(context, state)),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.secondary(
                    label: t.transaction.recordAgainAction,
                    onPressed: () => _recordAgain(context),
                  ),
                  if (transaction.recurrence == null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppButton.secondary(
                      label: t.transaction.makeRecurringAction,
                      onPressed: () => _makeRecurring(context),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  _DeleteLink(onPressed: () => _delete(context)),
                ],
                const SizedBox(height: AppSpacing.md),
              ],
            );
          },
        ),
      ),
    );
  }
}
