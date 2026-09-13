// Satu method disengaja — port kecil untuk satu kebutuhan baca lintas fitur
// (lihat catatan revisi ADR-0009), bukan kelas yang sebaiknya jadi fungsi
// top-level. Pola yang sama seperti `CardCatalog`/`GroceryCycleGateway`.
// ignore_for_file: one_member_abstracts

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Port milik fitur `income` — ringkasan buku jam TERBUKA milik sumber
/// freelance, TANPA `income` mengimpor domain/data milik fitur `worklog`
/// secara langsung (ADR-0009). Diimplementasikan oleh `features/worklog/
/// data/` dan dikawat di `RootModule`.
///
/// Dipakai `IncomeSourceListPage` supaya tiap sumber freelance menampilkan
/// ringkasan buku berjalannya sendiri, dengan tombol langsung ke layar
/// catatan jam kerja (laporan pemilik: sebelumnya satu-satunya jalan ke
/// sana adalah ikon tanpa label di app bar, terlepas dari daftar sumber).
abstract interface class IncomeWorklogGateway {
  /// Jumlah jam pada buku TERBUKA tiap sumber dalam [sourceIds], hanya untuk
  /// sumber yang benar-benar punya buku terbuka (sumber tanpa buku terbuka
  /// tidak muncul sebagai kunci sama sekali, bukan `0`).
  Future<Either<Failure, Map<String, int>>> openBookHoursBySourceId(List<String> sourceIds);
}
