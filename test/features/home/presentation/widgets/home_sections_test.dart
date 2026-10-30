import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/presentation/home_placeholder.dart';
import 'package:saldough/features/home/presentation/widgets/home_sections.dart';
import 'package:saldough/features/home/presentation/widgets/home_summary.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/reduced_motion.dart';

Widget _host(Widget child, {bool reduced = true, Brightness brightness = Brightness.light, String preset = 'matcha'}) =>
    MaterialApp(
      theme: AppThemeBridge.build(DsThemePresets.byId(preset), brightness),
      builder: reduced ? reducedMotion : null,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  test('saklar data tiruan menyala sesuai keputusan pemilik', () {
    expect(kHomePlaceholderPreview, isTrue);
  });

  group('HomeQuickActions', () {
    testWidgets('Scan Struk nonaktif berlabel Segera; tile lain bisa diketuk', (tester) async {
      var transfer = 0;
      var report = 0;
      await tester.pumpWidget(
        _host(HomeQuickActions(onRecordTransfer: () => transfer++, onOpenReport: () => report++)),
      );
      expect(find.text(t.home.actionScan), findsOneWidget);
      expect(find.text(t.home.soon), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home-action-scan')), warnIfMissed: false);
      expect(transfer + report, 0);
      await tester.tap(find.text(t.home.actionTransfer));
      await tester.tap(find.text(t.home.actionReport));
      expect((transfer, report), (1, 1));
      expect(find.text(t.home.actionMission), findsOneWidget);
    });

    testWidgets('tidak ada kata kirim: aplikasi mencatat, bukan melakukan', (tester) async {
      await tester.pumpWidget(_host(HomeQuickActions(onRecordTransfer: () {}, onOpenReport: () {})));
      expect(find.textContaining('Kirim'), findsNothing);
      expect(t.home.actionTransfer, 'Catat Transfer');
    });
  });

  testWidgets('Misi Hemat: lencana +50 XP, klaim memicu perayaan dan onClaimed, lalu pulih', (tester) async {
    var claims = 0;
    await tester.pumpWidget(
      _host(
        HomeQuickActions(onRecordTransfer: () {}, onOpenReport: () {}, onClaimed: () => claims++),
        reduced: false,
      ),
    );
    expect(find.text(t.home.preview.missionReward), findsOneWidget);
    await tester.tap(find.text(t.home.actionMission));
    await tester.pump(const Duration(milliseconds: 300));
    expect(claims, 1);
    expect(find.text(t.home.preview.missionClaimed), findsOneWidget);
    // Perayaan menampilkan hadiahnya; ketukan kedua saat terklaim diabaikan.
    expect(find.text(t.home.preview.missionReward), findsOneWidget);
    await tester.tap(find.text(t.home.actionMission), warnIfMissed: false);
    expect(claims, 1);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text(t.home.preview.missionClaimed), findsNothing);
    expect(find.text(t.home.preview.missionReward), findsOneWidget);
  });

  testWidgets('HomeGreeting: pil level di kanan dan pil mood di bawah sapaan', (tester) async {
    await tester.pumpWidget(_host(const HomeGreeting(name: 'Sari')));
    expect(find.text(t.home.greetingNamed(name: 'Sari')), findsOneWidget);
    expect(find.text(t.home.preview.level), findsOneWidget);
    expect(find.byType(HomeMoodPill), findsOneWidget);
    expect(find.textContaining(t.home.preview.moodTitle, findRichText: true), findsOneWidget);
  });

  group('HomeCarouselSection', () {
    const budget = BudgetOverview(activeCount: 1, plannedAmount: 15000000, spent: 3000000);

    testWidgets('satu carousel: anggaran nyata + dua slide tiruan, dapat digeser dengan titik', (tester) async {
      await tester.pumpWidget(_host(HomeCarouselSection(board: null, budget: budget, onOpenBudget: () {})));
      await tester.pump();
      expect(find.byType(DsCarousel), findsOneWidget);
      expect(find.byType(HomeBudgetCard).hitTestable(), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(t.home.statusCarouselDot(number: 2)));
      await tester.pumpAndSettle();
      expect(find.text(t.home.preview.billTitle).hitTestable(), findsOneWidget);
    });

    testWidgets('slide status tampil lebih dulu, tinggi mengikuti slide aktif', (tester) async {
      final board = DsStatusBoard();
      addTearDown(board.dispose);
      board.report(
        'a',
        const DsStatusSlideData(
          id: 'a',
          icon: Icons.event_note,
          title: 'Judul a',
          subtitle: 'Keterangan a',
          attention: true,
        ),
      );
      await tester.pumpWidget(_host(HomeCarouselSection(board: board, budget: budget, onOpenBudget: () {})));
      await tester.pumpAndSettle();
      expect(find.text('Judul a').hitTestable(), findsOneWidget);
      final statusHeight = tester.getSize(find.byType(PageView)).height;
      await tester.tap(find.bySemanticsLabel(t.home.statusCarouselDot(number: 2)));
      await tester.pumpAndSettle();
      expect(find.byType(HomeBudgetCard).hitTestable(), findsOneWidget);
      expect(tester.getSize(find.byType(PageView)).height, greaterThan(statusHeight));
    });

    testWidgets('tanpa anggaran tetap ada slide tiruan', (tester) async {
      await tester.pumpWidget(_host(HomeCarouselSection(board: null, budget: null, onOpenBudget: () {})));
      await tester.pump();
      expect(find.byType(DsCarousel), findsOneWidget);
      expect(find.byType(HomeBudgetCard), findsNothing);
    });

    testWidgets('tidak luap di 360px dengan teks 2x', (tester) async {
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await tester.pumpWidget(_host(HomeCarouselSection(board: null, budget: budget, onOpenBudget: () {})));
      await tester.pumpAndSettle();
      for (var i = 2; i <= 3; i++) {
        await tester.tap(find.bySemanticsLabel(t.home.statusCarouselDot(number: i)));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('anggaran hampir habis: meter bernapas; aman: tidak', (tester) async {
      Future<bool> breathing(BudgetOverview o) async {
        await tester.pumpWidget(_host(HomeBudgetCard(overview: o, onOpen: () {}), reduced: false));
        await tester.pump(const Duration(milliseconds: 100));
        final meter = tester.widget<DsSegmentMeter>(find.byType(DsSegmentMeter));
        await tester.pumpWidget(const SizedBox());
        return meter.breathing;
      }

      expect(await breathing(budget), isFalse);
      expect(await breathing(const BudgetOverview(activeCount: 1, plannedAmount: 10000000, spent: 9000000)), isTrue);
    });
  });

  group('HomeRecentRow', () {
    const wallets = {
      'bca': Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
      'gopay': Wallet(id: 'gopay', name: 'GoPay', iconKey: 'walletEwallet', initialBalance: 0, currentBalance: 0),
    };
    final date = DateTime(2026, 10, 30, 14, 20);

    testWidgets('tanda dan warna nominal mengikuti aturan lama', (tester) async {
      await tester.pumpWidget(
        _host(
          DsListCard(
            children: [
              HomeRecentRow(
                transaction: IncomeTransaction(
                  id: 'a',
                  date: date,
                  amount: 150000000,
                  note: 'Freelance',
                  walletId: 'bca',
                ),
                walletsById: wallets,
              ),
              HomeRecentRow(
                transaction: ExpenseTransaction(id: 'b', date: date, amount: 2800000, note: 'Kopi', walletId: 'bca'),
                walletsById: wallets,
              ),
              HomeRecentRow(
                transaction: TransferTransaction(
                  id: 'c',
                  date: date,
                  amount: 10000000,
                  note: 'Top-up',
                  fromWalletId: 'bca',
                  toWalletId: 'gopay',
                ),
                walletsById: wallets,
              ),
            ],
          ),
        ),
      );
      final colors = DsThemePresets.fallback.light;
      Color colorOf(String text) => tester.widget<Text>(find.text(text)).style!.color!;
      expect(colorOf('+Rp1.500.000'), colors.income);
      expect(colorOf('−Rp28.000'), colors.textPrimary);
      expect(colorOf('Rp100.000'), colors.textSecondary);
      expect(find.text('BCA → GoPay · 14.20'), findsOneWidget);
      expect(find.text('BCA · 14.20'), findsNWidgets(2));
    });

    testWidgets('kategori kopi memakai ikon clay; tanpa kategori memakai ikon lama', (tester) async {
      await tester.pumpWidget(
        _host(
          HomeRecentRow(
            transaction: ExpenseTransaction(id: 'b', date: date, amount: 2800000, note: 'Kopi', walletId: 'bca'),
            walletsById: wallets,
          ),
        ),
      );
      await tester.pump();
      // Tanpa kategori terpasang, ikon jatuh ke ikon jenis lama (bukan clay).
      expect(find.byType(AppIconTile), findsOneWidget);
    });
  });

  for (final (preset, brightness) in [
    ('matcha', Brightness.dark),
    ('pink', Brightness.light),
    ('pink', Brightness.dark),
  ]) {
    testWidgets('kartu saldo hero tampil tanpa galat di $preset ${brightness.name}', (tester) async {
      await tester.pumpWidget(
        _host(
          const HomeBalanceCard(
            total: 1485000000,
            walletCount: 2,
            cashFlow: CashFlow(income: 850000000, expense: 365000000),
            footer: Text('FOOTER'),
          ),
          preset: preset,
          brightness: brightness,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('14.850.000'), findsOneWidget);
      expect(find.text('+Rp8.500.000'), findsOneWidget);
      expect(find.text('FOOTER'), findsOneWidget);
      // Kartu saldo tanpa tombol: Catat dan Dompet ada di navigasi.
      expect(find.descendant(of: find.byType(DsHeroBalanceCard), matching: find.byType(DsButton)), findsNothing);
    });
  }
}
