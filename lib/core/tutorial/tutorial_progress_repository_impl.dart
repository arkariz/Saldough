import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/core/tutorial/tutorial_progress.dart';
import 'package:saldough/core/tutorial/tutorial_progress_repository.dart';

const _progressKey = StorageKey(namespace: 'tutorial', name: 'progress');

/// Implementasi [TutorialProgressRepository] di atas [KeyValueStorage]:
/// satu dokumen `{schemaVersion, onboardingDone, completedTours}`.
///
/// Id tur yang tidak dikenal (mis. dari versi lain) diabaikan saat dibaca,
/// bukan dianggap rusak.
final class TutorialProgressRepositoryImpl with RepositoryGuard implements TutorialProgressRepository {
  /// Membuat [TutorialProgressRepositoryImpl] di atas [_storage].
  const TutorialProgressRepositoryImpl({required this._storage});

  /// Versi skema dokumen progres.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<TutorialProgress> get _store => StoredValue<TutorialProgress>.json(
    key: _progressKey,
    fromJson: _fromJson,
    toJson: (progress) => {
      'schemaVersion': schemaVersion,
      'onboardingDone': progress.onboardingDone,
      'completedTours': [
        for (final tour in TourId.values)
          if (progress.hasCompleted(tour)) tour.name,
      ],
    },
    storage: _storage,
  );

  static TutorialProgress _fromJson(Map<String, dynamic> json) {
    final onboardingDone = json['onboardingDone'];
    final tours = json['completedTours'];
    if (onboardingDone is! bool || tours is! List<dynamic>) {
      throw const FormatException('Dokumen progres tutorial tidak valid');
    }
    final byName = {for (final tour in TourId.values) tour.name: tour};
    return TutorialProgress(
      onboardingDone: onboardingDone,
      completedTours: {for (final name in tours) ?byName[name]},
    );
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
  Future<Either<Failure, Unit>> markTourDone(TourId tour) => guardVoid(() async {
    final current = await _readForWrite();
    await _store.write(current.copyWith(completedTours: {...current.completedTours, tour}));
  });

  @override
  Future<Either<Failure, Unit>> resetTour(TourId tour) => guardVoid(() async {
    final current = await _readForWrite();
    await _store.write(current.copyWith(completedTours: {...current.completedTours}..remove(tour)));
  });

  @override
  Future<Either<Failure, Unit>> resetAll() => guardVoid(() => _store.remove());
}
