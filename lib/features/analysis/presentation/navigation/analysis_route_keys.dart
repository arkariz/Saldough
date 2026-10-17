import 'package:navigation/navigation.dart';
import 'package:saldough/shared/category/category.dart';

// Satu-satunya berkas fitur `analysis` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Dari mana Analisis dibuka (analitik, FINANCIAL_ANALYSIS §13A).
enum AnalysisSource {
  /// Tab Riwayat › Analisis.
  history,

  /// Kartu Arus di Beranda.
  home,

  /// Lembar kilas balik di Rencana.
  lookback,
}

/// Input Analisis sebagai rute penuh (dari Beranda dan kilas balik).
final class AnalysisInput extends RouteInput {
  /// Membuat [AnalysisInput].
  const AnalysisInput({required this.source, this.periodStart});

  /// Asal pembukaan.
  final AnalysisSource source;

  /// Tanggal di dalam periode yang dibuka; `null` = periode berjalan.
  final DateTime? periodStart;
}

/// Input Rincian kategori (A5): satu kategori, atau Freelance, di satu periode.
final class CategoryDetailInput extends RouteInput {
  /// Membuat [CategoryDetailInput].
  const CategoryDetailInput({
    required this.categoryId,
    required this.kind,
    required this.periodStart,
    this.walletId,
  });

  /// Kategori yang dirinci; `null` = kelompok Freelance (B-9).
  final String? categoryId;

  /// Pengeluaran atau pemasukan.
  final CategoryKind kind;

  /// Tanggal di dalam periode yang dirinci.
  final DateTime periodStart;

  /// Dompet yang disaring di Analisis, atau `null` = semua dompet.
  final String? walletId;
}

/// Kunci rute fitur `analysis`.
abstract final class AnalysisRouteKeys {
  /// Analisis satu periode sebagai halaman penuh; keluar = kembali.
  static const open = RouteKey<AnalysisInput>('analysis.open');

  /// Rincian satu kategori di satu periode, dari Analisis (Lihat rincian,
  /// sorotan).
  static const category = RouteKey<CategoryDetailInput>('analysis.category');
}
