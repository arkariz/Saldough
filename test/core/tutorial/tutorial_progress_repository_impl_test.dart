import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/tutorial/tutorial.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late TutorialProgressRepositoryImpl repository;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = TutorialProgressRepositoryImpl(storage: storage);
  });

  Future<TutorialProgress> loaded() async => (await repository.load()).getOrElse((_) => throw StateError('Left'));

  test('dokumen belum ada berarti belum ada yang dilihat', () async {
    expect(await loaded(), TutorialProgress.empty);
  });

  test('menandai onboarding dan tur selesai lalu membacanya kembali', () async {
    await repository.markOnboardingDone();
    await repository.markTourDone(TourId.home);
    await repository.markTourDone(TourId.wallet);

    final progress = await loaded();
    expect(progress.onboardingDone, isTrue);
    expect(progress.completedTours, {TourId.home, TourId.wallet});
  });

  test('resetTour hanya mengembalikan satu tur', () async {
    await repository.markOnboardingDone();
    await repository.markTourDone(TourId.home);
    await repository.markTourDone(TourId.budget);
    await repository.resetTour(TourId.home);

    final progress = await loaded();
    expect(progress.onboardingDone, isTrue);
    expect(progress.completedTours, {TourId.budget});
  });

  test('resetAll mengembalikan semuanya ke belum dilihat', () async {
    await repository.markOnboardingDone();
    await repository.markTourDone(TourId.record);
    await repository.resetAll();

    expect(await loaded(), TutorialProgress.empty);
  });

  test('dokumen rusak menghasilkan Left, dan menulis memulihkannya', () async {
    await storage.write('tutorial_progress', '{bukan json');
    expect((await repository.load()).isLeft(), isTrue);

    await repository.markTourDone(TourId.home);
    expect(await loaded(), const TutorialProgress(onboardingDone: false, completedTours: {TourId.home}));
  });

  test('bentuk field salah dianggap rusak', () async {
    await storage.write('tutorial_progress', '{"schemaVersion":1,"onboardingDone":"ya","completedTours":[]}');
    expect((await repository.load()).isLeft(), isTrue);
  });

  test('id tur yang tidak dikenal diabaikan', () async {
    await storage.write(
      'tutorial_progress',
      '{"schemaVersion":1,"onboardingDone":true,"completedTours":["home","tur_masa_depan"]}',
    );
    expect(await loaded(), const TutorialProgress(onboardingDone: true, completedTours: {TourId.home}));
  });
}
