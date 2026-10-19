import 'package:di/di.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/navigation/app_route_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/onboarding/presentation/onboarding_route.dart';
import 'package:saldough/features/onboarding/presentation/pages/onboarding_page.dart';

/// Langkah wajib baru onboarding (Fase 21, FEATURE_DISCOVERY §4).
Widget _still(Widget child) => MediaQuery(data: const MediaQueryData(disableAnimations: true), child: child);

final Finder _back = find.byKey(const ValueKey('onboarding-back'));
final Finder _periodConfirm = find.byKey(const ValueKey('onboarding-period-confirm'));
final Finder _turnOn = find.byKey(const ValueKey('onboarding-reminder-turn-on'));
final Finder _notNow = find.byKey(const ValueKey('onboarding-reminder-not-now'));
final Finder _reminderNext = find.byKey(const ValueKey('onboarding-reminder-next'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Bahasa › layar geser › mata uang IDR, sampai langkah awal periode.
Future<void> _toPeriod(WidgetTester tester) async {
  await _tap(tester, find.byKey(const ValueKey('onboarding-language-confirm')));
  await _tap(tester, find.text(t.onboarding.skipAction));
  final idr = find.byKey(const ValueKey('onboarding-currency-IDR'));
  await tester.scrollUntilVisible(idr, 80, scrollable: find.byType(Scrollable).last);
  await _tap(tester, idr);
  await _tap(tester, find.byKey(const ValueKey('onboarding-currency-confirm')));
}

void main() {
  tearDown(() {
    ActiveCurrency.notifier.value = AppCurrency.idr;
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
    LocaleSettings.setLocaleSync(AppLocale.id);
    ActiveLanguage.notifier.value = AppLocale.id;
  });

  group('OnboardingPage langkah wajib', () {
    late List<FinancialMonthStart> periods;
    late List<(OnboardingOutcome, AppCurrency?)> finished;
    var reminderResult = true;
    var periodResult = true;
    var turnOns = 0;
    var declines = 0;

    setUp(() {
      periods = [];
      finished = [];
      reminderResult = true;
      periodResult = true;
      turnOns = 0;
      declines = 0;
    });

    Future<void> pump(
      WidgetTester tester, {
      OnboardingMode mode = OnboardingMode.firstRun,
      bool skipPeriod = false,
      bool skipReminder = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => _still(child!),
          home: OnboardingPage(
            mode: mode,
            skipPeriod: skipPeriod,
            skipReminder: skipReminder,
            onFinished: (outcome, currency) async => finished.add((outcome, currency)),
            onLanguageSelected: (_) async {},
            onPeriodConfirmed: (start) async {
              periods.add(start);
              return periodResult;
            },
            onTurnOnReminders: () async {
              turnOns++;
              return reminderResult;
            },
            onRemindersDeclined: () async => declines++,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('awal periode: tanggal 1 terpilih, tombol menyebut tanggal, tanpa Lewati', (tester) async {
      await pump(tester);
      await _toPeriod(tester);

      expect(find.text(t.onboarding.periodTitle), findsOneWidget);
      expect(find.text(t.onboarding.periodBody), findsOneWidget);
      expect(find.text(t.onboarding.periodConfirm(day: 1)), findsOneWidget);
      expect(find.text(t.onboarding.skipAction), findsNothing);

      await _tap(tester, find.byKey(const ValueKey('day-25')));
      expect(find.text(t.onboarding.periodConfirm(day: 25)), findsOneWidget);

      await _tap(tester, _periodConfirm);
      expect(periods, [const FinancialMonthStart.day(25)]);
      expect(find.text(t.onboarding.reminderTitle), findsOneWidget);
    });

    testWidgets('hari terakhir bulan: tombol menyebut hari terakhir', (tester) async {
      await pump(tester);
      await _toPeriod(tester);

      await _tap(tester, find.byKey(const ValueKey('day-last')));
      expect(find.text(t.onboarding.periodConfirmLast), findsOneWidget);
      await _tap(tester, _periodConfirm);

      expect(periods, [FinancialMonthStart.lastDay]);
    });

    testWidgets('gagal menyimpan: tetap di awal periode', (tester) async {
      periodResult = false;
      await pump(tester);
      await _toPeriod(tester);

      await _tap(tester, _periodConfirm);

      expect(find.text(t.onboarding.periodTitle), findsOneWidget);
      expect(find.text(t.onboarding.reminderTitle), findsNothing);
    });

    testWidgets('pengingat Nyalakan berhasil: status Nyala dan Lanjut, tanpa Nyalakan lagi', (tester) async {
      await pump(tester);
      await _toPeriod(tester);
      await _tap(tester, _periodConfirm);

      expect(_reminderNext, findsNothing);
      await _tap(tester, _turnOn);

      expect(turnOns, 1);
      expect(find.text(t.discovery.status.on), findsOneWidget);
      expect(_turnOn, findsNothing);
      expect(_notNow, findsNothing);
      await _tap(tester, _reminderNext);
      expect(find.text(t.onboarding.finalTitle), findsOneWidget);
      expect(find.text(t.discovery.status.on), findsOneWidget);
    });

    testWidgets('izin ditolak: tetap lanjut dengan status Izin belum diberikan', (tester) async {
      reminderResult = false;
      await pump(tester);
      await _toPeriod(tester);
      await _tap(tester, _periodConfirm);

      await _tap(tester, _turnOn);

      expect(find.text(t.discovery.status.permissionNeeded), findsOneWidget);
      await _tap(tester, _reminderNext);
      expect(find.text(t.onboarding.finalTitle), findsOneWidget);
      expect(find.text(t.discovery.status.permissionNeeded), findsOneWidget);
    });

    testWidgets('Tidak sekarang: langsung ke penutup dengan status Mati, tanpa meminta izin', (tester) async {
      await pump(tester);
      await _toPeriod(tester);
      await _tap(tester, _periodConfirm);

      await _tap(tester, _notNow);

      expect(turnOns, 0);
      expect(declines, 1);
      expect(find.text(t.onboarding.finalTitle), findsOneWidget);
      expect(find.text(t.discovery.status.off), findsOneWidget);
    });

    testWidgets('penutup: ringkasan dua jawaban lalu ajakan dompet', (tester) async {
      await pump(tester);
      await _toPeriod(tester);
      await _tap(tester, find.byKey(const ValueKey('day-25')));
      await _tap(tester, _periodConfirm);
      await _tap(tester, _notNow);

      expect(find.text(t.onboarding.summaryPeriod), findsOneWidget);
      expect(find.text(t.plan.financialMonthDay(day: 25)), findsOneWidget);
      expect(find.text(t.onboarding.summaryReminder), findsOneWidget);
      await _tap(tester, find.text(t.onboarding.createWalletAction));
      expect(finished, [(OnboardingOutcome.createWallet, AppCurrency.idr)]);
    });

    testWidgets('baris informasi Catat dari notifikasi hanya di Android dan tidak dapat diketuk', (tester) async {
      Future<void> toFinale() async {
        await pump(tester);
        await _toPeriod(tester);
        await _tap(tester, _periodConfirm);
        await _tap(tester, _notNow);
      }

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await toFinale();
      expect(find.byKey(const ValueKey('onboarding-notification-info')), findsOneWidget);
      expect(find.text(t.onboarding.notificationInfo), findsOneWidget);
      // Tanpa satu pun tombol atau izin untuk fitur ini di onboarding.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('onboarding-notification-info')),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.pumpWidget(const SizedBox());
      await toFinale();
      expect(find.byKey(const ValueKey('onboarding-notification-info')), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Kembali (tombol dan sistem) mundur satu langkah, tanpa keluar dari onboarding', (tester) async {
      await pump(tester);
      await _toPeriod(tester);
      await _tap(tester, _periodConfirm);
      await _tap(tester, _notNow);
      expect(find.text(t.onboarding.finalTitle), findsOneWidget);

      await _tap(tester, _back);
      expect(find.text(t.onboarding.reminderTitle), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(t.onboarding.periodTitle), findsOneWidget);

      await _tap(tester, _back);
      expect(find.text(t.onboarding.currencyTitle), findsOneWidget);

      await _tap(tester, _back);
      expect(find.text(t.onboarding.page1Title), findsOneWidget);
      expect(finished, isEmpty);
    });

    testWidgets('Lewati di layar geser melompat ke langkah wajib, tidak keluar', (tester) async {
      await pump(tester);
      await _tap(tester, find.byKey(const ValueKey('onboarding-language-confirm')));

      await _tap(tester, find.text(t.onboarding.skipAction));

      expect(find.text(t.onboarding.currencyTitle), findsOneWidget);
      expect(finished, isEmpty);
    });

    testWidgets('langkah yang sudah dijawab sebelumnya dilewati', (tester) async {
      await pump(tester, skipPeriod: true, skipReminder: true);
      await _toPeriod(tester);

      expect(find.text(t.onboarding.finalTitle), findsOneWidget);
      expect(periods, isEmpty);
    });

    testWidgets('mode tinjau tidak menanyakan langkah wajib dan boleh ditutup', (tester) async {
      await pump(tester, mode: OnboardingMode.review);

      expect(find.text(t.onboarding.languageTitle), findsNothing);
      await _tap(tester, find.text(t.onboarding.closeAction).first);

      expect(finished, [(OnboardingOutcome.dismissed, null)]);
      expect(periods, isEmpty);
      expect(turnOns, 0);
    });

    testWidgets('muat di 360dp dengan teks 2x, id dan en', (tester) async {
      for (final locale in [AppLocale.id, AppLocale.en]) {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
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
            home: OnboardingPage(
              key: ValueKey(locale),
              onFinished: (_, _) async {},
              onPeriodConfirmed: (_) async => true,
              onTurnOnReminders: () async => true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _toPeriod(tester);
        expect(tester.takeException(), isNull);
        await _tap(tester, _periodConfirm);
        expect(tester.takeException(), isNull);
        await _tap(tester, _turnOn);
        await _tap(tester, _reminderNext);
        expect(tester.takeException(), isNull);
      }
      LocaleSettings.setLocaleSync(AppLocale.id);
    });
  });

  group('rute onboarding langkah wajib', () {
    late InMemoryKeyValueStorage storage;
    late TutorialProgressRepositoryImpl tutorial;
    late FinancialMonthPreferenceRepositoryImpl financialMonth;
    late GetIt container;
    var reminderGranted = true;
    var enabled = 0;

    setUp(() {
      storage = InMemoryKeyValueStorage();
      tutorial = TutorialProgressRepositoryImpl(storage: storage);
      financialMonth = FinancialMonthPreferenceRepositoryImpl(storage: storage);
      reminderGranted = true;
      enabled = 0;
      container = GetIt.asNewInstance()
        ..registerSingleton<TutorialProgressRepository>(tutorial)
        ..registerSingleton<FinancialMonthPreferenceRepository>(financialMonth)
        ..registerSingleton<CurrencyPreferenceRepository>(CurrencyPreferenceRepositoryImpl(storage: storage))
        ..registerSingleton<ChangeAppLanguage>(
          ChangeAppLanguage(repository: LanguagePreferenceRepositoryImpl(storage: storage)),
        );
    });

    Future<void> pumpRouter(WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: AppRouteRegistry.onboardingPath,
        routes: [
          GoRoute(path: AppRouteRegistry.homePath, builder: (_, _) => const Text('beranda')),
          GoRoute(
            path: AppRouteRegistry.onboardingPath,
            builder: (context, state) => buildOnboardingRoute(
              context,
              state,
              enableReminders: () async {
                enabled++;
                return reminderGranted;
              },
            ),
          ),
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
    }

    Future<TutorialProgress> progress() async => (await tutorial.load()).getOrElse((_) => TutorialProgress.empty);

    testWidgets('awal periode tersimpan sejak awal: tanpa periode peralihan, langkah tercatat dijawab', (tester) async {
      await pumpRouter(tester);
      await _toPeriod(tester);
      await _tap(tester, find.byKey(const ValueKey('day-25')));

      await _tap(tester, _periodConfirm);

      final saved = (await financialMonth.load()).getOrElse((_) => FinancialMonthSchedule.initial);
      expect(saved.active, const FinancialMonthStart.day(25));
      expect(saved.entries, hasLength(1));
      // Ditetapkan sebelum ada data: tanggal mana pun tidak membuat periode peralihan.
      for (final today in [
        DateTime(2026, 10, 3),
        DateTime(2026, 10, 19),
        DateTime(2026, 10, 25),
        DateTime(2026, 10, 31),
      ]) {
        expect(saved.periodOf(today).isTransition, isFalse, reason: '$today');
      }
      expect(ActiveFinancialMonth.schedule.active, const FinancialMonthStart.day(25));
      expect((await progress()).answeredSteps, {OnboardingStep.period});
    });

    testWidgets('pengingat: Nyalakan memanggil alur izin dan mencatat jawaban', (tester) async {
      await pumpRouter(tester);
      await _toPeriod(tester);
      await _tap(tester, _periodConfirm);

      await _tap(tester, _turnOn);

      expect(enabled, 1);
      expect((await progress()).answeredSteps, {OnboardingStep.period, OnboardingStep.reminder});
    });

    testWidgets('pengingat: Tidak sekarang tidak meminta izin tetapi tetap tercatat dijawab', (tester) async {
      await pumpRouter(tester);
      await _toPeriod(tester);
      await _tap(tester, _periodConfirm);

      await _tap(tester, _notNow);

      expect(enabled, 0);
      expect((await progress()).answeredSteps, contains(OnboardingStep.reminder));
      expect((await progress()).onboardingDone, isFalse);
    });

    testWidgets('onboarding yang terputus: langkah yang sudah dijawab tidak ditanya lagi', (tester) async {
      await tutorial.markOnboardingStepAnswered(OnboardingStep.period);
      await tutorial.markOnboardingStepAnswered(OnboardingStep.reminder);
      await pumpRouter(tester);

      await _toPeriod(tester);

      expect(find.text(t.onboarding.finalTitle), findsOneWidget);
    });
  });
}
