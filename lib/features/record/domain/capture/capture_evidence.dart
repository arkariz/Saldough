import 'package:dependencies/dependencies.dart';

/// Asal bukti Catat Cerdas (ADR-027 §3.1). Menambah sumber baru cukup
/// menambah anggota di sini dan satu penangkapnya; interpreter, resolver,
/// dan formulir tidak berubah.
enum CaptureSource {
  /// Transkrip ucapan.
  voice,

  /// Teks notifikasi bank atau e-wallet.
  notification,

  /// Teks hasil OCR foto struk.
  photo,
}

/// Bukti teks yang ditafsirkan menjadi draf transaksi.
final class CaptureEvidence extends Equatable {
  /// Membuat [CaptureEvidence].
  const CaptureEvidence({required this.source, required this.text, required this.capturedAt, this.origin});

  /// Asal bukti.
  final CaptureSource source;

  /// Teks yang ditafsirkan. Satu-satunya sumber kebenaran untuk nominal:
  /// nominal yang tidak tertulis di sini ditolak.
  final String text;

  /// Waktu bukti ditangkap (untuk notifikasi: waktu notifikasinya). Dipakai
  /// sebagai tanggal transaksi kalau teks tidak menyebut tanggal.
  final DateTime capturedAt;

  /// Keterangan asal, mis. nama paket aplikasi pengirim notifikasi. Tidak
  /// pernah dikirim ke model.
  final String? origin;

  @override
  List<Object?> get props => [source, text, capturedAt, origin];
}
