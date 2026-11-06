import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/presentation/home_placeholder.dart';
import 'package:saldough/features/home/presentation/widgets/home_cards.dart';
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
    testWidgets('tanpa tile notifikasi (platform tanpa dukungan): tidak ada slot kosong, Scan Struk, atau tile Catat', (
      tester,
    ) async {
      var report = 0;
      await tester.pumpWidget(_host(HomeQuickActions(onOpenReport: () => report++, onOpenFreelance: () {})));
      expect(find.byKey(const ValueKey('home-action-scan')), findsNothing);
      expect(find.byKey(const ValueKey('home-action-notification')), findsNothing);
      // Tombol Catat di tengah bilah bawah satu-satunya pintu CATAT: tanpa tile Catat Transfer.
      expect(find.byKey(const ValueKey('home-action-transfer')), findsNothing);
      await tester.tap(find.text(t.home.actionReport));
      expect(report, 1);
      expect(find.text(t.home.actionMission), findsOneWidget);
    });

    testWidgets('tile notifikasi disisipkan di baris dan bisa diketuk', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        _host(
          HomeQuickActions(
            onOpenReport: () {},
            onOpenFreelance: () {},
            notificationAction: DsQuickActionTile(
              key: const ValueKey('home-action-notification'),
              tile: DsIconTile.asset(asset: ClayIcons.bell),
              label: t.home.actionNotification,
              onPressed: () => opened++,
            ),
          ),
        ),
      );
      await tester.tap(find.text(t.home.actionNotification));
      expect(opened, 1);
    });

    testWidgets('tile Freelance membuka Ikhtisar Freelance lewat callback-nya', (tester) async {
      var opened = 0;
      await tester.pumpWidget(_host(HomeQuickActions(onOpenReport: () {}, onOpenFreelance: () => opened++)));
      expect(find.byKey(const ValueKey('home-action-freelance')), findsOneWidget);
      await tester.tap(find.text(t.home.actionFreelance));
      expect(opened, 1);
    });

    testWidgets('empat tile (notifikasi, laporan, freelance, misi) muat sebaris di 360dp teks 2x', (tester) async {
      tester.view
        ..physicalSize = const Size(360, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: HomeQuickActions(
              onOpenReport: () {},
              onOpenFreelance: () {},
              notificationAction: DsQuickActionTile(
                tile: DsIconTile.asset(asset: ClayIcons.bell),
                label: t.home.actionNotification,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tidak ada kata kirim: aplikasi mencatat, bukan melakukan', (tester) async {
      await tester.pumpWidget(_host(HomeQuickActions(onOpenReport: () {}, onOpenFreelance: () {})));
      expect(find.textContaining('Kirim'), findsNothing);
    });
  });

  testWidgets('Misi Hemat: lencana +50 XP, klaim memicu perayaan dan onClaimed, lalu pulih', (tester) async {
    var claims = 0;
    await tester.pumpWidget(
      _host(
        HomeQuickActions(onOpenReport: () {}, onOpenFreelance: () {}, onClaimed: () => claims++),
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

    testWidgets('hanya anggaran nyata: satu kartu tanpa carousel', (tester) async {
      await tester.pumpWidget(_host(HomeCarouselSection(board: null, budget: budget, onOpenBudget: () {})));
      await tester.pump();
      expect(find.byType(DsCarousel), findsNothing);
      expect(find.byType(HomeBudgetCard).hitTestable(), findsOneWidget);
    });

    testWidgets('slide status tampil lebih dulu, semua slide selebar dan setinggi sama', (tester) async {
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
      expect(tester.getSize(find.byType(PageView)).height, statusHeight, reason: 'tinggi sama untuk semua slide');
      final page = tester.getSize(find.byType(HomeBudgetCard).hitTestable());
      // PageView 16px lebih lebar dari konten (jarak antarkartu).
      expect(page.width, tester.getSize(find.byType(PageView)).width - 16, reason: 'selebar konten');
    });

    testWidgets('tanpa anggaran dan tanpa slide status: tidak ada apa-apa (tanpa slide tiruan)', (tester) async {
      await tester.pumpWidget(_host(HomeCarouselSection(board: null, budget: null, onOpenBudget: () {})));
      await tester.pump();
      expect(find.byType(DsCarousel), findsNothing);
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
      await tester.tap(find.bySemanticsLabel(t.home.statusCarouselDot(number: 2)));
      await tester.pumpAndSettle();
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

  group('HomeFirstSteps (keadaan awal)', () {
    Widget steps({
      bool noWallets = true,
      bool budget = false,
      VoidCallback? onWallet,
      VoidCallback? onRecord,
      VoidCallback? onBudget,
    }) => _host(
      HomeFirstSteps(
        hasNoWallets: noWallets,
        hasBudget: budget,
        onAddWallet: onWallet ?? () {},
        onRecord: onRecord ?? () {},
        onBudget: onBudget ?? () {},
      ),
    );

    testWidgets('tanpa dompet: hanya langkah dompet bertombol; lainnya terkunci dan tak bisa diketuk', (tester) async {
      var wallet = 0;
      var record = 0;
      var budget = 0;
      await tester.pumpWidget(steps(onWallet: () => wallet++, onRecord: () => record++, onBudget: () => budget++));
      expect(find.text(t.home.createWalletAction), findsOneWidget);
      expect(find.text(t.home.recordAction), findsNothing);
      expect(find.text(t.home.stepsProgress(done: 0, total: 3).toUpperCase()), findsOneWidget);
      await tester.tap(find.text(t.home.stepRecordTitle));
      await tester.tap(find.text(t.home.stepBudgetTitle));
      expect((record, budget), (0, 0));
      await tester.tap(find.text(t.home.stepWalletTitle));
      expect(wallet, 1);
    });

    testWidgets('ada dompet: langkah dompet selesai, Catat transaksi jadi tombol, anggaran opsional bisa diketuk', (
      tester,
    ) async {
      var record = 0;
      var budget = 0;
      await tester.pumpWidget(steps(noWallets: false, onRecord: () => record++, onBudget: () => budget++));
      expect(find.text(t.home.createWalletAction), findsNothing);
      expect(find.text(t.home.recordAction), findsOneWidget);
      expect(find.text(t.home.stepDone.toUpperCase()), findsOneWidget);
      expect(find.text(t.home.stepOptional.toUpperCase()), findsOneWidget);
      expect(find.text(t.home.stepsProgress(done: 1, total: 3).toUpperCase()), findsOneWidget);
      await tester.tap(find.text(t.home.stepRecordTitle));
      await tester.tap(find.text(t.home.stepBudgetTitle));
      expect((record, budget), (1, 1));
    });

    testWidgets('anggaran sudah ada: dua dari tiga selesai', (tester) async {
      await tester.pumpWidget(steps(noWallets: false, budget: true));
      expect(find.text(t.home.stepsProgress(done: 2, total: 3).toUpperCase()), findsOneWidget);
    });

    testWidgets('hadiah XP tampil (tiruan) dan maskot tidur terpasang', (tester) async {
      await tester.pumpWidget(steps());
      expect(find.text(t.home.questRewardXp), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('tidak luap di 360px dengan teks 2x, juga dengan animasi menyala', (tester) async {
      tester.view
        ..physicalSize = const Size(360, 1600)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await tester.pumpWidget(
        _host(
          HomeFirstSteps(
            hasNoWallets: false,
            onAddWallet: () {},
            onRecord: () {},
            onBudget: () {},
          ),
          reduced: false,
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeGreeting pemula: subjudul mengajak mulai, tanpa pil mood', (tester) async {
      await tester.pumpWidget(_host(const HomeGreeting(name: null, firstRun: true)));
      expect(find.text(t.home.firstSubtitle), findsOneWidget);
      expect(find.text(t.home.preview.levelNew), findsOneWidget);
      expect(find.byType(HomeMoodPill), findsNothing);
    });

    testWidgets('HomeEmptyLedger menampilkan judul dan isi kosong', (tester) async {
      await tester.pumpWidget(_host(const HomeEmptyLedger()));
      expect(find.text(t.home.emptyTitle), findsOneWidget);
      expect(find.text(t.home.emptyBody), findsOneWidget);
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

    testWidgets('semua kategori memakai ikon clay di tile datar', (tester) async {
      await tester.pumpWidget(
        _host(
          HomeRecentRow(
            transaction: ExpenseTransaction(id: 'b', date: date, amount: 2800000, note: 'Kopi', walletId: 'bca'),
            walletsById: wallets,
          ),
        ),
      );
      await tester.pump();
      // Semua ikon benda sudah clay: tile datar berisi SVG, bukan ikon piksel.
      expect(find.byType(AppIconTile), findsNothing);
      expect(find.byType(DsIconTile), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
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
