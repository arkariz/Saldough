import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/financial_month/financial_period.dart';

/// Keadaan layar hadiah uji coba (FREEMIUM_PAYWALL §8.1, D-1).
final class TrialGiftInfo extends Equatable {
  /// Membuat [TrialGiftInfo].
  const TrialGiftInfo({required this.start, required this.endsOn, required this.needsPayday, required this.minDays});

  /// Hari uji coba dimulai.
  final DateTime start;

  /// Hari terakhir uji coba menurut jadwal periode sekarang.
  final DateTime endsOn;

  /// Pengguna belum pernah memilih tanggal gajian, jadi layar menanyakannya.
  final bool needsPayday;

  /// Sisa periode minimal agar uji coba berakhir di periode berjalan.
  final int minDays;

  @override
  List<Object?> get props => [start, endsOn, needsPayday, minDays];
}

/// Pintu layar hadiah ke uji coba (ADR-041 §3.4): tanpa SDK dan penyimpanan.
abstract interface class TrialGift {
  /// Hadiah yang menunggu ditampilkan, atau `null` (tanpa uji coba, atau
  /// sudah pernah ditampilkan).
  Future<TrialGiftInfo?> pending();

  /// Menyimpan tanggal gajian [start] sebagai awal periode dan menghitung ulang
  /// akhir uji coba. Mengembalikan hari akhir yang berlaku, atau `null` bila gagal.
  Future<DateTime?> setPayday(FinancialMonthStart start);

  /// Menandai hadiah sudah ditampilkan; tanggal akhir tidak berubah lagi.
  Future<void> markSeen();
}
