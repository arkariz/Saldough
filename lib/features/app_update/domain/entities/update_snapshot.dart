import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/app_update/domain/entities/app_version.dart';

/// Keadaan versi baru dari Play Store (ADR-039 §3.1). [unknown] = tidak bisa
/// dicek (luring, bukan dari Play, build debug) dan selalu berarti diam.
enum StoreUpdateStage {
  /// Tidak diketahui.
  unknown,

  /// Sudah dicek, tidak ada versi baru.
  none,

  /// Versi baru tersedia.
  available,

  /// Versi baru sedang diunduh.
  downloading,

  /// Versi baru sudah diunduh, tinggal dipasang.
  downloaded,
}

/// Hasil pengecekan Play: keadaan dan nomor build yang tersedia.
final class StoreUpdateInfo extends Equatable {
  /// Membuat [StoreUpdateInfo].
  const StoreUpdateInfo({required this.stage, this.availableBuild});

  /// Tidak diketahui.
  static const unknown = StoreUpdateInfo(stage: StoreUpdateStage.unknown);

  /// Keadaan.
  final StoreUpdateStage stage;

  /// Nomor build versi baru; `null` bila tidak ada atau tidak diketahui.
  final int? availableBuild;

  @override
  List<Object?> get props => [stage, availableBuild];
}

/// Keadaan Shorebird yang dibaca lokal: tambalan berjalan dan tambalan yang
/// akan berjalan pada pembukaan berikutnya (sudah diunduh mesin).
final class PatchState extends Equatable {
  /// Membuat [PatchState].
  const PatchState({this.current = 0, this.next});

  /// Tanpa tambalan atau tidak diketahui (build debug).
  static const none = PatchState();

  /// Nomor tambalan berjalan; 0 bila tanpa tambalan.
  final int current;

  /// Nomor tambalan pada pembukaan berikutnya, atau `null`.
  final int? next;

  /// Nomor tambalan yang siap dipakai, atau `null`. Nomor yang tidak lebih
  /// besar dari yang berjalan (rollback atau sama) tidak pernah "siap".
  int? get ready => next != null && next! > current ? next : null;

  @override
  List<Object?> get props => [current, next];
}

/// Gabungan sumber keadaan pembaruan pada satu saat.
final class UpdateSnapshot extends Equatable {
  /// Membuat [UpdateSnapshot].
  const UpdateSnapshot({required this.version, this.store = StoreUpdateInfo.unknown, this.patch = PatchState.none});

  /// Versi yang berjalan.
  final AppVersion version;

  /// Keadaan Play.
  final StoreUpdateInfo store;

  /// Keadaan Shorebird.
  final PatchState patch;

  @override
  List<Object?> get props => [version, store, patch];
}
