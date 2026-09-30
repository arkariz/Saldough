import 'package:navigation/navigation.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

// Satu-satunya berkas fitur `record` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Tiga jenis yang ditawarkan CATAT (FR-REC-001), dipilih lewat
/// `RecordKindSwitcher` di atas formulir (UX-1).
enum RecordChoice {
  /// Catat pemasukan.
  income,

  /// Catat pengeluaran.
  expense,

  /// Catat transfer antar dompet.
  transfer,
}

/// Input alur CATAT (FR-REC-001/002). Semua isian opsional; tanpa isian,
/// formulir pengeluaran dibuka dengan dompet terakhir yang dipakai.
final class RecordSheetInput extends RouteInput {
  /// Membuat [RecordSheetInput].
  const RecordSheetInput({
    this.initialWalletId,
    this.initialChoice,
    this.initialBudgetItemId,
    this.initialAmountSen,
    this.initialToWalletId,
    this.prefillFrom,
    this.draft,
  });

  /// Dompet awal (pintasan rincian dompet, FR-REC-002).
  final String? initialWalletId;

  /// Jenis yang terpilih saat lembar dibuka; bawaannya pengeluaran.
  final RecordChoice? initialChoice;

  /// Pos anggaran awal (pintasan rincian anggaran, T-4.10).
  final String? initialBudgetItemId;

  /// Nominal awal pengeluaran/transfer (sisa pos anggaran).
  final int? initialAmountSen;

  /// Dompet tujuan transfer awal (pos transfer, ADR-018).
  final String? initialToWalletId;

  /// "Catat lagi" (UX-4): isian dari transaksi ini, tetap transaksi BARU.
  final Transaction? prefillFrom;

  /// Draf Catat Cerdas (ADR-027 §3.4).
  final RecordDraft? draft;
}

/// Input sunting transaksi (FR-TXN-005). Rutenya selesai dengan transaksi
/// hasil sunting, atau `null` kalau dibatalkan; tidak ada yang tersimpan di
/// alur ini -- pemanggil yang menyimpannya.
final class RecordEditInput extends RouteInput {
  /// Membuat [RecordEditInput].
  const RecordEditInput({required this.transaction, required this.wallets, this.budgetItems = const []});

  /// Transaksi yang disunting.
  final Transaction transaction;

  /// Dompet yang ditawarkan formulir.
  final List<Wallet> wallets;

  /// Pos anggaran yang ditawarkan formulir.
  final List<BudgetItemOption> budgetItems;
}

/// Kunci rute fitur `record`. Ketiganya alur transparan yang membuka
/// lembarnya sendiri (ADR-030 §3.3), jadi tampilannya sama dengan lembar
/// yang dibuka langsung.
abstract final class RecordRouteKeys {
  /// Alur CATAT: lembar formulir, lalu dialog menyimpan.
  static const sheet = RouteKey<RecordSheetInput>('record.sheet');

  /// Sunting transaksi; hasil rutenya `Transaction?`.
  static const edit = RouteKey<RecordEditInput>('record.edit');

  /// Catat pakai suara (ADR-027), berlanjut ke CATAT dengan draf.
  static const voice = RouteKey<EmptyInput>('record.voice');
}
