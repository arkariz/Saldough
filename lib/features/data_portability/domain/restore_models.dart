import 'package:saldough/features/data_portability/domain/backup_summary.dart';

/// Dari mana pemulihan dimulai.
enum RestoreKind {
  /// Dari Akun, di atas data yang ada.
  account,

  /// Dari onboarding, belum ada data (tanpa salinan pengaman).
  onboarding,

  /// Mengembalikan data sebelum pemulihan (R-5).
  undo,
}

/// Perbandingan yang ditampilkan sebelum pemulihan (EXPORT_BACKUP §7.1
/// langkah 3-4): isi cadangan melawan data di ponsel ini, dan apa yang akan
/// berubah.
final class RestorePreview {
  /// Membuat [RestorePreview].
  const RestorePreview({
    required this.source,
    required this.backup,
    required this.backupCreatedAt,
    required this.current,
    required this.isOlderThanCurrent,
    required this.newCurrency,
    required this.lostInboxDrafts,
  });

  /// Asal alur.
  final RestoreKind source;

  /// Ringkasan isi cadangan, dihitung dari dokumen.
  final BackupSummary backup;

  /// Kapan cadangan dibuat (untuk cadangan pengaman: saat data itu disalin).
  final DateTime backupCreatedAt;

  /// Ringkasan data di ponsel ini sekarang.
  final BackupSummary current;

  /// Cadangan lebih lama dari data sekarang (R: jumlah transaksi lebih
  /// sedikit, atau transaksi terakhir lebih baru dari tanggal cadangan).
  final bool isOlderThanCurrent;

  /// Kode mata uang baru bila berbeda dari sekarang (R-7), selain itu `null`.
  final String? newCurrency;

  /// Draf dari notifikasi yang belum ditinjau dan akan ikut terganti (R-10).
  final int lostInboxDrafts;

  /// Apakah ada yang perlu ditulis di bagian "Yang akan berubah".
  bool get hasChanges => newCurrency != null || lostInboxDrafts > 0;
}

/// Hasil pemeriksaan berkas: pratinjau beserta isinya yang siap disiapkan.
/// Isinya tetap di memori; tidak ada yang ditulis sampai pengguna menyetujui.
final class RestoreSession {
  /// Membuat [RestoreSession].
  const RestoreSession({required this.preview, required this.docs});

  /// Pratinjau untuk layar.
  final RestorePreview preview;

  /// Dokumen yang akan ditulis, `kunci → string tersimpan`. Kosong untuk
  /// "Kembalikan": isinya diambil dari cadangan pengaman saat disiapkan.
  final Map<String, String> docs;
}

/// Cadangan pengaman yang masih bisa dikembalikan (R-5).
final class SafetyCopyInfo {
  /// Membuat [SafetyCopyInfo].
  const SafetyCopyInfo({required this.createdAt, required this.expiresAt});

  /// Saat data itu disalin.
  final DateTime createdAt;

  /// Saat salinan dibuang otomatis (paling lama 30 hari, KT-E4).
  final DateTime expiresAt;
}

/// Keterangan pemulihan yang baru selesai, untuk pesan sesudah mulai ulang.
final class RestoreReport {
  /// Membuat [RestoreReport].
  const RestoreReport({required this.kind, required this.backupCreatedAt, this.restoredKeys = const []});

  /// Asal pemulihan.
  final RestoreKind kind;

  /// Tanggal cadangan yang dipulihkan, bila diketahui.
  final DateTime? backupCreatedAt;

  /// Kunci yang ditulis dari cadangan.
  final List<String> restoredKeys;

  /// Cadangan memuat Catat dari notifikasi atau pengingat, sehingga izin
  /// sistemnya perlu diberikan lagi di ponsel ini (EXPORT_BACKUP §7.1).
  bool get mayNeedPermissions =>
      restoredKeys.contains('settings_notification_capture') || restoredKeys.contains('settings_recurring_reminders');
}
