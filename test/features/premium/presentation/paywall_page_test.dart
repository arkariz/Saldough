import 'dart:async';

import 'package:di/di.dart' show GetIt, ScopeProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/premium/domain/paywall_trigger.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';
import 'package:saldough/features/premium/presentation/bloc/paywall_bloc.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_module.dart';
import 'package:saldough/features/premium/presentation/pages/paywall_page.dart';
import 'package:state_management/state_management.dart';

import '../../../helpers/fake_plus_purchasing.dart';
import '../../../helpers/routes.dart';

/// Paywall Plus (T-24.17a): pesan per pemicu, PlanCard, dan keadaannya.
void main() {
  late FakePlusPurchasing purchasing;

  setUp(() {
    purchasing = FakePlusPurchasing();
    addTearDown(ActivePlan.reset);
  });

  Future<void> pump(
    WidgetTester tester, {
    PaywallTrigger trigger = PaywallTrigger.account,
    bool signedIn = true,
    VoidCallback? onSignIn,
    double scale = 1,
    ThemeData? theme,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScopeProvider(
        container: GetIt.asNewInstance()
          ..registerSingleton<RouteRegistry>(appRouteRegistry()),
        child: MaterialApp(
          theme: theme ?? PixelTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider(
                    create: (_) =>
                        PaywallBloc(purchasing: purchasing)
                          ..add(const PaywallStarted()),
                    child: PaywallPage(
                      trigger: trigger,
                      signedIn: signedIn,
                      onSignIn: onSignIn ?? () {},
                    ),
                  ),
                ),
              ),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  final texts = t.premium.paywall;

  /// Menggulir ke [text] lalu mengetuknya (isi paywall bisa lebih tinggi dari layar).
  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pump();
    await tester.tap(find.text(text));
  }

  group('pesan per pemicu', () {
    testWidgets('umum: tanpa lencana Plus', (tester) async {
      await pump(tester);
      expect(find.text(texts.messages.general.title), findsOneWidget);
      expect(find.text(texts.messages.general.body), findsOneWidget);
      // Satu-satunya "Tanukonomy Plus" adalah judulnya; tanpa lencana di atasnya.
      expect(find.text(texts.kicker), findsOneWidget);
    });

    for (final (trigger, title, body) in [
      (
        PaywallTrigger.analysisHistory,
        t.premium.paywall.messages.analysis.title(n: 6),
        t.premium.paywall.messages.analysis.body,
      ),
      (
        PaywallTrigger.notificationSource,
        t.premium.paywall.messages.notification.title,
        t.premium.paywall.messages.notification.body,
      ),
      (
        PaywallTrigger.recurringAutomation,
        t.premium.paywall.messages.auto.title,
        t.premium.paywall.messages.auto.body,
      ),
      (
        PaywallTrigger.templateLimit,
        t.premium.paywall.messages.template.title,
        t.premium.paywall.messages.template.body,
      ),
      (
        PaywallTrigger.projectLimit,
        t.premium.paywall.messages.project.title,
        t.premium.paywall.messages.project.body,
      ),
      (
        PaywallTrigger.forecast,
        t.premium.paywall.messages.forecast.title,
        t.premium.paywall.messages.forecast.body,
      ),
    ]) {
      testWidgets('${trigger.name}: judul, kalimat gratis, dan lencana', (
        tester,
      ) async {
        await pump(tester, trigger: trigger);
        expect(find.text(title), findsOneWidget);
        expect(find.text(body), findsOneWidget);
        expect(find.text(texts.kicker), findsOneWidget);
      });
    }

    testWidgets('kuota tafsir: menyebut jatah Gratis dari batas yang berlaku', (
      tester,
    ) async {
      await pump(tester, trigger: PaywallTrigger.smartQuota);
      final n = ActivePlan.limits.value.freeAllowance(
        PlusFeature.smartInterpretation,
      );
      expect(find.text(texts.messages.reading.title(n: n)), findsOneWidget);
    });
  });

  group('paket', () {
    testWidgets('tahunan terpilih bawaan, harga dari toko, setara per bulan', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Rp179.000'), findsOneWidget);
      expect(find.text('Rp25.000'), findsOneWidget);
      expect(find.text(texts.yearlyEquiv(price: 'Rp14.917')), findsOneWidget);
      expect(find.text(texts.buyYearly), findsOneWidget);
      expect(find.text(texts.fineYearly(price: 'Rp179.000')), findsOneWidget);
    });

    testWidgets(
      'memilih Bulanan mengganti tombol dan kalimat wajib; beli memakai paket itu',
      (tester) async {
        await pump(tester);
        await tapText(tester, texts.monthly);
        await tester.pump();
        expect(find.text(texts.buyMonthly), findsOneWidget);
        expect(find.text(texts.fineMonthly(price: 'Rp25.000')), findsOneWidget);
        await tester.tap(find.text(texts.buyMonthly));
        await tester.pumpAndSettle();
        expect(purchasing.bought.single.kind, PlusPlanKind.monthly);
      },
    );

    testWidgets('Harga Pendiri: lencana, harga biasa dicoret, batas waktu', (
      tester,
    ) async {
      purchasing.plans = OfferedPlans(
        offering: null,
        deadline: DateTime(2027, 1, 21, 23, 59),
        options: const [
          FakePlusPurchasing.monthly,
          PlanOption(
            kind: PlusPlanKind.yearlyFounder,
            priceText: 'Rp129.000',
            regularPriceText: 'Rp179.000',
            handle: 'f',
          ),
        ],
      );
      await pump(tester);
      expect(find.text(texts.founderName), findsOneWidget);
      expect(find.text('Rp179.000'), findsOneWidget);
      expect(find.textContaining('2027'), findsOneWidget);
    });

    testWidgets(
      'penawaran sesudah uji coba: harga perkenalan dan kalimat wajib dua harga',
      (tester) async {
        purchasing.plans = OfferedPlans(
          offering: null,
          deadline: DateTime(2026, 11, 26, 21),
          options: const [
            FakePlusPurchasing.monthly,
            PlanOption(
              kind: PlusPlanKind.yearlyIntro,
              priceText: 'Rp129.000',
              regularPriceText: 'Rp179.000',
              handle: 'i',
            ),
          ],
        );
        await pump(tester);
        expect(find.text(texts.introName), findsOneWidget);
        expect(
          find.text(texts.fineIntro(price: 'Rp129.000', regular: 'Rp179.000')),
          findsOneWidget,
        );
      },
    );
  });

  group('keadaan', () {
    testWidgets('memuat: kerangka harga dan tombol beli nonaktif', (
      tester,
    ) async {
      purchasing.gate = Completer<void>();
      await pump(tester, settle: false);
      expect(find.text('Rp179.000'), findsNothing);
      expect(find.text(texts.subscribe), findsOneWidget);
      purchasing.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Rp179.000'), findsOneWidget);
    });

    testWidgets('luring: kartu "Harga belum bisa dimuat" dengan Coba lagi', (
      tester,
    ) async {
      purchasing.plans = OfferedPlans.none;
      await pump(tester);
      expect(find.text(texts.offlineTitle), findsOneWidget);
      expect(find.text('Rp179.000'), findsNothing);
      purchasing.plans = FakePlusPurchasing.defaultPlans;
      await tapText(tester, texts.retry);
      await tester.pumpAndSettle();
      expect(find.text(texts.offlineTitle), findsNothing);
      expect(find.text('Rp179.000'), findsOneWidget);
    });

    testWidgets('memproses: paket tidak bisa diubah', (tester) async {
      purchasing.buyGate = Completer<BuyResult>();
      await pump(tester);
      await tester.tap(find.text(texts.buyYearly));
      await tester.pump();
      await tapText(tester, texts.monthly);
      await tester.pump();
      expect(find.text(texts.fineYearly(price: 'Rp179.000')), findsOneWidget);
      purchasing.buyGate!.complete(const BuyCancelled());
      await tester.pumpAndSettle();
      expect(find.text(texts.buyYearly), findsOneWidget);
    });

    testWidgets('tertunda: banner dan tombol "Menunggu persetujuan"', (
      tester,
    ) async {
      purchasing.result = const BuyPending();
      await pump(tester);
      await tester.tap(find.text(texts.buyYearly));
      await tester.pumpAndSettle();
      expect(find.text(texts.pending), findsOneWidget);
      expect(find.text(texts.waiting), findsOneWidget);
    });

    testWidgets('gagal: banner galat, tombol Coba lagi membeli ulang', (
      tester,
    ) async {
      purchasing.result = const BuyFailed(PurchaseFailure.billing);
      await pump(tester);
      await tester.tap(find.text(texts.buyYearly));
      await tester.pumpAndSettle();
      expect(find.text(texts.failed), findsOneWidget);
      purchasing.result = const BuyDone();
      await tester.tap(find.text(texts.retry));
      await tester.pumpAndSettle();
      expect(purchasing.bought, hasLength(2));
    });

    testWidgets('berhasil: layar "Plus aktif" dengan Selesai', (tester) async {
      await pump(tester);
      await tester.tap(find.text(texts.buyYearly));
      await tester.pumpAndSettle();
      expect(find.text(texts.doneTitle), findsOneWidget);
      await tester.tap(find.text(texts.done));
      await tester.pumpAndSettle();
      expect(find.text('buka'), findsOneWidget);
    });

    testWidgets('Nanti saja menutup tanpa membeli', (tester) async {
      await pump(tester);
      await tester.tap(find.text(texts.later));
      await tester.pumpAndSettle();
      expect(find.text('buka'), findsOneWidget);
      expect(purchasing.bought, isEmpty);
    });
  });

  testWidgets(
    '"Lihat semua fitur Plus" membuka daftar fitur; "Lihat paket" kembali ke paywall',
    (tester) async {
      await pump(tester);
      await tester.tap(find.text(t.premium.features.seeAll));
      await tester.pumpAndSettle();
      expect(find.text(t.premium.features.title), findsOneWidget);
      await tester.tap(find.text(t.premium.features.cta));
      await tester.pumpAndSettle();
      expect(find.text(t.premium.features.title), findsNothing);
      expect(find.text(texts.messages.general.title), findsOneWidget);
    },
  );

  testWidgets('dijual dan belum masuk akun: banner "Masuk untuk mencoba Plus" membuka Akun', (tester) async {
    var opened = 0;
    await pump(tester, signedIn: false, onSignIn: () => opened++);
    expect(find.text(texts.signInForTrial), findsOneWidget);
    await tester.tap(find.text(t.premium.signInAction));
    expect(opened, 1);
  });

  testWidgets('sudah masuk akun: tanpa banner masuk', (tester) async {
    await pump(tester);
    expect(find.text(texts.signInForTrial), findsNothing);
  });

  group('Plus belum dijual', () {
    setUp(() => purchasing.selling = false);

    testWidgets(
      'tanpa akun: ajakan masuk; tombol membuka Akun; tanpa tombol beli',
      (tester) async {
        var opened = 0;
        await pump(tester, signedIn: false, onSignIn: () => opened++);
        expect(find.text(t.premium.signInTitle), findsOneWidget);
        expect(find.text(texts.buyYearly), findsNothing);
        await tester.tap(find.text(t.premium.signInAction));
        expect(opened, 1);
        expect(purchasing.offeredCalls, 0);
      },
    );

    testWidgets('sudah masuk: Plus belum dijual, tanpa tombol masuk', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text(texts.notSellingTitle), findsOneWidget);
      expect(find.text(t.premium.signInAction), findsNothing);
    });
  });

  group('tata letak', () {
    for (final dark in [false, true]) {
      testWidgets(
        '360dp, teks 200%, tema ${dark ? 'gelap' : 'terang'}: tanpa overflow',
        (tester) async {
          await pump(
            tester,
            scale: 2,
            theme: dark ? PixelTheme.dark : PixelTheme.light,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('keadaan galat di teks 200%: tanpa overflow', (tester) async {
      purchasing.result = const BuyFailed(PurchaseFailure.network);
      await pump(tester, scale: 2, trigger: PaywallTrigger.analysisHistory);
      await tester.tap(find.text(texts.buyYearly));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('analitik', () {
    testWidgets(
      'viewed saat dibuka dan dismissed saat ditutup, dengan pemicunya',
      (tester) async {
        final events = <AnalyticsEvent>[];
        AppAnalytics.debugSink = events.add;
        addTearDown(() => AppAnalytics.debugSink = null);
        await pump(tester, trigger: PaywallTrigger.notificationSource);
        expect(events, [PremiumEvents.paywallViewed(trigger: 'P2')]);
        await tester.tap(find.text(texts.later));
        await tester.pumpAndSettle();
        expect(events.last, PremiumEvents.paywallDismissed(trigger: 'P2'));
      },
    );
  });

  test(
    'modul rute: rute paywall, daftar fitur, dan hadiah; satu entri menu pengembang',
    () {
      const module = PremiumRouteModule();
      expect(module.routes, hasLength(3));
      expect(module.devEntries, hasLength(1));
    },
  );

  test('nama pemicu untuk analitik unik dan P1–P10 berurutan', () {
    final names = PaywallTrigger.values.map((t) => t.analyticsName).toList();
    expect(names.toSet(), hasLength(names.length));
    expect(names.take(10), [for (var i = 1; i <= 10; i++) 'P$i']);
  });
}
