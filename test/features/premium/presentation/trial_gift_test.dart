import 'package:di/di.dart' show GetIt, ScopeProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/premium/domain/trial_gift.dart';
import 'package:saldough/features/premium/presentation/pages/trial_gift_page.dart';
import 'package:saldough/features/premium/presentation/widgets/trial_gift_host.dart';

import '../../../helpers/routes.dart';

final class _FakeGift implements TrialGift {
  _FakeGift(this.info);

  TrialGiftInfo? info;
  DateTime? payday;
  bool fail = false;
  int seen = 0;
  FinancialMonthStart? saved;

  @override
  Future<TrialGiftInfo?> pending() async => seen > 0 ? null : info;

  @override
  Future<DateTime?> setPayday(FinancialMonthStart start) async {
    saved = start;
    return fail ? null : payday;
  }

  @override
  Future<void> markSeen() async => seen++;
}

/// Layar hadiah uji coba dan pemicunya (T-24.17d).
void main() {
  final info = TrialGiftInfo(start: DateTime(2026, 11), endsOn: DateTime(2026, 11, 30), needsPayday: true, minDays: 14);
  final texts = t.premium.gift;

  setUp(() {
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
    addTearDown(() {
      ActivePlan.reset();
      ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
    });
  });

  Future<void> pumpPage(WidgetTester tester, _FakeGift gift, TrialGiftInfo i, {double scale = 1}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: TrialGiftPage(info: i, gift: gift),
      ),
    );
    await tester.pump();
  }

  group('TrialGiftPage', () {
    testWidgets('tanpa pertanyaan: langsung hadiah dengan tanggal akhir dan ditandai tampil', (tester) async {
      final gift = _FakeGift(info);
      await pumpPage(tester, gift, TrialGiftInfo(start: info.start, endsOn: DateTime(2026, 11, 24), needsPayday: false, minDays: 14));
      expect(find.text(texts.title(date: '24 Nov')), findsOneWidget);
      expect(find.text(texts.start), findsOneWidget);
      expect(gift.seen, 1);
    });

    testWidgets('bertanya gajian: pratinjau tanggal berubah mengikuti pilihan; konfirmasi menyimpan', (tester) async {
      final gift = _FakeGift(info)..payday = DateTime(2026, 11, 24);
      await pumpPage(tester, gift, info);
      expect(gift.seen, 0, reason: 'belum ditandai selama bertanya');
      expect(find.text(texts.askTitle), findsOneWidget);
      expect(find.text(texts.confirmDay(day: 25)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('day-10')));
      await tester.pump();
      expect(find.text(texts.confirmDay(day: 10)), findsOneWidget);
      await tester.tap(find.text(texts.confirmDay(day: 10)));
      await tester.pumpAndSettle();
      expect(gift.saved, const FinancialMonthStart.day(10));
      expect(find.text(texts.title(date: '24 Nov')), findsOneWidget);
      expect(gift.seen, 1);
    });

    testWidgets('hari terakhir bulan: tombol dan simpan', (tester) async {
      final gift = _FakeGift(info)..payday = DateTime(2026, 11, 29);
      await pumpPage(tester, gift, info);
      await tester.tap(find.byKey(const ValueKey('day-last')));
      await tester.pump();
      await tester.tap(find.text(texts.confirmLast));
      await tester.pumpAndSettle();
      expect(gift.saved, FinancialMonthStart.lastDay);
    });

    testWidgets('gagal menyimpan: tetap di pertanyaan dengan pesan galat', (tester) async {
      final gift = _FakeGift(info)..fail = true;
      await pumpPage(tester, gift, info);
      await tester.tap(find.text(texts.confirmDay(day: 25)));
      await tester.pumpAndSettle();
      expect(find.text(t.common.genericErrorMessage), findsOneWidget);
      expect(find.text(texts.askTitle), findsOneWidget);
      expect(gift.seen, 0);
    });

    testWidgets('360dp teks 200%: tanpa overflow di kedua langkah', (tester) async {
      await pumpPage(tester, _FakeGift(info), info, scale: 2);
      expect(tester.takeException(), isNull);
      await pumpPage(
        tester,
        _FakeGift(info),
        TrialGiftInfo(start: info.start, endsOn: info.endsOn, needsPayday: false, minDays: 14),
        scale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('TrialGiftHost', () {
    Future<void> pumpHost(WidgetTester tester, _FakeGift gift, {bool active = true}) async {
      final container = GetIt.asNewInstance()
        ..registerSingleton<RouteRegistry>(appRouteRegistry())
        ..registerSingleton<TrialGift>(gift);
      await tester.pumpWidget(
        ScopeProvider(
          container: container,
          child: MaterialApp(
            theme: PixelTheme.light,
            home: Scaffold(body: TrialGiftHost(container: container, active: active)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('uji coba aktif dan hadiah menunggu: layar hadiah terbuka sekali', (tester) async {
      ActivePlan.notifier.value = TrialPlan(endsOn: DateTime(2026, 11, 30));
      final gift = _FakeGift(info);
      await pumpHost(tester, gift);
      expect(find.text(texts.askTitle), findsOneWidget);
    });

    testWidgets('bukan uji coba, atau bukan tab Beranda: tidak membuka apa pun', (tester) async {
      final gift = _FakeGift(info);
      await pumpHost(tester, gift);
      expect(find.text(texts.askTitle), findsNothing);
      ActivePlan.notifier.value = TrialPlan(endsOn: DateTime(2026, 11, 30));
      await tester.pumpAndSettle();
      expect(find.text(texts.askTitle), findsOneWidget, reason: 'paket berubah menjadi uji coba membukanya');
    });

    testWidgets('tidak aktif: menunggu', (tester) async {
      ActivePlan.notifier.value = TrialPlan(endsOn: DateTime(2026, 11, 30));
      await pumpHost(tester, _FakeGift(info), active: false);
      expect(find.text(texts.askTitle), findsNothing);
    });

    testWidgets('hadiah sudah pernah tampil: tidak membuka', (tester) async {
      ActivePlan.notifier.value = TrialPlan(endsOn: DateTime(2026, 11, 30));
      await pumpHost(tester, _FakeGift(null));
      expect(find.text(texts.askTitle), findsNothing);
    });
  });
}
