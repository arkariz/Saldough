import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/foundation/navigation/app_route_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/onboarding/presentation/onboarding_route.dart';
import 'package:saldough/features/onboarding/presentation/pages/onboarding_page.dart';

/// Gerak dimatikan: loop tanpa akhir membuat `pumpAndSettle` macet
/// (ADR-021 §5).
Widget _still(Widget child) => MediaQuery(
  data: const MediaQueryData(disableAnimations: true),
  child: child,
);

typedef _Finished = (OnboardingOutcome, AppCurrency?);

final Finder _confirm = find.byKey(const ValueKey('onboarding-currency-confirm'));

Finder _option(AppCurrency currency) => find.byKey(ValueKey('onboarding-currency-${currency.code}'));

/// Menggulir daftar mata uang sampai [finder] terlihat utuh.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 80, scrollable: find.byType(Scrollable).last);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Memilih [currency] di langkah mata uang lalu menekan tombol lanjutnya.
Future<void> _chooseCurrency(WidgetTester tester, AppCurrency currency) async {
  await _reveal(tester, _option(currency));
  await tester.tap(_option(currency));
  await tester.pumpAndSettle();
  await tester.tap(_confirm);
  await tester.pumpAndSettle();
}

bool _confirmEnabled(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.descendant(of: _confirm, matching: find.byType(ElevatedButton))).onPressed !=
    null;

