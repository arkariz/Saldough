import 'package:dependencies/dependencies.dart';

/// Yang diingat aplikasi agar aturan pengumuman berlaku (APP_UPDATE §6,
/// ADR-039 §3.5). Bukan data keuangan; milik perangkat.
final class AppUpdateMemory extends Equatable {
  /// Membuat [AppUpdateMemory].
  const AppUpdateMemory({
    this.lastSeenBuild,
    this.lastSeenPatch = 0,
    this.deferredBuild,
    this.deferredAt,
    this.announcedPatches = const {},
  });

  /// Pemasangan pertama atau ingatan gagal dibaca.
  static const empty = AppUpdateMemory();

  /// Build terakhir yang dilihat; `null` = belum pernah (pemasangan pertama).
  final int? lastSeenBuild;

  /// Pembaruan kecil terakhir yang dilihat pada [lastSeenBuild].
  final int lastSeenPatch;

  /// Build versi baru yang ditunda lewat Nanti.
  final int? deferredBuild;

  /// Waktu Nanti diketuk.
  final DateTime? deferredAt;

  /// Per build: nomor pembaruan kecil tertinggi yang sudah diumumkan.
  final Map<int, int> announcedPatches;

  /// Menunda build [build] pada [at].
  AppUpdateMemory defer(int build, DateTime at) => _copy(deferredBuild: build, deferredAt: at);

  /// Menandai pembaruan kecil [patch] pada [build] sudah diumumkan.
  AppUpdateMemory announce(int build, int patch) {
    final seen = announcedPatches[build];
    if (seen != null && seen >= patch) return this;
    return _copy(announcedPatches: {...announcedPatches, build: patch});
  }

  /// Mencatat versi terakhir yang dilihat. Tidak pernah menurun (rollback).
  AppUpdateMemory see(int build, int patch) {
    final last = lastSeenBuild;
    if (last != null && (build < last || (build == last && patch <= lastSeenPatch))) return this;
    return _copy(lastSeenBuild: build, lastSeenPatch: patch);
  }

  AppUpdateMemory _copy({
    int? lastSeenBuild,
    int? lastSeenPatch,
    int? deferredBuild,
    DateTime? deferredAt,
    Map<int, int>? announcedPatches,
  }) => AppUpdateMemory(
    lastSeenBuild: lastSeenBuild ?? this.lastSeenBuild,
    lastSeenPatch: lastSeenPatch ?? this.lastSeenPatch,
    deferredBuild: deferredBuild ?? this.deferredBuild,
    deferredAt: deferredAt ?? this.deferredAt,
    announcedPatches: announcedPatches ?? this.announcedPatches,
  );

  @override
  List<Object?> get props => [lastSeenBuild, lastSeenPatch, deferredBuild, deferredAt, announcedPatches];
}
