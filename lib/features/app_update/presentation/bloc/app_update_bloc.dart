import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/app_version.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/repositories/app_update_memory_repository.dart';
import 'package:saldough/features/app_update/domain/repositories/release_notes_source.dart';
import 'package:saldough/features/app_update/domain/repositories/update_sources.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';
import 'package:saldough/features/app_update/domain/services/whats_new_policy.dart';
import 'package:saldough/features/app_update/domain/usecases/read_update_snapshot.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_state.dart';
import 'package:state_management/state_management.dart';

part 'app_update_event.dart';

/// Jeda minimum antar pengecekan Play tanpa `force` sesudah hasil yang pasti
/// (ADR-039 §3.1). Pengecekan ke Play murah, dan keadaan Play bisa baru
/// berubah beberapa menit sesudah build dipublikasikan, jadi jedanya pendek.
const storeCheckInterval = Duration(hours: 1);

/// Jeda ulang bila pengecekan Play terakhir tidak pasti (gagal, belum siap):
/// dicoba lagi pada pemicu berikutnya (aplikasi kembali ke depan).
const storeRetryInterval = Duration(minutes: 1);

/// Batas tunggu banner versi baru untuk catatan build yang ditawarkan Play
/// (untuk chip versi), bila belum ada di perangkat (ADR-039 §3.3 butir 4).
const chipWait = Duration(seconds: 2);

/// Bloc pengumuman pembaruan (ADR-039). Hidup selama aplikasi (didaftarkan
/// di akar): Beranda dan Akun membaca keadaan yang sama. Kegagalan apa pun
/// = diam, tidak pernah efek galat (B-5).
final class AppUpdateBloc extends Bloc<AppUpdateEvent, AppUpdateState> {
  /// Membuat [AppUpdateBloc]; [now] dan [chipWait] bisa diganti di uji.
  AppUpdateBloc({
    required this._read,
    required this._store,
    required this._memory,
    required this._notes,
    DateTime Function()? now,
    this._waitForChip = chipWait,
  }) : _now = now ?? DateTime.now,
       super(const AppUpdateState()) {
    on<AppUpdateChecked>(_onChecked);
    on<AppUpdateDownloadRequested>(_onDownloadRequested);
    on<AppUpdateInstallRequested>(_onInstallRequested);
    on<AppUpdateDeferred>(_onDeferred);
    on<AppUpdatePatchAcknowledged>(_onPatchAcknowledged);
    on<AppUpdateWhatsNewSeen>(_onWhatsNewSeen);
    on<AppUpdateBannerShown>(_onBannerShown);
    on<AppUpdateWhatsNewOpened>(_onWhatsNewOpened);
    on<_AppUpdateStageChanged>(_onStageChanged);
    on<_AppUpdateNotesChanged>(_onNotesChanged);
  }

  final ReadUpdateSnapshot _read;
  final StoreUpdateSource _store;
  final AppUpdateMemoryRepository _memory;
  final ReleaseNotesSource _notes;
  final DateTime Function() _now;
  final Duration _waitForChip;

  StreamSubscription<StoreUpdateStage>? _stages;
  StreamSubscription<void>? _noteChanges;
  DateTime? _lastStoreCheck;
  bool _lastStoreUnknown = false;
  bool _memoryLoaded = false;
  int? _reportedPatch;
  final _shownBanners = <UpdateAnnouncement>{};

  /// Menyusun state dari [snapshot], [memory], dan [notes]; memajukan versi
  /// terakhir dilihat bila lembar tidak diperlukan (pemasangan pertama, tanpa
  /// catatan). Mengembalikan state baru.
  AppUpdateState _compose(
    AppUpdateState base, {
    UpdateSnapshot? snapshot,
    AppUpdateMemory? memory,
    ReleaseNotesSnapshot? notes,
  }) {
    var mem = memory ?? base.memory;
    final snap = snapshot ?? base.snapshot;
    final noteSet = notes ?? base.notes;
    var whatsNew = const <ReleaseNote>[];
    var installed = const <ReleaseNote>[];
    String? availableVersion;
    if (snap != null) {
      final decision = decideWhatsNew(
        running: snap.version,
        memory: mem,
        entries: noteSet.entries,
        serverRead: noteSet.serverRead,
      );
      switch (decision) {
        case WhatsNewShow(notes: final shown):
          whatsNew = shown;
        case WhatsNewNothing():
          final advanced = mem.see(snap.version.build, snap.version.patch);
          if (advanced != mem) {
            _reportUpdated(mem, advanced, snap.version);
            mem = advanced;
            unawaited(_memory.save(advanced));
          }
        case WhatsNewWait():
          break;
      }
      installed = installedNotes(running: snap.version, entries: noteSet.entries);
      final build = snap.store.availableBuild;
      if (build != null && snap.store.stage != StoreUpdateStage.none && snap.store.stage != StoreUpdateStage.unknown) {
        availableVersion = noteSet.entries[(build: build, patch: 0)]?.version;
      }
    }
    return base.copyWith(
      snapshot: () => snap,
      memory: mem,
      notes: noteSet,
      whatsNew: whatsNew,
      installedNotes: installed,
      availableVersion: () => availableVersion,
      announcement: snap == null ? UpdateAnnouncement.none : pickAnnouncement(snapshot: snap, memory: mem, now: _now()),
    );
  }

