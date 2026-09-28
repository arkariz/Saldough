import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/freelance/presentation/pages/freelance_overview_page.dart';
import 'package:saldough/features/record/domain/record_defaults.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/expense_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/income_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_host.dart';
import 'package:saldough/features/record/presentation/widgets/record_saving_dialog.dart';
import 'package:saldough/features/record/presentation/widgets/transfer_form_sheet.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:state_management/state_management.dart';

/// Membuka alur CATAT: satu lembar [RecordFormHost] yang langsung berisi
/// formulir Pengeluaran, dengan pengalih Keluar | Masuk | Transfer di atasnya
/// (UX-1, KO-5). Lembar pilihan edukasi yang dulu selalu mendahului formulir
/// sudah dihapus; isinya pindah ke onboarding (OB-3) dan tur CATAT.
/// Tombol kembali di formulir menutup alur.
///
/// Diekstrak dari `_AppShellPageState._openRecordSheet` (T-2.4) menjadi
/// fungsi tingkat atas supaya CATAT bisa dipicu dari lebih dari satu tempat
/// tanpa menduplikasi alurnya -- CLAUDE.md aturan 8: CATAT satu-satunya
/// jalur pembuatan transaksi manual, jangan membuat formulir pencatatan
/// tersendiri. Titik panggil pertama: `AppShellPage._onDestinationSelected`.
/// Titik panggil kedua (T-2.5): CTA keadaan kosong `TransactionListPage`
/// saat bulan berjalan genuinely belum punya transaksi.
///
/// [context] harus berada di keturunan `BlocProvider<RecordBloc>` (dipasang
/// sekali di `AppShellPage`, membungkus seluruh tab dan lembar yang
/// dibukanya) supaya `context.read<RecordBloc>()` di bawah ini menemukannya.
///
/// [initialWalletId], kalau terisi, mengisi awal dompet pada formulir yang
/// dipilih pengguna (FR-REC-002) -- pintasan kontekstual dari layar rincian
/// dompet (T-2.8). Titik panggil ketiga: `WalletDetailPage`. Tanpa pintasan,
/// dompet awal adalah satu-satunya dompet aktif, atau dompet terakhir yang
/// dipakai untuk jenis itu ([initialWalletFor], UX-2).
///
/// [initialChoice], kalau terisi, menentukan jenis yang terpilih saat lembar
/// dibuka (bawaannya pengeluaran); [initialBudgetItemId] mengisi awal pos anggarannya
/// (FR-BUD-007/FR-REC-002, pintasan "Catat Pengeluaran"/"Catat Transfer" di
/// rincian anggaran, T-4.10). [initialAmountSen] mengisi awal nominal
/// pengeluaran/transfer (sisa pos anggaran), dan [initialToWalletId] dompet
/// tujuan transfer (dompet tujuan pos transfer, ADR-018).
///
/// Kartu Freelance di formulir pemasukan menutup alur ini dan membuka
/// Ikhtisar Freelance ([OpenFreelance]); `Future` ini baru selesai sesudah
/// layar itu ditutup, supaya pemanggil menyegarkan saldo sesudah pembayaran
/// dicatat diterima.
///
/// [prefillFrom] (UX-4, "Catat lagi") menentukan jenis awal seperti
/// [initialChoice] (diturunkan dari tipe transaksinya) dan mengisi
/// nominal, kategori, catatan, dompet, dan pos anggaran dari transaksi itu
/// -- TAPI TETAP mode CATAT (transaksi BARU, bukan menimpa yang lama) dan
/// tanggalnya hari ini, bukan tanggal transaksi sumber. Kalau dompet
/// transaksi sumber sudah nonaktif, dropdown dompet formulir tampil kosong
/// (dompet nonaktif tidak ditawarkan CATAT) -- pemakai memilih dompet baru.
Future<void> openRecordSheet(
  BuildContext context, {
  String? initialWalletId,
  RecordChoice? initialChoice,
  String? initialBudgetItemId,
  int? initialAmountSen,
  String? initialToWalletId,
  Transaction? prefillFrom,
}) async {
  final bloc = context.read<RecordBloc>()..add(const RecordWalletsLoaded());
  await bloc.stream.firstWhere((s) => !s.isLoading);
  if (!context.mounted) return;
  // Kegagalan pemuatan sudah ditampilkan lewat efek galat `RecordBloc`
  // (snackbar dari `EffectListener`) -- jangan lanjut membuka lembar
  // pilihan, yang widget dompetnya akan salah menampilkan "belum ada
  // dompet" padahal masalahnya pembacaan yang gagal.
  if (bloc.state.loadFailed) return;

  final initial =
      initialChoice ??
      switch (prefillFrom) {
        IncomeTransaction() => RecordChoice.income,
        ExpenseTransaction() => RecordChoice.expense,
        TransferTransaction() => RecordChoice.transfer,
        null => RecordChoice.expense,
      };
  final wallets = bloc.state.wallets;
  final budgetItems = bloc.state.budgetItems;
  final defaults = bloc.state.defaults;
  final activeIds = [for (final wallet in wallets) wallet.id];
  String? walletFor(String? lastUsed) =>
      initialWalletFor(shortcut: initialWalletId, activeWalletIds: activeIds, lastUsed: lastUsed);
  final transferFrom = walletFor(defaults.transferFromWalletId);
  // Tujuan terakhir hanya dipakai kalau asalnya juga dari transfer terakhir.
  final transferTo =
      initialToWalletId ?? (transferFrom == defaults.transferFromWalletId ? defaults.transferToWalletId : null);
  // `is`, bukan `as` -- kalau pemakai mengganti jenis lewat pengalih, jenis
  // yang tidak cocok dengan `prefillFrom` cukup mendapat `null`.
  final incomePrefill = prefillFrom is IncomeTransaction ? prefillFrom : null;
  final expensePrefill = prefillFrom is ExpenseTransaction ? prefillFrom : null;
  final transferPrefill = prefillFrom is TransferTransaction ? prefillFrom : null;
  final result = await showFullScreenSheet<Object>(
    context,
    builder: (_) => RecordFormHost(
      initialChoice: initial,
      formFor: (choice, kindSwitcher) => switch (choice) {
        RecordChoice.income => IncomeFormSheet(
          wallets: wallets,
          prefill: incomePrefill,
          initialWalletId: walletFor(defaults.incomeWalletId),
          recentCategories: defaults.incomeCategories,
          kindSwitcher: kindSwitcher,
        ),
        RecordChoice.expense => ExpenseFormSheet(
          wallets: wallets,
          prefill: expensePrefill,
          initialWalletId: walletFor(defaults.expenseWalletId),
          recentCategories: defaults.expenseCategories,
          budgetItems: budgetItems,
          initialBudgetItemId: initialBudgetItemId,
          initialAmountSen: initialAmountSen,
          kindSwitcher: kindSwitcher,
        ),
        RecordChoice.transfer => TransferFormSheet(
          wallets: wallets,
          prefill: transferPrefill,
          initialWalletId: transferFrom,
          budgetItems: budgetItems,
          initialBudgetItemId: initialBudgetItemId,
          initialAmountSen: initialAmountSen,
          initialToWalletId: transferTo,
          kindSwitcher: kindSwitcher,
        ),
      },
    ),
  );
  if (result == null || !context.mounted) return;
  // CATAT → Pemasukan → Freelance (FR-FRL-005). Alur CATAT selesai;
  // pemanggil menyegarkan saldo sesudahnya seperti biasa.
  if (result is OpenFreelance) {
    await openFreelanceOverview(context);
    return;
  }
  if (result is RecordEvent) {
    bloc.add(result);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecordSavingDialog(bloc: bloc),
    );
    return;
  }
}
