import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/premium/domain/plus_purchasing.dart';
import 'package:saldough/features/premium/presentation/widgets/account_plus_section.dart';
import 'package:saldough/shared/auth/auth.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_plus_purchasing.dart';
import '../../../helpers/routes.dart';

/// Bagian Plus di Akun (T-24.17c): satu baris status per keadaan paket.
void main() {
  late FakePlusPurchasing purchasing;
  late List<Uri> launched;
  late GetIt container;

  setUp(() {
    purchasing = FakePlusPurchasing(selling: false);
    launched = [];
    container = GetIt.asNewInstance()
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
      ..registerSingleton<PlusPurchasing>(purchasing)
      ..registerSingleton<AuthRepository>(FakeAuthRepository());
    addTearDown(ActivePlan.reset);
  });

  Future<void> pump(WidgetTester tester, PlanState plan, {double scale = 1}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    ActivePlan.notifier.value = plan;
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          theme: PixelTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AccountPlusSection(
                purchasing: purchasing,
                launch: (uri) async {
                  launched.add(uri);
                  return true;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  final texts = t.premium.account;

  testWidgets('Gratis: tanpa lencana dan tanpa Kelola; Pulihkan selalu ada', (tester) async {
    await pump(tester, const FreePlan());
    expect(find.text(texts.subFree), findsOneWidget);
    expect(find.text(texts.manage), findsNothing);
    expect(find.text(texts.restore), findsOneWidget);
  });

  testWidgets('uji coba: lencana dan tanggal akhir, tanpa Kelola', (tester) async {
    await pump(tester, TrialPlan(endsOn: DateTime(2026, 11, 24)));
    expect(find.text(texts.subTrial(date: '24 Nov 2026')), findsOneWidget);
    expect(find.text(texts.badgeTrial), findsOneWidget);
    expect(find.text(texts.manage), findsNothing);
  });

  testWidgets('aktif beli: tanggal akhir periode dan Kelola membuka Play Store', (tester) async {
    await pump(tester, PlusPlan(source: PlanSource.purchase, until: DateTime(2027, 10, 22)));
    expect(find.text(texts.subActive(date: '22 Okt 2027')), findsOneWidget);
    await tester.tap(find.text(texts.manage));
    expect(launched, [playSubscriptionsUri]);
  });

  testWidgets('tenggang dan ditahan: lencana Cek dan Kelola', (tester) async {
    await pump(tester, PlusPlan(source: PlanSource.purchase, until: DateTime(2026, 10, 25), inGrace: true));
    expect(find.text(texts.subGrace(date: '25 Okt 2026')), findsOneWidget);
    expect(find.text(texts.badgeCheck), findsOneWidget);
    expect(find.text(texts.manage), findsOneWidget);
    ActivePlan.notifier.value = OnHoldPlan(since: DateTime(2026, 10, 26));
    await tester.pump();
    expect(find.text(texts.subOnHold), findsOneWidget);
    expect(find.text(texts.manage), findsOneWidget);
  });

  testWidgets('penguji: dari program penguji, tanpa Kelola', (tester) async {
    await pump(tester, PlusPlan(source: PlanSource.promotional, until: DateTime(2027, 10, 22)));
    expect(find.text(texts.subTester(date: '22 Okt 2027')), findsOneWidget);
    expect(find.text(texts.manage), findsNothing);
    ActivePlan.notifier.value = const PlusPlan(source: PlanSource.prelaunch);
    await tester.pump();
    expect(find.text(texts.subTesterOpen), findsOneWidget);
  });

  testWidgets('Pulihkan pembelian memanggil pemulihan dan memberi tahu', (tester) async {
    await pump(tester, const FreePlan());
    await tester.tap(find.text(texts.restore));
    await tester.pump();
    await tester.pump();
    expect(purchasing.restored, 1);
    expect(find.text(texts.restoreDone), findsOneWidget);
  });

  testWidgets('baris Plus: Gratis membuka paywall, aktif membuka daftar fitur', (tester) async {
    await pump(tester, const FreePlan());
    await tester.tap(find.byKey(const ValueKey('account-plus-row')));
    await tester.pumpAndSettle();
    expect(find.text(t.premium.paywall.messages.general.title), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    ActivePlan.notifier.value = const PlusPlan(source: PlanSource.purchase);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('account-plus-row')));
    await tester.pumpAndSettle();
    expect(find.text(t.premium.features.title), findsOneWidget);
    expect(find.text(t.premium.features.records.title), findsOneWidget);
    await tester.scrollUntilVisible(find.text(t.premium.features.freeTitle), 200);
    expect(find.text(t.premium.features.freeTitle), findsOneWidget);
  });

  testWidgets('360dp teks 200%: tanpa overflow', (tester) async {
    await pump(tester, PlusPlan(source: PlanSource.purchase, until: DateTime(2027, 10, 22), inGrace: true), scale: 2);
    expect(tester.takeException(), isNull);
  });
}
