import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/capture/capture.dart';

/// Alasan tangkapan masuk kotak masuk alih-alih dicatat otomatis (QA PR #43
/// F16), ditampilkan sebagai badge di kartunya. Kemungkinan kembar sudah
/// punya badge sendiri (`possibleDuplicate`).
enum CaptureReviewReason {
  /// Catat otomatis dimatikan pengguna.
  autoRecordOff,

  /// Dari pola bawaan yang belum terverifikasi: selalu ditinjau.
  newPattern,

  /// Nominal tidak ditemukan, ganda, atau bisa dibaca dua cara.
  amountUnclear,

  /// Menyebut mata uang lain.
  otherCurrency,

  /// Jenis belum pasti: pengeluaran atau pindah dompet.
  kindUnclear,

  /// Dompet tidak dikenali.
  walletUnknown,

  /// Kategori belum jelas.
  categoryUnclear,

  /// Tanggal tidak bisa dipakai.
  dateUnclear,
}

/// Tangkapan yang menunggu ditinjau di kotak masuk (ADR-032 §3.6). Teksnya
/// disimpan hanya selama menunggu, paling lama [CaptureRetention.days] hari.
final class CaptureInboxEntry extends Equatable {
  /// Membuat [CaptureInboxEntry].
  const CaptureInboxEntry({
    required this.id,
    required this.packageName,
    required this.appLabel,
    required this.text,
    required this.capturedAt,
    required this.draft,
    this.possibleDuplicate = false,
    this.iconId,
    this.reviewReason,
  });

  /// Identitas tangkapan.
  final String id;

  /// Paket aplikasi pengirim.
  final String packageName;

  /// Nama aplikasi pengirim.
  final String appLabel;

  /// Teks notifikasi.
  final String text;

  /// Waktu notifikasi.
  final DateTime capturedAt;

  /// Draf hasil tafsir.
  final RecordDraft draft;

  /// Mungkin sama dengan transaksi atau tangkapan lain.
  final bool possibleDuplicate;

  /// Id ikon notifikasi di penyimpanan ikon sumber (ADR-032 §3.10).
  final String? iconId;

  /// Kenapa tidak dicatat otomatis; `null` untuk item lama atau kembar.
  final CaptureReviewReason? reviewReason;

  @override
  List<Object?> get props => [
    id,
    packageName,
    appLabel,
    text,
    capturedAt,
    draft,
    possibleDuplicate,
    iconId,
    reviewReason,
  ];
}

/// Transaksi yang tercatat otomatis dari notifikasi (ADR-032 §3.6).
final class AutoRecordedEntry extends Equatable {
  /// Membuat [AutoRecordedEntry].
  const AutoRecordedEntry({
    required this.captureId,
    required this.transactionId,
    required this.transactionDate,
    required this.kind,
    required this.amountSen,
    required this.appLabel,
    required this.recordedAt,
    this.note = '',
    this.categoryId,
    this.iconId,
    this.capturedAt,
  });

  /// Identitas tangkapan asalnya.
  final String captureId;

  /// Identitas transaksi yang tercatat.
  final String transactionId;

  /// Tanggal transaksi (kunci dokumen bulan buku besar).
  final DateTime transactionDate;

  /// Jenis transaksi.
  final DraftKind kind;

  /// Nominal dalam sen.
  final int amountSen;

  /// Nama aplikasi pengirim.
  final String appLabel;

  /// Waktu dicatat.
  final DateTime recordedAt;

  /// Catatan transaksi.
  final String note;

  /// Kategori transaksi saat dicatat (ikon utama kartunya).
  final String? categoryId;

  /// Id ikon notifikasi asalnya (ADR-032 §3.10).
  final String? iconId;

  /// Waktu notifikasi asalnya; `null` untuk log yang disimpan sebelum
  /// ADR-032 §10.
  final DateTime? capturedAt;

  @override
  List<Object?> get props => [
    captureId,
    transactionId,
    transactionDate,
    kind,
    amountSen,
    appLabel,
    recordedAt,
    note,
    categoryId,
    iconId,
    capturedAt,
  ];
}

/// Retensi kotak masuk dan log (ADR-032 §3.6).
abstract final class CaptureRetention {
  CaptureRetention._();

  /// Lama penyimpanan, dalam hari.
  static const days = 7;

  /// `true` bila [at] sudah lewat retensi pada [now].
  static bool expired(DateTime at, DateTime now) => now.difference(at) > const Duration(days: days);
}
