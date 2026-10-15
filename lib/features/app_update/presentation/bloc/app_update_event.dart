part of 'app_update_bloc.dart';

/// Event [AppUpdateBloc].
sealed class AppUpdateEvent {
  /// Membuat [AppUpdateEvent].
  const AppUpdateEvent();
}

/// Cek keadaan pembaruan: sesudah Beranda tampil, aplikasi kembali ke depan
/// (`force` false: Play hanya dicek ulang bila sudah lewat 6 jam), atau Akun
/// dibuka (`force` true).
final class AppUpdateChecked extends AppUpdateEvent {
  /// Membuat [AppUpdateChecked].
  const AppUpdateChecked({this.force = false});

  /// Lewati batas frekuensi pengecekan Play.
  final bool force;
}

/// Perbarui diketuk: mulai unduhan (dialog Play bila perlu).
final class AppUpdateDownloadRequested extends AppUpdateEvent {
  /// Membuat [AppUpdateDownloadRequested].
  const AppUpdateDownloadRequested();
}

/// Pasang sekarang diketuk (B-7: satu-satunya jalan ke pemasangan).
final class AppUpdateInstallRequested extends AppUpdateEvent {
  /// Membuat [AppUpdateInstallRequested].
  const AppUpdateInstallRequested();
}

/// Nanti diketuk: tunda build yang tersedia 7 hari (B-6).
final class AppUpdateDeferred extends AppUpdateEvent {
  /// Membuat [AppUpdateDeferred].
  const AppUpdateDeferred();
}

/// Oke diketuk pada banner pembaruan kecil (B-8).
final class AppUpdatePatchAcknowledged extends AppUpdateEvent {
  /// Membuat [AppUpdatePatchAcknowledged].
  const AppUpdatePatchAcknowledged();
}

/// Lembar Apa yang baru ditutup (Oke, scrim, atau geser): sudah dilihat.
final class AppUpdateWhatsNewSeen extends AppUpdateEvent {
  /// Membuat [AppUpdateWhatsNewSeen].
  const AppUpdateWhatsNewSeen();
}

/// Nilai catatan baru diaktifkan saat aplikasi terbuka.
final class _AppUpdateNotesChanged extends AppUpdateEvent {
  const _AppUpdateNotesChanged();
}

/// Keadaan unduhan berubah dari aliran Play.
final class _AppUpdateStageChanged extends AppUpdateEvent {
  const _AppUpdateStageChanged(this.stage);

  final StoreUpdateStage stage;
}
