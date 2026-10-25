import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';

/// Pemakaian lokal yang menjadi bahan rekap nilai dan layar turun (ADR-041
/// §3.12): hanya angka, dibaca dari data perangkat, tidak pernah dikirim.
abstract interface class PlusUsage {
  /// Jumlah aplikasi sumber Catat dari notifikasi yang dipilih.
  Future<int> notificationSources();

  /// Jumlah rutin yang Catat otomatisnya menyala.
  Future<int> autoRecordRules();

  /// Jumlah catatan yang masuk otomatis dari notifikasi sejak [since].
  Future<int> autoRecordedSince(DateTime since);
}

/// Kartu Plus di Beranda (design `PlusKartu`): satu kalimat, satu tombol,
/// bisa ditutup. Contoh Penjaga menunggu fiturnya (B-44).
sealed class PlusCard extends Equatable {
  const PlusCard();

  /// Kunci penanda "ditutup" untuk kartu ini.
  String get dismissKey;
}

/// Jatah tafsir cerdas bulan ini habis (Gratis).
final class PlusContextCard extends PlusCard {
  /// Membuat [PlusContextCard]; [periodKey] membedakan periode keuangannya.
  const PlusContextCard({required this.limit, required this.periodKey});

  /// Jatah tafsir per periode di Gratis.
  final int limit;

  /// Awal periode keuangan berjalan, sebagai teks tanggal.
  final String periodKey;

  @override
  String get dismissKey => 'context:$periodKey';

  @override
  List<Object?> get props => [limit, periodKey];
}

/// Rekap nilai H-3 sebelum uji coba berakhir.
final class PlusRecapCard extends PlusCard {
  /// Membuat [PlusRecapCard].
  const PlusRecapCard({required this.start, required this.endsOn, required this.recorded});

  /// Hari uji coba dimulai.
  final DateTime start;

  /// Hari terakhir uji coba.
  final DateTime endsOn;

  /// Catatan yang masuk otomatis dari notifikasi sejak [start].
  final int recorded;

  @override
  String get dismissKey => 'recap';

  @override
  List<Object?> get props => [start, endsOn, recorded];
}

/// Isi layar turun sesudah uji coba berakhir tanpa membeli (D-8).
final class PlusDowngrade extends Equatable {
  /// Membuat [PlusDowngrade].
  const PlusDowngrade({required this.sources, required this.autoRules, required this.freePeriods, this.offer});

  /// Aplikasi notifikasi yang dipilih (Gratis hanya yang pertama).
  final int sources;

  /// Rutin ber-Catat otomatis yang kembali ke satu ketuk.
  final int autoRules;

  /// Periode Analisis yang tetap terbuka di Gratis.
  final int freePeriods;

  /// Penawaran sesudah uji coba yang masih berlaku, atau `null`.
  final OfferedPlans? offer;

  @override
  List<Object?> get props => [sources, autoRules, freePeriods, offer];
}

/// Momen terjadwal uji coba (FREEMIUM_PAYWALL §8.2) yang belum ditampilkan.
abstract interface class PlusMoments {
  /// Kartu Beranda yang sedang layak tampil, atau `null`.
  Future<PlusCard?> card();

  /// Menutup [card] supaya tidak muncul lagi.
  Future<void> dismiss(PlusCard card);

  /// Layar turun yang menunggu, atau `null`. Uji coba yang berakhir dengan
  /// pembelian hanya dicatat (`trial_ended`), tanpa layar.
  Future<PlusDowngrade?> downgrade();

  /// Menandai layar turun sudah tampil.
  Future<void> markDowngradeShown();
}
