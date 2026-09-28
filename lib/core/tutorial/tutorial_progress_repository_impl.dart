import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/core/tutorial/spotlight_key.dart';
import 'package:saldough/core/tutorial/tutorial_progress.dart';
import 'package:saldough/core/tutorial/tutorial_progress_repository.dart';

const _progressKey = StorageKey(namespace: 'tutorial', name: 'progress');

/// Implementasi [TutorialProgressRepository] di atas [KeyValueStorage]:
/// satu dokumen `{schemaVersion, onboardingDone, seenSteps}`.
///
/// Versi 1 (`completedTours`, hanya pernah ada di build pengembangan)
/// dimigrasi saat dibaca: tur yang selesai berarti semua langkahnya sudah
/// dilihat. Id langkah atau tur yang tidak dikenal diabaikan, bukan dianggap
/// rusak.
final class TutorialProgressRepositoryImpl with RepositoryGuard implements TutorialProgressRepository {
  /// Membuat [TutorialProgressRepositoryImpl] di atas [_storage].
  const TutorialProgressRepositoryImpl({required this._storage});

  /// Versi skema dokumen progres.
  static const schemaVersion = 2;

  final KeyValueStorage _storage;

  StoredValue<TutorialProgress> get _store => StoredValue<TutorialProgress>.json(
    key: _progressKey,
    fromJson: _fromJson,
    toJson: (progress) => {
      'schemaVersion': schemaVersion,
      'onboardingDone': progress.onboardingDone,
      'seenSteps': [
        for (final step in SpotlightKey.values)
          if (progress.hasSeen(step)) step.name,
      ],
    },
    storage: _storage,
  );

  static TutorialProgress _fromJson(Map<String, dynamic> json) {
    final onboardingDone = json['onboardingDone'];
    if (onboardingDone is! bool) throw const FormatException('Dokumen progres tutorial tidak valid');
    final steps = json['seenSteps'];
    if (steps is List<dynamic>) {
      final byName = {for (final step in SpotlightKey.values) step.name: step};
      return TutorialProgress(onboardingDone: onboardingDone, seenSteps: {for (final name in steps) ?byName[name]});
    }
    final tours = json['completedTours'];
    if (tours is List<dynamic>) {
      final byName = {for (final tour in TourId.values) tour.name: tour};
      return TutorialProgress(
        onboardingDone: onboardingDone,
        seenSteps: {
          for (final name in tours) ...?tourSteps[byName[name]],
        },
      );
    }
    throw const FormatException('Dokumen progres tutorial tidak valid');
  }

  Future<TutorialProgress> _read() async => await _store.read() ?? TutorialProgress.empty;

  /// Dasar untuk menulis: dokumen rusak ditimpa dari [TutorialProgress.empty],
  /// supaya menandai selesai sekaligus memulihkannya — bukan gagal selamanya.
  Future<TutorialProgress> _readForWrite() async {
    try {
      return await _read();
    } on Failure {
      return TutorialProgress.empty;
    } on FormatException {
      return TutorialProgress.empty;
    }
  }

  @override
  Future<Either<Failure, TutorialProgress>> load() => guard(_read);

  @override
  Future<Either<Failure, Unit>> markOnboardingDone() => guardVoid(() async {
    await _store.write((await _readForWrite()).copyWith(onboardingDone: true));
  });

  @override
  Future<Either<Failure, Unit>> markStepsSeen(Iterable<SpotlightKey> steps) => guardVoid(() async {
    final current = await _readForWrite();
    await _store.write(current.copyWith(seenSteps: {...current.seenSteps, ...steps}));
  });

  @override
  Future<Either<Failure, Unit>> resetTour(TourId tour) => guardVoid(() async {
    final current = await _readForWrite();
    await _store.write(current.copyWith(seenSteps: current.seenSteps.difference(tourSteps[tour]!.toSet())));
  });

  @override
  Future<Either<Failure, Unit>> resetAll() => guardVoid(() => _store.remove());
}
