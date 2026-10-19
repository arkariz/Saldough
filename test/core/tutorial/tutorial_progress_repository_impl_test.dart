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

  test('menandai onboarding dan langkah dilihat lalu membacanya kembali', () async {
    await repository.markOnboardingDone();
    await repository.markStepsSeen([SpotlightKey.homeBalance, SpotlightKey.homeRecord]);
    await repository.markStepsSeen([SpotlightKey.walletAdd]);

    final progress = await loaded();
    expect(progress.onboardingDone, isTrue);
    expect(progress.seenSteps, {SpotlightKey.homeBalance, SpotlightKey.homeRecord, SpotlightKey.walletAdd});
  });

  test('tur selesai hanya kalau semua langkahnya sudah dilihat', () async {
    await repository.markStepsSeen([SpotlightKey.homeBalance, SpotlightKey.homeRecord]);
    expect((await loaded()).hasCompleted(TourId.home), isFalse);

    await repository.markStepsSeen(tourSteps[TourId.home]!);
    expect((await loaded()).hasCompleted(TourId.home), isTrue);
  });

  test('resetTour hanya mengembalikan langkah tur itu', () async {
    await repository.markOnboardingDone();
    await repository.markStepsSeen([...tourSteps[TourId.home]!, ...tourSteps[TourId.budget]!]);
    await repository.resetTour(TourId.home);

    final progress = await loaded();
    expect(progress.onboardingDone, isTrue);
    expect(progress.seenSteps, tourSteps[TourId.budget]!.toSet());
  });

  test('resetAll mengembalikan semuanya ke belum dilihat', () async {
    await repository.markOnboardingDone();
    await repository.markStepsSeen([SpotlightKey.recordKind]);
    await repository.resetAll();

    expect(await loaded(), TutorialProgress.empty);
  });

  test('dokumen rusak menghasilkan Left, dan menulis memulihkannya', () async {
    await storage.write('tutorial_progress', '{bukan json');
    expect((await repository.load()).isLeft(), isTrue);

    await repository.markStepsSeen([SpotlightKey.homeBalance]);
    expect(await loaded(), const TutorialProgress(onboardingDone: false, seenSteps: {SpotlightKey.homeBalance}));
  });

  test('bentuk field salah dianggap rusak', () async {
    await storage.write('tutorial_progress', '{"schemaVersion":2,"onboardingDone":"ya","seenSteps":[]}');
    expect((await repository.load()).isLeft(), isTrue);
  });

  test('id langkah yang tidak dikenal diabaikan', () async {
    await storage.write(
      'tutorial_progress',
      '{"schemaVersion":2,"onboardingDone":true,"seenSteps":["homeBalance","langkah_masa_depan"]}',
    );
    expect(await loaded(), const TutorialProgress(onboardingDone: true, seenSteps: {SpotlightKey.homeBalance}));
  });

  test('versi 1 dimigrasi: tur selesai berarti semua langkahnya sudah dilihat', () async {
    await storage.write(
      'tutorial_progress',
      '{"schemaVersion":1,"onboardingDone":true,"completedTours":["wallet","tur_masa_depan"]}',
    );

    final progress = await loaded();
    expect(progress.onboardingDone, isTrue);
    expect(progress.seenSteps, tourSteps[TourId.wallet]!.toSet());

    await repository.markStepsSeen([SpotlightKey.homeBalance]);
    expect(await storage.read('tutorial_progress'), contains('"schemaVersion":3'));
  });

  group('langkah wajib onboarding (Fase 21)', () {
    test('menandai langkah dijawab per langkah dan membacanya kembali', () async {
      await repository.markOnboardingStepAnswered(OnboardingStep.period);

      var progress = await loaded();
      expect(progress.answeredSteps, {OnboardingStep.period});
      expect(progress.isStepPending(OnboardingStep.period), isFalse);
      expect(progress.isStepPending(OnboardingStep.reminder), isTrue);

      await repository.markOnboardingStepAnswered(OnboardingStep.reminder);
      progress = await loaded();
      expect(progress.answeredSteps, OnboardingStep.values.toSet());
    });

    test('jawaban bertahan lewat markOnboardingDone dan markStepsSeen', () async {
      await repository.markOnboardingStepAnswered(OnboardingStep.period);
      await repository.markStepsSeen([SpotlightKey.homeBalance]);
      await repository.markOnboardingDone();

      final progress = await loaded();
      expect(progress.answeredSteps, {OnboardingStep.period});
      expect(progress.seenSteps, {SpotlightKey.homeBalance});
    });

    test('pengguna lama (versi 2, onboarding sudah selesai) tidak dipaksa mengulang', () async {
      await storage.write(
        'tutorial_progress',
        '{"schemaVersion":2,"onboardingDone":true,"seenSteps":["homeBalance"]}',
      );

      final progress = await loaded();
      expect(progress.answeredSteps, isEmpty);
      for (final step in OnboardingStep.values) {
        expect(progress.isStepPending(step), isFalse, reason: step.name);
      }
    });

    test('instalasi baru: kedua langkah wajib menunggu jawaban', () async {
      final progress = await loaded();
      for (final step in OnboardingStep.values) {
        expect(progress.isStepPending(step), isTrue, reason: step.name);
      }
    });

    test('nama langkah yang tidak dikenal diabaikan', () async {
      await storage.write(
        'tutorial_progress',
        '{"schemaVersion":3,"onboardingDone":false,"seenSteps":[],"answeredSteps":["period","langkah_masa_depan"]}',
      );

      expect((await loaded()).answeredSteps, {OnboardingStep.period});
    });

    test('resetAll melupakan jawaban', () async {
      await repository.markOnboardingStepAnswered(OnboardingStep.period);
      await repository.resetAll();

      expect(await loaded(), TutorialProgress.empty);
    });
  });
}