  /// `app_updated` sekali saat versi terakhir dilihat maju karena versi
  /// berubah; pemasangan pertama (belum ada versi sebelumnya) tidak dihitung.
  void _reportUpdated(AppUpdateMemory before, AppUpdateMemory after, AppVersion running) {
    final fromBuild = before.lastSeenBuild;
    if (fromBuild == null) return;
    AppAnalytics.log(
      UpdateEvents.appUpdated(
        kind: after.lastSeenBuild != fromBuild ? 'store' : 'patch',
        fromBuild: fromBuild,
        toBuild: running.build,
        toPatch: running.patch,
      ),
    );
  }

  /// Nomor pembaruan kecil yang berjalan ke Analytics dan Crashlytics, sekali
  /// tiap berubah (0 = tanpa tambalan).
  void _reportPatch(int patch) {
    if (_reportedPatch == patch) return;
    _reportedPatch = patch;
    AppAnalytics.setUserProperty(UpdateEvents.patchNumberKey, '$patch');
    AppAnalytics.setDiagnostic(UpdateEvents.patchNumberKey, patch);
  }

  Future<ReleaseNotesSnapshot?> _loadNotes(AppVersion running, {required bool refresh}) async =>
      (await _notes.load(running: running, refresh: refresh)).fold((_) => null, (snapshot) => snapshot);

  Future<void> _onChecked(AppUpdateChecked event, Emitter<AppUpdateState> emit) async {
    var memory = state.memory;
    if (!_memoryLoaded) {
      // Ingatan gagal dibaca = kosong; pengumuman tetap jalan dengan hitungan baru.
      memory = (await _memory.load()).getOrElse((_) => AppUpdateMemory.empty);
      _memoryLoaded = true;
    }
    final last = _lastStoreCheck;
    // Hasil yang tidak pasti (gagal dicek) tidak boleh menahan pengecekan
    // berikutnya selama berjam-jam.
    final interval = _lastStoreUnknown ? storeRetryInterval : storeCheckInterval;
    final checkStore = event.force || last == null || _now().difference(last) >= interval;
    if (checkStore) _lastStoreCheck = _now();
    final result = await _read(checkStore: checkStore);
    switch (result) {
      case Left():
        emit(_compose(state, memory: memory));
      case Right(value: var snapshot):
        if (checkStore) _lastStoreUnknown = snapshot.store.stage == StoreUpdateStage.unknown;
        // Tanpa pengecekan Play, keadaan Play terakhir dipertahankan.
        final previous = state.snapshot;
        if (!checkStore && previous != null) {
          snapshot = UpdateSnapshot(version: snapshot.version, store: previous.store, patch: snapshot.patch);
        }
        var notes = await _loadNotes(snapshot.version, refresh: false) ?? state.notes;
        final offered = snapshot.store.availableBuild;
        final chipMissing =
            offered != null &&
            snapshot.store.stage == StoreUpdateStage.available &&
            !notes.entries.containsKey((build: offered, patch: 0));
        if (chipMissing) {
          // Menunggu sebentar supaya chip versi ikut tampil; lewat batas,
          // banner tampil tanpa chip dan chip menyusul (B-14).
          final fresh = await _loadNotes(
            snapshot.version,
            refresh: true,
          ).timeout(_waitForChip, onTimeout: () => null).catchError((Object _) => null);
          notes = fresh ?? notes;
        } else {
          unawaited(_refreshNotes(snapshot.version));
        }
        _reportPatch(snapshot.version.patch);
        emit(_compose(state, snapshot: snapshot, memory: memory, notes: notes));
        _watch();
    }
  }

  /// Mengambil catatan dari server di latar, lalu memberi tahu bloc.
  Future<void> _refreshNotes(AppVersion running) async {
    final fresh = await _loadNotes(running, refresh: true);
    if (fresh != null && fresh != state.notes && !isClosed) add(const _AppUpdateNotesChanged());
  }

