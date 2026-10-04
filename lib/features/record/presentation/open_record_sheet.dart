import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/freelance/presentation/navigation/freelance_route_keys.dart';
import 'package:saldough/features/record/domain/record_defaults.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/expense_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/income_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_host.dart';
import 'package:saldough/features/record/presentation/widgets/record_saving_dialog.dart';
import 'package:saldough/features/record/presentation/widgets/transfer_form_sheet.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
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
///
/// [draft] (Catat Cerdas, ADR-027 §3.4) menentukan jenis awal dan mengisi
/// formulirnya, sama seperti [prefillFrom]: tetap mode CATAT, dan tidak ada
/// yang tersimpan sebelum pengguna menekan Catat. Untuk transfer, dompet asal
/// dan tujuan hanya diambil dari draf -- tanpa dompet bawaan.
///
/// [initialRepeat] membuka CATAT dalam mode jadwal (T-15.3, chip pembuka).
/// [makeRecurringFrom] (**Jadikan Rutin**, J2) mengisi formulir dari
/// transaksi itu, termasuk tanggalnya, mengunci Ulangi dan jenisnya, lalu
/// menautkan transaksi itu sebagai kemunculan pertama rutin baru -- tidak
/// ada transaksi baru yang tercatat.
///
/// Mengembalikan `true` bila transaksi benar-benar tersimpan (kotak masuk
/// Catat dari notifikasi menghapus itemnya hanya saat itu, ADR-032 §3.6).
Future<bool> openRecordSheet(
  BuildContext context, {
  String? initialWalletId,
  RecordChoice? initialChoice,
  String? initialBudgetItemId,
  int? initialAmountSen,
  String? initialToWalletId,
  Transaction? prefillFrom,
  RecordDraft? draft,
  RecurringPattern? initialRepeat,
  Transaction? makeRecurringFrom,
  RecurringRule? editRule,
  RecurringRule? occurrenceRule,
  DateTime? occurrenceDate,
}) async {
  final recordDraft = switch ((makeRecurringFrom, editRule)) {
    (final Transaction source, _) => draftFromTransaction(source),
    (_, final RecurringRule rule) => draftFromRule(rule),
    // Kotak masuk notifikasi membawa drafnya sendiri; kartu Menunggu tidak.
    _ when occurrenceRule != null && occurrenceDate != null =>
      draft ?? draftFromRule(occurrenceRule, date: occurrenceDate),
    _ => draft,
  };
  final occurrence = occurrenceRule != null && occurrenceDate != null
      ? (rule: occurrenceRule, date: occurrenceDate)
      : null;
  final repeat =
      initialRepeat ??
      (editRule != null ? RecurringPattern.of(editRule) : (makeRecurringFrom != null ? const RecurringPattern() : null));
  final repeatLocked = makeRecurringFrom != null || editRule != null;
  final scheduleOnly = editRule != null;
  final bloc = context.read<RecordBloc>()..add(const RecordWalletsLoaded());
  await bloc.stream.firstWhere((s) => !s.isLoading);
  if (!context.mounted) return false;
  // Kegagalan pemuatan sudah ditampilkan lewat efek galat `RecordBloc`
  // (snackbar dari `EffectListener`) -- jangan lanjut membuka lembar
  // pilihan, yang widget dompetnya akan salah menampilkan "belum ada
  // dompet" padahal masalahnya pembacaan yang gagal.
  if (bloc.state.loadFailed) return false;

  final initial =
      initialChoice ??
      switch (recordDraft?.kind) {
        DraftKind.income => RecordChoice.income,
        DraftKind.expense => RecordChoice.expense,
        DraftKind.transfer => RecordChoice.transfer,
        null => null,
      } ??
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
      formFor: (choice, switcher) {
        // Jadikan Rutin: jenisnya mengikuti transaksi asal, tidak bisa diganti.
        final kindSwitcher = repeatLocked ? null : switcher;
        return switch (choice) {
          RecordChoice.income => IncomeFormSheet(
            wallets: wallets,
            prefill: incomePrefill,
            draft: recordDraft?.kind == DraftKind.income ? recordDraft : null,
            initialWalletId: walletFor(defaults.incomeWalletId),
            frequentCategoryIds: defaults.incomeCategoryIds,
            onCreateCategory: (name) => bloc.createCategory(CategoryKind.income, name),
            kindSwitcher: kindSwitcher,
            initialRepeat: repeat,
            repeatLocked: repeatLocked,
          scheduleOnly: scheduleOnly,
          occurrence: occurrence,
          ),
          RecordChoice.expense => ExpenseFormSheet(
            wallets: wallets,
            prefill: expensePrefill,
            draft: recordDraft?.kind == DraftKind.expense ? recordDraft : null,
            initialWalletId: walletFor(defaults.expenseWalletId),
            frequentCategoryIds: defaults.expenseCategoryIds,
            onCreateCategory: (name) => bloc.createCategory(CategoryKind.expense, name),
            budgetItems: budgetItems,
            initialBudgetItemId: initialBudgetItemId,
            initialAmountSen: initialAmountSen,
            kindSwitcher: kindSwitcher,
            initialRepeat: repeat,
            repeatLocked: repeatLocked,
          scheduleOnly: scheduleOnly,
          occurrence: occurrence,
          ),
          RecordChoice.transfer => TransferFormSheet(
            wallets: wallets,
            prefill: transferPrefill,
            draft: recordDraft?.kind == DraftKind.transfer ? recordDraft : null,
            initialWalletId: transferFrom,
            budgetItems: budgetItems,
            initialBudgetItemId: initialBudgetItemId,
            initialAmountSen: initialAmountSen,
            initialToWalletId: transferTo,
            kindSwitcher: kindSwitcher,
            initialRepeat: repeat,
            repeatLocked: repeatLocked,
          scheduleOnly: scheduleOnly,
          occurrence: occurrence,
          ),
        };
      },
    ),
  );
  if (result == null || !context.mounted) return false;
  // CATAT → Pemasukan → Freelance (FR-FRL-005). Alur CATAT selesai;
  // pemanggil menyegarkan saldo sesudahnya seperti biasa.
  if (result is OpenFreelance) {
    await context.pushRoute(FreelanceRouteKeys.overview, const EmptyInput());
    return false;
  }
  if (result is RecordEvent) {
    final savedBefore = bloc.state.saveCount;
    bloc.add(
      switch ((makeRecurringFrom, editRule)) {
        (final Transaction source, _) => RecordMadeRecurring(source: source, recorded: result),
        (_, final RecurringRule rule) => RecordRuleEdited(rule: rule, recorded: result),
        _ when occurrence != null => RecordOccurrenceRecorded(
          rule: occurrence.rule,
          occurrenceDate: occurrence.date,
          recorded: withSourceIcon(result, recordDraft?.sourceIconId),
        ),
        _ => withSourceIcon(result, recordDraft?.sourceIconId),
      },
    );
    if (!context.mounted) return false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecordSavingDialog(bloc: bloc),
    );
    return bloc.state.saveCount > savedBefore;
  }
  return false;
}

