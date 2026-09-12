// Satu method disengaja — port kecil untuk satu kebutuhan baca lintas fitur
// (lihat catatan revisi ADR-0009), bukan kelas yang sebaiknya jadi fungsi
// top-level. Pola yang sama seperti `CardCatalog`.
// ignore_for_file: one_member_abstracts

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Port kecil untuk membaca `id` siklus yang sudah dibuat — TANPA `grocery`
/// mengimpor domain/data milik fitur `cycle` secara langsung (ADR-0009:
/// fitur privat, tidak saling diimpor). Diimplementasikan oleh
/// `features/cycle/data/` dan dikawat di `RootModule`, pola yang sama
/// seperti `CycleIncomeWriter` (fitur `worklog`) dan `CycleInvestmentGateway`
/// (fitur `investment`).
///
/// Dipakai layar Rencana Belanja untuk memilih BULAN mana yang sedang
/// dilihat/disunting (tautan 1:1 `GroceryPlan`↔`MonthlyCycle`, laporan
/// pemilik) — sama seperti `CycleInvestmentGateway.listCycleIds` dipakai
/// layar Investasi, bukan mengetik `YYYY-MM` dengan tangan (UX-09).
abstract interface class GroceryCycleGateway {
  /// Seluruh `id` siklus yang sudah dibuat, terurut menaik.
  Future<Either<Failure, List<String>>> listCycleIds();
}
