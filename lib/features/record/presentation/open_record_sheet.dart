import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/expense_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/income_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/record_saving_dialog.dart';
import 'package:saldough/features/record/presentation/widgets/transfer_form_sheet.dart';
import 'package:state_management/state_management.dart';

/// Membuka alur CATAT: [RecordChoiceSheet] (tiga pilihan, FR-REC-001), lalu
/// satu dari tiga formulir, dalam LOOP -- menekan tombol kembali di formulir
/// mengembalikan `BackToChoice`, yang membuka ulang [RecordChoiceSheet]
/// alih-alih menutup seluruh alur.
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
/// dompet (T-2.8). Titik panggil ketiga: `WalletDetailPage`.
///
/// [initialChoice], kalau terisi, melewati lembar pilihan dan langsung
/// membuka formulir itu; [initialBudgetItemId] mengisi awal pos anggarannya
/// (FR-BUD-007/FR-REC-002, pintasan "Catat Pengeluaran"/"Catat Transfer" di
/// rincian anggaran, T-4.10). [initialAmountSen] mengisi awal nominal
/// pengeluaran/transfer (sisa pos anggaran). Menekan kembali di formulir tetap
/// membuka lembar pilihan — alurnya sama persis dengan CATAT biasa.
Future<void> openRecordSheet(
  BuildContext context, {
  String? initialWalletId,
  RecordChoice? initialChoice,
  String? initialBudgetItemId,
  int? initialAmountSen,
}) async {
  final bloc = context.read<RecordBloc>()..add(const RecordWalletsLoaded());
  await bloc.stream.firstWhere((s) => !s.isLoading);
  if (!context.mounted) return;
  // Kegagalan pemuatan sudah ditampilkan lewat efek galat `RecordBloc`
  // (snackbar dari `EffectListener`) -- jangan lanjut membuka lembar
  // pilihan, yang widget dompetnya akan salah menampilkan "belum ada
  // dompet" padahal masalahnya pembacaan yang gagal.
  if (bloc.state.loadFailed) return;

  var preselected = initialChoice;
  while (true) {
    final choice =
        preselected ??
        await showFullScreenSheet<RecordChoice>(
          context,
          builder: (_) => const RecordChoiceSheet(),
        );
    preselected = null;
    if (choice == null || !context.mounted) return;

    final wallets = bloc.state.wallets;
    final budgetItems = bloc.state.budgetItems;
    final result = await showFullScreenSheet<Object>(
      context,
      builder: (_) => switch (choice) {
        RecordChoice.income => IncomeFormSheet(
          wallets: wallets,
          initialWalletId: initialWalletId,
        ),
        RecordChoice.expense => ExpenseFormSheet(
          wallets: wallets,
          initialWalletId: initialWalletId,
          budgetItems: budgetItems,
          initialBudgetItemId: initialBudgetItemId,
          initialAmountSen: initialAmountSen,
        ),
        RecordChoice.transfer => TransferFormSheet(
          wallets: wallets,
          initialWalletId: initialWalletId,
          budgetItems: budgetItems,
          initialBudgetItemId: initialBudgetItemId,
          initialAmountSen: initialAmountSen,
        ),
      },
    );
    if (result == null || !context.mounted) return;
    if (result is BackToChoice) continue;
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
}
