import 'package:di/di.dart' show GetIt, ScopeProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/premium/domain/offering_policy.dart';
import 'package:saldough/features/premium/domain/plus_moments.dart';
import 'package:saldough/features/premium/domain/plus_purchasing.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';
import 'package:saldough/features/premium/domain/trial_gift.dart';
import 'package:saldough/features/premium/presentation/pages/plus_downgrade_page.dart';
import 'package:saldough/features/premium/presentation/widgets/plus_home_card.dart';
import 'package:saldough/features/premium/presentation/widgets/trial_gift_host.dart';
import 'package:saldough/shared/auth/auth.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_plus_purchasing.dart';
import '../../../helpers/routes.dart';

final class _Moments implements PlusMoments {
  PlusCard? current;
  PlusDowngrade? down;
  final dismissed = <PlusCard>[];
  int shown = 0;

  @override
  Future<PlusCard?> card() async => current;

  @override
  Future<void> dismiss(PlusCard card) async {
    dismissed.add(card);
    current = null;
  }

  @override
  Future<PlusDowngrade?> downgrade() async => shown > 0 ? null : down;

  @override
  Future<void> markDowngradeShown() async => shown++;
}

final class _NoGift implements TrialGift {
  @override
  Future<TrialGiftInfo?> pending() async => null;

  @override
  Future<DateTime?> setPayday(FinancialMonthStart start) async => null;

  @override
  Future<void> markSeen() async {}
}

