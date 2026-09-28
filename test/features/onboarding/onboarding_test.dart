import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/navigation/app_route_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/onboarding/presentation/onboarding_route.dart';
import 'package:saldough/features/onboarding/presentation/pages/onboarding_page.dart';

/// Gerak dimatikan: loop tanpa akhir membuat `pumpAndSettle` macet
/// (ADR-021 §5).
Widget _still(Widget child) => MediaQuery(
  data: const MediaQueryData(disableAnimations: true),
  child: child,
);

void main() {
  group('OnboardingPage', () {
    late List<OnboardingOutcome> outcomes;

    setUp(() => outcomes = []);

    Future<void> pumpPage(WidgetTester tester, {OnboardingMode mode = OnboardingMode.firstRun}) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => _still(child!),
          home: OnboardingPage(mode: mode, onFinished: (outcome) async => outcomes.add(outcome)),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> goToLast(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text(t.onboarding.nextAction));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('menampilkan layar pertama dan indikator halaman', (tester) async {
      await pumpPage(tester);

      expect(find.text(t.onboarding.page1Title), findsOneWidget);
      expect(find.bySemanticsLabel(t.onboarding.pageIndicatorLabel(current: 1, total: 5)), findsOneWidget);
    });

    testWidgets('Lewati mengakhiri onboarding tanpa ajakan dompet', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text(t.onboarding.skipAction));
      await tester.pumpAndSettle();

      expect(outcomes, [OnboardingOutcome.dismissed]);
    });

    testWidgets('Lanjut sampai layar akhir menampilkan ajakan dompet pertama', (tester) async {
      await pumpPage(tester);
      await goToLast(tester);

      expect(find.text(t.onboarding.finalTitle), findsOneWidget);
      expect(find.text(t.onboarding.skipAction), findsNothing);
      await tester.tap(find.text(t.onboarding.createWalletAction));
      await tester.pumpAndSettle();

      expect(outcomes, [OnboardingOutcome.createWallet]);
    });

    testWidgets('"Nanti saja" di layar akhir tetap ada (KO-6)', (tester) async {
      await pumpPage(tester);
      await goToLast(tester);

      await tester.tap(find.text(t.onboarding.laterAction));
      await tester.pumpAndSettle();

      expect(outcomes, [OnboardingOutcome.dismissed]);
    });

    testWidgets('mode tinjau diakhiri dengan Tutup, tanpa ajakan dompet', (tester) async {
      await pumpPage(tester, mode: OnboardingMode.review);
      await goToLast(tester);

      expect(find.text(t.onboarding.createWalletAction), findsNothing);
      await tester.tap(find.widgetWithText(ElevatedButton, t.onboarding.closeAction));
      await tester.pumpAndSettle();

      expect(outcomes, [OnboardingOutcome.dismissed]);
    });

    testWidgets('tidak meluap di 360dp dengan teks 2x di semua layar', (tester) async {
      tester.view
        ..physicalSize = const Size(720, 1280)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true, textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: OnboardingPage(onFinished: (outcome) async {}),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(t.onboarding.nextAction));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(find.text(t.onboarding.createWalletAction), findsOneWidget);
    });

    testWidgets('adegan bergerak saat gerak diizinkan, tanpa galat', (tester) async {
      await tester.pumpWidget(MaterialApp(home: OnboardingPage(onFinished: (outcome) async {})));
      // Loop tanpa akhir: maju dengan durasi tetap, bukan `pumpAndSettle`.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(tester.takeException(), isNull);
      expect(find.text(t.onboarding.page1Title), findsOneWidget);
    });
  });

  group('gerbang onboarding', () {
    late InMemoryKeyValueStorage storage;
    late TutorialProgressRepositoryImpl repository;
    late GetIt container;

    setUp(() {
      storage = InMemoryKeyValueStorage();
      repository = TutorialProgressRepositoryImpl(storage: storage);
      container = GetIt.asNewInstance()..registerSingleton<TutorialProgressRepository>(repository);
    });

    Future<List<ShellStartAction?>> pumpRouter(WidgetTester tester) async {
      final homes = <ShellStartAction?>[];
      final router = GoRouter(
        initialLocation: AppRouteRegistry.onboardingPath,
        routes: [
          GoRoute(
            path: AppRouteRegistry.homePath,
            builder: (context, state) {
              homes.add(state.extra as ShellStartAction?);
              return const Text('beranda');
            },
          ),
          GoRoute(path: AppRouteRegistry.onboardingPath, builder: buildOnboardingRoute),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ScopeProvider(
          container: container,
          child: MaterialApp.router(routerConfig: router, builder: (context, child) => _still(child!)),
        ),
      );
      await tester.pumpAndSettle();
      return homes;
    }

    Future<TutorialProgress> progress() async => (await repository.load()).getOrElse((_) => TutorialProgress.empty);

    testWidgets('Lewati menandai onboarding selesai lalu ke Beranda', (tester) async {
      final homes = await pumpRouter(tester);

      await tester.tap(find.text(t.onboarding.skipAction));
      await tester.pumpAndSettle();

      expect(find.text('beranda'), findsOneWidget);
      expect(homes.last, isNull);
      expect((await progress()).onboardingDone, isTrue);
    });

    testWidgets('Buat Dompet Pertama ke Beranda dengan aksi buka formulir dompet', (tester) async {
      final homes = await pumpRouter(tester);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text(t.onboarding.nextAction));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text(t.onboarding.createWalletAction));
      await tester.pumpAndSettle();

      expect(homes.last, ShellStartAction.createWallet);
      expect((await progress()).onboardingDone, isTrue);
    });
  });
}