/// Draf CATAT dari [transaction] (Jadikan Rutin): seluruh isiannya, termasuk
/// tanggal, tanpa isu sehingga kartu draf tidak tampil.
RecordDraft draftFromTransaction(Transaction transaction) => switch (transaction) {
  IncomeTransaction(:final walletId, :final categoryId) => RecordDraft(
    kind: DraftKind.income,
    amountSen: transaction.amount,
    walletId: walletId,
    categoryId: categoryId,
    note: transaction.note,
    date: transaction.date,
  ),
  ExpenseTransaction(:final walletId, :final categoryId) => RecordDraft(
    kind: DraftKind.expense,
    amountSen: transaction.amount,
    walletId: walletId,
    categoryId: categoryId,
    note: transaction.note,
    date: transaction.date,
  ),
  TransferTransaction(:final fromWalletId, :final toWalletId) => RecordDraft(
    kind: DraftKind.transfer,
    amountSen: transaction.amount,
    walletId: fromWalletId,
    toWalletId: toWalletId,
    note: transaction.note,
    date: transaction.date,
  ),
};

/// Draf CATAT dari [rule]. Tanpa [date] (Ubah rutin): kemunculan berikutnya
/// sejak hari ini, atau patokannya bila sudah berakhir. Dengan [date] (Ubah
/// dulu): tanggal kemunculan itu, dengan jam sekarang.
RecordDraft draftFromRule(RecurringRule rule, {DateTime? date}) {
  final now = DateTime.now();
  final day = date ?? nextOccurrence(rule, now) ?? rule.schedule.anchorDate;
  final when = DateTime(day.year, day.month, day.day, now.hour, now.minute);
  return RecordDraft(
    kind: switch (rule.kind) {
      RecurringKind.income => DraftKind.income,
      RecurringKind.expense => DraftKind.expense,
      RecurringKind.transfer => DraftKind.transfer,
    },
    amountSen: rule.amount,
    walletId: rule.walletId,
    toWalletId: rule.toWalletId,
    categoryId: rule.categoryId,
    note: rule.note,
    date: when,
  );
}
