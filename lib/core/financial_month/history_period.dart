import 'package:flutter/foundation.dart';
import 'package:saldough/core/financial_month/financial_period.dart';

/// Periode yang dilihat di tab Riwayat, dibagi oleh segmen Daftar dan segmen
/// Analisis (FINANCIAL_ANALYSIS F6, T-19.10): memilih Juli di salah satunya
/// membuat yang lain menampilkan Juli juga. Hanya dua segmen itu yang
/// memakainya; Analisis dari Beranda atau Rincian kategori punya periodenya
/// sendiri.
///
/// Nilainya tanggal awal periode yang dipilih, atau `null` = periode
/// berjalan (ikut hari yang berganti dan awal bulan yang berubah).
abstract final class HistoryPeriod {
  HistoryPeriod._();

  /// Pemegang nilai; didengar kedua segmen.
  static final ValueNotifier<DateTime?> notifier = ValueNotifier(null);

  /// Tanggal awal periode yang dipilih, atau `null` = periode berjalan.
  static DateTime? get anchor => notifier.value;

  /// Memilih [period]; periode berjalan (atau yang lebih baru dari [current])
  /// disimpan sebagai `null`.
  static void select(FinancialPeriod period, FinancialPeriod current) {
    notifier.value = period.start.isBefore(current.start) ? period.start : null;
  }

  /// Kembali mengikuti periode berjalan.
  static void reset() => notifier.value = null;
}