  void _watch() {
    _stages ??= _store.watch().listen((stage) => add(_AppUpdateStageChanged(stage)), onError: (Object _) {});
    if (_noteChanges == null) {
      try {
        _noteChanges = _notes.changes.listen((_) => add(const _AppUpdateNotesChanged()), onError: (Object _) {});
      } on Object {
        // Firebase belum siap: tanpa sinyal langsung, pengambilan berkala tetap jalan.
      }
    }
  }

  Future<void> _onNotesChanged(_AppUpdateNotesChanged event, Emitter<AppUpdateState> emit) async {
    final running = state.snapshot?.version;
    if (running == null) return;
    final notes = await _loadNotes(running, refresh: false);
    if (notes == null) return;
    emit(_compose(state, notes: notes));
  }

  void _onStageChanged(_AppUpdateStageChanged event, Emitter<AppUpdateState> emit) {
    final snapshot = state.snapshot;
    if (snapshot == null) return;
    final store = StoreUpdateInfo(stage: event.stage, availableBuild: snapshot.store.availableBuild);
    emit(
      _compose(
        state,
        snapshot: UpdateSnapshot(version: snapshot.version, store: store, patch: snapshot.patch),
      ),
    );
  }

  Future<void> _onDownloadRequested(AppUpdateDownloadRequested event, Emitter<AppUpdateState> emit) async {
    if (state.busy) return;
    AppAnalytics.log(UpdateEvents.bannerAction(kind: 'store', action: 'update', source: event.source.name));
    emit(state.copyWith(busy: true));
    // Pengguna menolak atau gagal: tetap "tersedia", tanpa pesan galat.
    await _store.startDownload();
    emit(state.copyWith(busy: false));
  }

  Future<void> _onInstallRequested(AppUpdateInstallRequested event, Emitter<AppUpdateState> emit) async {
    if (state.snapshot?.store.stage != StoreUpdateStage.downloaded) return;
    AppAnalytics.log(UpdateEvents.bannerAction(kind: 'store', action: 'install', source: event.source.name));
    await _store.completeInstall();
  }

  Future<void> _onDeferred(AppUpdateDeferred event, Emitter<AppUpdateState> emit) async {
    final build = state.snapshot?.store.availableBuild;
    if (build == null) return;
    AppAnalytics.log(UpdateEvents.bannerAction(kind: 'store', action: 'dismiss', source: 'home'));
    final memory = state.memory.defer(build, _now());
    emit(_compose(state, memory: memory));
    await _memory.save(memory);
  }

  Future<void> _onPatchAcknowledged(AppUpdatePatchAcknowledged event, Emitter<AppUpdateState> emit) async {
    final snapshot = state.snapshot;
    final ready = snapshot?.patch.ready;
    if (snapshot == null || ready == null) return;
    AppAnalytics.log(UpdateEvents.bannerAction(kind: 'patch', action: 'dismiss', source: 'home'));
    final memory = state.memory.announce(snapshot.version.build, ready);
    emit(_compose(state, memory: memory));
    await _memory.save(memory);
  }

  Future<void> _onWhatsNewSeen(AppUpdateWhatsNewSeen event, Emitter<AppUpdateState> emit) async {
    final version = state.snapshot?.version;
    if (version == null || state.whatsNew.isEmpty) return;
    final memory = state.memory.see(version.build, version.patch);
    _reportUpdated(state.memory, memory, version);
    emit(_compose(state, memory: memory));
    await _memory.save(memory);
  }

  void _onBannerShown(AppUpdateBannerShown event, Emitter<AppUpdateState> emit) {
    final (kind, stage) = switch (event.announcement) {
      UpdateAnnouncement.none => (null, null),
      UpdateAnnouncement.storeAvailable => ('store', 'available'),
      UpdateAnnouncement.storeDownloading => ('store', 'downloading'),
      UpdateAnnouncement.storeDownloaded => ('store', 'downloaded'),
      UpdateAnnouncement.patchReady => ('patch', 'ready'),
    };
    if (kind == null || stage == null || !_shownBanners.add(event.announcement)) return;
    AppAnalytics.log(UpdateEvents.bannerShown(kind: kind, stage: stage, hasVersion: state.availableVersion != null));
  }

  void _onWhatsNewOpened(AppUpdateWhatsNewOpened event, Emitter<AppUpdateState> emit) {
    final shown = event.source == UpdateActionSource.home ? state.whatsNew : state.installedNotes;
    if (shown.isEmpty) return;
    AppAnalytics.log(
      UpdateEvents.whatsNewViewed(
        build: shown.first.build,
        patch: shown.first.patch,
        source: event.source == UpdateActionSource.home ? 'auto' : 'account',
      ),
    );
  }

  @override
  Future<void> close() async {
    await _stages?.cancel();
    await _noteChanges?.cancel();
    return super.close();
  }
}