/// Kartu Plus di Beranda dan layar turun (T-24.17e).
void main() {
  late _Moments moments;
  late GetIt container;
  final texts = t.premium;

  setUp(() {
    moments = _Moments();
    container = GetIt.asNewInstance()
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
      ..registerSingleton<PlusMoments>(moments)
      ..registerSingleton<TrialGift>(_NoGift())
      ..registerSingleton<PlusPurchasing>(FakePlusPurchasing(selling: false))
      ..registerSingleton<AuthRepository>(FakeAuthRepository());
    addTearDown(ActivePlan.reset);
  });

  Future<void> pump(WidgetTester tester, Widget child, {double scale = 1}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          theme: PixelTheme.light,
          builder: (context, c) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: c!,
          ),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('PlusHomeCard', () {
    testWidgets('tanpa momen: tidak menggambar apa pun', (tester) async {
      await pump(tester, PlusHomeCard(container: container));
      expect(find.byKey(const ValueKey('plus-home-card')), findsNothing);
    });

    testWidgets('rekap: judul tanggal, angka pemakai, Nanti saja menutup', (tester) async {
      moments.current = PlusRecapCard(start: DateTime(2026, 11), endsOn: DateTime(2026, 11, 24), recorded: 14);
      await pump(tester, PlusHomeCard(container: container));
      expect(find.text(texts.card.recapTitle(date: '24 Nov')), findsOneWidget);
      expect(find.text(texts.card.recapSince(date: '1 Nov')), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      await tester.tap(find.text(texts.paywall.later));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('plus-home-card')), findsNothing);
      expect(moments.dismissed, hasLength(1));
    });

    testWidgets('rekap tanpa catatan: tidak ada baris angka', (tester) async {
      moments.current = PlusRecapCard(start: DateTime(2026, 11), endsOn: DateTime(2026, 11, 24), recorded: 0);
      await pump(tester, PlusHomeCard(container: container));
      expect(find.text(texts.card.recapRecorded), findsNothing);
    });

    testWidgets('konteks: pesan sama dengan paywall tafsir; Lihat Plus membuka paywall', (tester) async {
      moments.current = const PlusContextCard(limit: 30, periodKey: '2026-11-01');
      await pump(tester, PlusHomeCard(container: container));
      expect(find.text(texts.paywall.messages.reading.title(n: 30)), findsOneWidget);
      await tester.tap(find.text(texts.seePlus));
      await tester.pumpAndSettle();
      expect(find.text(texts.paywall.messages.reading.title(n: 30)), findsWidgets);
      expect(find.text(texts.paywall.later), findsOneWidget);
    });

    testWidgets('360dp teks 200%: tanpa overflow', (tester) async {
      moments.current = PlusRecapCard(start: DateTime(2026, 11), endsOn: DateTime(2026, 11, 24), recorded: 14);
      await pump(tester, PlusHomeCard(container: container), scale: 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('PlusDowngradePage', () {
    const offer = OfferedPlans(
      offering: OfferingId.postTrial,
      options: [
        PlanOption(kind: PlusPlanKind.yearlyIntro, priceText: 'Rp129.000', regularPriceText: 'Rp179.000', handle: 'i'),
      ],
    );

    Future<void> pumpPage(WidgetTester tester, PlusDowngrade data, {double scale = 1}) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ScopeProvider(
          container: container,
          child: MaterialApp(
            theme: PixelTheme.light,
            builder: (context, c) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: c!,
            ),
            home: PlusDowngradePage(data: data),
          ),
        ),
      );
    }

    testWidgets('angka pemakai sendiri, kartu penawaran, dan dua tombol', (tester) async {
      await pumpPage(
        tester,
        PlusDowngrade(
          sources: 3,
          autoRules: 4,
          freePeriods: 6,
          offer: OfferedPlans(offering: offer.offering, options: offer.options, deadline: DateTime(2026, 11, 26, 21)),
        ),
      );
      final d = texts.downgrade;
      expect(find.text(d.notifSub(n: 3)), findsOneWidget);
      expect(find.text(d.autoSub(n: 4)), findsOneWidget);
      expect(find.text(d.analysisSub(n: 6)), findsOneWidget);
      await tester.scrollUntilVisible(find.text(d.dealKicker(until: '26 Nov, 21.00')), 200);
      expect(find.text(d.dealKicker(until: '26 Nov, 21.00')), findsOneWidget);
      expect(find.text('Rp129.000'), findsOneWidget);
      expect(find.text(d.ctaDeal), findsOneWidget);
      await tester.tap(find.text(d.free));
      await tester.pumpAndSettle();
    });

    testWidgets('baris yang tidak berubah dilewati; tanpa penawaran: Lihat Plus', (tester) async {
      await pumpPage(tester, const PlusDowngrade(sources: 1, autoRules: 0, freePeriods: 6));
      final d = texts.downgrade;
      expect(find.text(d.notifTitle), findsNothing);
      expect(find.text(d.autoTitle), findsNothing);
      expect(find.text(d.analysisTitle), findsOneWidget);
      expect(find.byKey(const ValueKey('downgrade-offer')), findsNothing);
      expect(find.text(d.ctaPlain), findsOneWidget);
    });

    testWidgets('360dp teks 200%: tanpa overflow', (tester) async {
      await pumpPage(tester, const PlusDowngrade(sources: 3, autoRules: 4, freePeriods: 6, offer: offer), scale: 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('TrialGiftHost: layar turun', () {
    Future<void> pumpHost(WidgetTester tester) async {
      await tester.pumpWidget(
        ScopeProvider(
          container: container,
          child: MaterialApp(
            theme: PixelTheme.light,
            home: Scaffold(body: TrialGiftHost(container: container, active: true)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Gratis dengan layar turun menunggu: terbuka sekali dan ditandai', (tester) async {
      moments.down = const PlusDowngrade(sources: 2, autoRules: 0, freePeriods: 6);
      await pumpHost(tester);
      expect(find.text(texts.downgrade.title), findsOneWidget);
      expect(moments.shown, 1);
    });

    testWidgets('Plus aktif: tidak membuka layar turun', (tester) async {
      ActivePlan.notifier.value = const PlusPlan(source: PlanSource.purchase);
      moments.down = const PlusDowngrade(sources: 2, autoRules: 0, freePeriods: 6);
      await pumpHost(tester);
      expect(find.text(texts.downgrade.title), findsNothing);
    });
  });
}