void main() {
  tearDown(() => ActiveCurrency.notifier.value = AppCurrency.idr);

  group('OnboardingPage', () {
    late List<_Finished> outcomes;

    setUp(() => outcomes = []);

    Future<void> pumpPage(WidgetTester tester, {OnboardingMode mode = OnboardingMode.firstRun}) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => _still(child!),
          home: OnboardingPage(mode: mode, onFinished: (outcome, currency) async => outcomes.add((outcome, currency))),
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

    testWidgets('Lewati menuju langkah mata uang, bukan langsung selesai', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text(t.onboarding.skipAction));
      await tester.pumpAndSettle();

      expect(outcomes, isEmpty);
      expect(find.text(t.onboarding.currencyTitle), findsOneWidget);
      await _chooseCurrency(tester, AppCurrency.usd);

      expect(outcomes, [(OnboardingOutcome.dismissed, AppCurrency.usd)]);
    });

    testWidgets('langkah mata uang tidak bisa dilewati tanpa memilih', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text(t.onboarding.skipAction));
      await tester.pumpAndSettle();

      // Tidak ada tombol lewati, tidak ada yang terpilih otomatis, dan tombol
      // lanjut nonaktif: mengetuknya berkali-kali (mis. jari yang masih
      // mengetuk "Lanjut") tidak mengakhiri onboarding.
      expect(find.text(t.onboarding.skipAction), findsNothing);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.text(t.onboarding.currencyChooseFirst), findsOneWidget);
      expect(_confirmEnabled(tester), isFalse);
      for (var i = 0; i < 3; i++) {
        await tester.tap(_confirm, warnIfMissed: false);
        await tester.pumpAndSettle();
      }
      expect(outcomes, isEmpty);

      await tester.tap(_option(AppCurrency.idr));
      await tester.pumpAndSettle();
      expect(find.text(t.onboarding.currencyConfirm(code: 'IDR')), findsOneWidget);
      expect(_confirmEnabled(tester), isTrue);
    });

    testWidgets('saran wilayah perangkat tampil paling atas tapi tidak terpilih', (tester) async {
      tester.platformDispatcher.localeTestValue = const Locale('en', 'SG');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      await pumpPage(tester);
      await tester.tap(find.text(t.onboarding.skipAction));
      await tester.pumpAndSettle();

      final sgdTop = tester.getTopLeft(_option(AppCurrency.sgd)).dy;
      expect(sgdTop, lessThan(tester.getTopLeft(_option(AppCurrency.idr)).dy));
      expect(find.text(t.onboarding.currencySuggested), findsOneWidget);
      expect(_confirmEnabled(tester), isFalse);
    });

    testWidgets('Kembali dan tombol kembali sistem kembali ke layar geser yang sama', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text(t.onboarding.nextAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.onboarding.skipAction));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('onboarding-back')));
      await tester.pumpAndSettle();
      expect(find.text(t.onboarding.page2Title), findsOneWidget);
      expect(find.text(t.onboarding.currencyTitle), findsNothing);

      await tester.tap(find.text(t.onboarding.skipAction));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(t.onboarding.page2Title), findsOneWidget);
      expect(outcomes, isEmpty);
    });

    testWidgets('Lanjut sampai layar akhir menampilkan ajakan dompet pertama', (tester) async {
      await pumpPage(tester);
      await goToLast(tester);

      expect(find.text(t.onboarding.finalTitle), findsOneWidget);
      expect(find.text(t.onboarding.skipAction), findsNothing);
      await tester.tap(find.text(t.onboarding.createWalletAction));
      await tester.pumpAndSettle();
      expect(outcomes, isEmpty);
      await _chooseCurrency(tester, AppCurrency.idr);

      expect(outcomes, [(OnboardingOutcome.createWallet, AppCurrency.idr)]);
    });

    testWidgets('"Nanti saja" di layar akhir tetap ada (KO-6)', (tester) async {
      await pumpPage(tester);
      await goToLast(tester);

      await tester.tap(find.text(t.onboarding.laterAction));
      await tester.pumpAndSettle();
      await _chooseCurrency(tester, AppCurrency.eur);

      expect(outcomes, [(OnboardingOutcome.dismissed, AppCurrency.eur)]);
    });

    testWidgets('"Sudah punya akun? Masuk" di layar akhir (ADR-024)', (tester) async {
      await pumpPage(tester);
      await goToLast(tester);

      await tester.tap(find.text(t.onboarding.signInAction));
      await tester.pumpAndSettle();
      await _chooseCurrency(tester, AppCurrency.jpy);

      expect(outcomes, [(OnboardingOutcome.signIn, AppCurrency.jpy)]);
    });

    testWidgets('mode tinjau diakhiri dengan Tutup, tanpa ajakan dompet', (tester) async {
      await pumpPage(tester, mode: OnboardingMode.review);
      await goToLast(tester);

      expect(find.text(t.onboarding.createWalletAction), findsNothing);
      expect(find.text(t.onboarding.signInAction), findsNothing);
      await tester.tap(find.widgetWithText(ElevatedButton, t.onboarding.closeAction));
      await tester.pumpAndSettle();

      // Mode tinjau tidak menanyakan mata uang; gantinya di layar Akun.
      expect(find.text(t.onboarding.currencyTitle), findsNothing);
      expect(outcomes, [(OnboardingOutcome.dismissed, null)]);
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
          home: OnboardingPage(onFinished: (outcome, currency) async {}),
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

      await tester.tap(find.text(t.onboarding.createWalletAction));
      await tester.pumpAndSettle();
      await _reveal(tester, _option(AppCurrency.idr));
      await tester.tap(_option(AppCurrency.idr));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(t.onboarding.currencyConfirm(code: 'IDR')), findsOneWidget);
    });

    testWidgets('adegan bergerak saat gerak diizinkan, tanpa galat', (tester) async {
      await tester.pumpWidget(MaterialApp(home: OnboardingPage(onFinished: (outcome, currency) async {})));
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
    late CurrencyPreferenceRepository currencyRepository;
    late GetIt container;

    setUp(() {
      storage = InMemoryKeyValueStorage();
      repository = TutorialProgressRepositoryImpl(storage: storage);
      currencyRepository = CurrencyPreferenceRepositoryImpl(storage: storage);
      container = GetIt.asNewInstance()
        ..registerSingleton<TutorialProgressRepository>(repository)
        ..registerSingleton<CurrencyPreferenceRepository>(currencyRepository);
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

    testWidgets('Lewati, pilih mata uang, lalu tersimpan, aktif, dan onboarding selesai', (tester) async {
      final homes = await pumpRouter(tester);

      await tester.tap(find.text(t.onboarding.skipAction));
      await tester.pumpAndSettle();
      expect(find.text('beranda'), findsNothing);
      expect((await progress()).onboardingDone, isFalse);
      await _chooseCurrency(tester, AppCurrency.usd);

      expect(find.text('beranda'), findsOneWidget);
      expect(homes.last, isNull);
      expect((await progress()).onboardingDone, isTrue);
      expect((await currencyRepository.load()).getOrElse((_) => AppCurrency.idr), AppCurrency.usd);
      expect(ActiveCurrency.value, AppCurrency.usd);
    });

    testWidgets('mata uang gagal tersimpan: tetap di langkah mata uang, onboarding belum selesai', (tester) async {
      container
        ..unregister<CurrencyPreferenceRepository>()
        ..registerSingleton<CurrencyPreferenceRepository>(_FailingCurrencyRepository());
      await pumpRouter(tester);

      await tester.tap(find.text(t.onboarding.skipAction));
      await tester.pumpAndSettle();
      await _chooseCurrency(tester, AppCurrency.usd);

      expect(find.text('beranda'), findsNothing);
      expect(_confirm, findsOneWidget);
      expect(find.text(t.common.genericErrorMessage), findsOneWidget);
      expect((await progress()).onboardingDone, isFalse);
      expect(ActiveCurrency.value, AppCurrency.idr);
    });

    testWidgets('Buat Dompet Pertama ke Beranda dengan aksi buka formulir dompet', (tester) async {
      final homes = await pumpRouter(tester);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text(t.onboarding.nextAction));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text(t.onboarding.createWalletAction));
      await tester.pumpAndSettle();
      await _chooseCurrency(tester, AppCurrency.idr);

      expect(homes.last, ShellStartAction.createWallet);
      expect((await progress()).onboardingDone, isTrue);
    });

    testWidgets('Masuk ke Beranda dengan aksi buka layar Akun', (tester) async {
      final homes = await pumpRouter(tester);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text(t.onboarding.nextAction));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text(t.onboarding.signInAction));
      await tester.pumpAndSettle();
      await _chooseCurrency(tester, AppCurrency.idr);

      expect(homes.last, ShellStartAction.openAccount);
      expect((await progress()).onboardingDone, isTrue);
    });

    testWidgets('Menu info "Pengenalan Tanukonomy" membuka onboarding mode tinjau tanpa mengubah progres', (
      tester,
    ) async {
      await repository.markOnboardingDone();
      final router = GoRouter(
        initialLocation: '/layar',
        routes: [
          GoRoute(
            path: '/layar',
            builder: (context, state) => const Scaffold(body: Center(child: TutorialInfoButton(tour: TourId.home))),
          ),
          GoRoute(path: AppRouteRegistry.onboardingPath, builder: buildOnboardingRoute),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ScopeProvider(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => _still(SpotlightHost(repository: repository, child: child!)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(t.info.menuTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.info.showIntroAction));
      await tester.pumpAndSettle();
      expect(find.text(t.onboarding.page1Title), findsOneWidget);

      await tester.tap(find.text(t.onboarding.closeAction));
      await tester.pumpAndSettle();
      expect(find.byType(TutorialInfoButton), findsOneWidget);
      expect((await progress()).onboardingDone, isTrue);
    });
  });
}

class _FailingCurrencyRepository implements CurrencyPreferenceRepository {
  @override
  Future<Either<Failure, AppCurrency>> load() async => const Right(AppCurrency.idr);

  @override
  Future<Either<Failure, Unit>> save(AppCurrency currency) async =>
      const Left(SystemFailure(code: FailureCode.unknown, message: 'uji'));
}
