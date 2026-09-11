import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Port kecil untuk menyuntikkan gaji bersih ke baris pemasukan pada sebuah
/// siklus (T-3.9/FR-TIME-003) — TANPA `worklog` mengimpor domain/data milik
/// fitur `cycle` secara langsung (ADR-0009: fitur privat, tidak saling
/// diimpor). Diimplementasikan oleh `features/cycle/data/` dan dikawat di
/// `RootModule`, yang memang melihat kedua fitur — pola yang sama seperti
/// `RollUpResolver` di fitur `cycle` sendiri (Fase 2), hanya arah
/// ketergantungannya terbalik. Lihat catatan revisi ADR-0009.
abstract interface class CycleIncomeWriter {
  /// Menulis [amount] (dalam sen) sebagai baris pemasukan ber-`sourceId`
  /// [sourceId] pada siklus ber-`id` [cycleId]: memperbarui baris yang sudah
  /// ada kalau ketemu, atau membuat baris baru berlabel [sourceLabel] kalau
  /// belum ada. Mengembalikan identitas baris yang ditulis.
  ///
  /// `Left(BusinessRuleFailure)` kalau siklus [cycleId] belum ada, atau
  /// sudah ditutup (ADR-0008 — siklus tertutup tidak menerima penyuntingan
  /// tanpa dibuka kembali secara sadar; penyuntikan otomatis bukan
  /// pengecualian dari aturan itu).
  Future<Either<Failure, String>> inject({
    required String cycleId,
    required String sourceId,
    required String sourceLabel,
    required int amount,
  });

  /// Seluruh `id` siklus yang sudah dibuat, terurut menaik (UX-09: dipakai
  /// untuk pemilih siklus tujuan, bukan mengetik `YYYY-MM` dengan tangan).
  Future<Either<Failure, List<String>>> listCycleIds();
}
