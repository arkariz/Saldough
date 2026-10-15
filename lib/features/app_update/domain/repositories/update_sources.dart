// Port kecil milik `app_update` (ADR-039 §3.5); satu metode per sumber.
// ignore_for_file: one_member_abstracts

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';

/// Versi dan build yang terpasang (tanpa nomor tambalan).
typedef InstalledVersion = ({String name, int build});

/// Pembaruan versi baru dari Play Store (ADR-039 §3.1). Kegagalan apa pun
/// dikembalikan sebagai `Left`; pemanggil memperlakukannya sebagai diam.
abstract interface class StoreUpdateSource {
  /// Mengecek keadaan Play; tidak memblokir pembukaan aplikasi.
  Future<Either<Failure, StoreUpdateInfo>> check();

  /// Memulai unduhan fleksibel (dialog Play bila perlu). `Right(false)` bila
  /// pengguna menolak.
  Future<Either<Failure, bool>> startDownload();

  /// Memasang yang sudah diunduh; aplikasi dimulai ulang. Hanya dari ketukan.
  Future<Either<Failure, Unit>> completeInstall();

  /// Perubahan keadaan unduhan selama aplikasi terbuka.
  Stream<StoreUpdateStage> watch();
}

/// Keadaan Shorebird, dibaca lokal tanpa jaringan (ADR-039 §3.2).
abstract interface class PatchSource {
  /// Membaca tambalan berjalan dan berikutnya.
  Future<Either<Failure, PatchState>> read();
}

/// Versi terpasang.
abstract interface class InstalledVersionSource {
  /// Membaca nama dan build.
  Future<Either<Failure, InstalledVersion>> read();
}
