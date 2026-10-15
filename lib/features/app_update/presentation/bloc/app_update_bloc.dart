import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/repositories/app_update_memory_repository.dart';
import 'package:saldough/features/app_update/domain/repositories/update_sources.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';
import 'package:saldough/features/app_update/domain/usecases/read_update_snapshot.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_state.dart';
import 'package:state_management/state_management.dart';

part 'app_update_event.dart';

/// Jeda minimum antar pengecekan Play tanpa `force` (ADR-039 §3.1).
const storeCheckInterval = Duration(hours: 6);

/// Bloc pengumuman pembaruan (ADR-039). Hidup selama aplikasi (didaftarkan
/// di akar): Beranda dan Akun membaca keadaan yang sama. Kegagalan apa pun
/// = diam, tidak pernah efek galat (B-5).
final class AppUpdateBloc extends Bloc<AppUpdateEvent, AppUpdateState> {
  /// Membuat [AppUpdateBloc]; [now] bisa diganti di uji.
  AppUpdateBloc({
    required this._read,
    required this._store,
    required this._memory,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const AppUpdateState()) {
    on<AppUpdateChecked>(_onChecked);
    on<AppUpdateDownloadRequested>(_onDownloadRequested);
    on<AppUpdateInstallRequested>(_onInstallRequested);
    on<AppUpdateDeferred>(_onDeferred);
    on<AppUpdatePatchAcknowledged>(_onPatchAcknowledged);
    on<_AppUpdateStageChanged>(_onStageChanged);
  }

  final ReadUpdateSnapshot _read;
  final StoreUpdateSource _store;
  final AppUpdateMemoryRepository _memory;
  final DateTime Function() _now;

  StreamSubscription<StoreUpdateStage>? _stages;
  DateTime? _lastStoreCheck;
  bool _memoryLoaded = false;

  AppUpdateState _derive(AppUpdateState base, {UpdateSnapshot? snapshot, AppUpdateMemory? memory}) {
    final next = memory ?? base.memory;
    final snap = snapshot ?? base.snapshot;
    return base.copyWith(
      snapshot: () => snap,
      memory: next,
      announcement: snap == null
          ? UpdateAnnouncement.none
          : pickAnnouncement(snapshot: snap, memory: next, now: _now()),
    );
  }

  Future<void> _onChecked(AppUpdateChecked event, Emitter<AppUpdateState> emit) async {
    var memory = state.memory;
    if (!_memoryLoaded) {
      // Ingatan gagal dibaca = kosong; pengumuman tetap jalan dengan hitungan baru.
      memory = (await _memory.load()).getOrElse((_) => AppUpdateMemory.empty);
      _memoryLoaded = true;
    }
    final last = _lastStoreCheck;
    final checkStore = event.force || last == null || _now().difference(last) >= storeCheckInterval;
    if (checkStore) _lastStoreCheck = _now();
    final result = await _read(checkStore: checkStore);
    switch (result) {
      case Left():
        emit(_derive(state, memory: memory));
      case Right(value: var snapshot):
        // Tanpa pengecekan Play, keadaan Play terakhir dipertahankan.
        final previous = state.snapshot;
        if (!checkStore && previous != null) {
          snapshot = UpdateSnapshot(version: snapshot.version, store: previous.store, patch: snapshot.patch);
        }
        emit(_derive(state, snapshot: snapshot, memory: memory));
        _watchStages();
    }
  }

  void _watchStages() {
    _stages ??= _store.watch().listen((stage) => add(_AppUpdateStageChanged(stage)), onError: (Object _) {});
  }

  void _onStageChanged(_AppUpdateStageChanged event, Emitter<AppUpdateState> emit) {
    final snapshot = state.snapshot;
    if (snapshot == null) return;
    final store = StoreUpdateInfo(stage: event.stage, availableBuild: snapshot.store.availableBuild);
    emit(
      _derive(
        state,
        snapshot: UpdateSnapshot(version: snapshot.version, store: store, patch: snapshot.patch),
      ),
    );
  }

  Future<void> _onDownloadRequested(AppUpdateDownloadRequested event, Emitter<AppUpdateState> emit) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    // Pengguna menolak atau gagal: tetap "tersedia", tanpa pesan galat.
    await _store.startDownload();
    emit(state.copyWith(busy: false));
  }

  Future<void> _onInstallRequested(AppUpdateInstallRequested event, Emitter<AppUpdateState> emit) async {
    if (state.snapshot?.store.stage != StoreUpdateStage.downloaded) return;
    await _store.completeInstall();
  }

  Future<void> _onDeferred(AppUpdateDeferred event, Emitter<AppUpdateState> emit) async {
    final build = state.snapshot?.store.availableBuild;
    if (build == null) return;
    final memory = state.memory.defer(build, _now());
    emit(_derive(state, memory: memory));
    await _memory.save(memory);
  }

  Future<void> _onPatchAcknowledged(AppUpdatePatchAcknowledged event, Emitter<AppUpdateState> emit) async {
    final snapshot = state.snapshot;
    final ready = snapshot?.patch.ready;
    if (snapshot == null || ready == null) return;
    final memory = state.memory.announce(snapshot.version.build, ready);
    emit(_derive(state, memory: memory));
    await _memory.save(memory);
  }

  @override
  Future<void> close() async {
    await _stages?.cancel();
    return super.close();
  }
}
