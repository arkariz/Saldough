import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? DsTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('DsButton', () {
    testWidgets('memanggil onPressed dan berwarna actionPrimary', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(DsButton(label: 'Simpan', onPressed: () => taps++)));
      await tester.tap(find.text('Simpan'));
      expect(taps, 1);
      final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect((box.decoration! as BoxDecoration).color, matcha.light.actionPrimary);
    });

    testWidgets('nonaktif: pudar dan tidak bereaksi', (tester) async {
      await tester.pumpWidget(_host(const DsButton.secondary(label: 'Batal', onPressed: null)));
      final opacity = tester.widget<Opacity>(find.ancestor(of: find.text('Batal'), matching: find.byType(Opacity)));
      expect(opacity.opacity, DsOpacity.disabled);
      expect(tester.getSemantics(find.text('Batal')), matchesSemantics(isButton: true, hasEnabledState: true, label: 'Batal'));
    });

    testWidgets('area sentuh minimal 44 walau tombol ringkas', (tester) async {
      await tester.pumpWidget(_host(DsButton.compact(label: 'KLAIM', onPressed: () {})));
      expect(tester.getSize(find.byType(DsPressable)).height, greaterThanOrEqualTo(44));
    });

    testWidgets('mengecil saat ditekan', (tester) async {
      await tester.pumpWidget(_host(DsButton(label: 'Tekan', onPressed: () {})));
      final gesture = await tester.startGesture(tester.getCenter(find.text('Tekan')));
      await tester.pump(DsMotion.standard);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, DsMotion.pressScale);
      await gesture.up();
    });
  });

  testWidgets('DsIconButton punya label dan tooltip', (tester) async {
    await tester.pumpWidget(_host(DsIconButton(icon: Icons.notifications, label: 'Notifikasi', onPressed: () {})));
    expect(find.byTooltip('Notifikasi'), findsOneWidget);
    expect(find.bySemanticsLabel('Notifikasi'), findsWidgets);
  });

  group('DsSegmentMeter', () {
    test('segmen terisi dibulatkan ke bawah dan dipotong', () {
      expect(DsSegmentMeter.filledFor(0.74, 10), 7);
      expect(DsSegmentMeter.filledFor(1.4, 10), 10);
      expect(DsSegmentMeter.filledFor(-1, 10), 0);
    });

    testWidgets('warna isi mengikuti nada', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 200,
            child: DsSegmentMeter(value: 0.5, semanticLabel: '50%', tone: DsMeterTone.danger),
          ),
        ),
      );
      final colors = tester
          .widgetList<DecoratedBox>(find.descendant(of: find.byType(DsSegmentMeter), matching: find.byType(DecoratedBox)))
          .map((b) => (b.decoration as BoxDecoration).color)
          .toList();
      expect(colors, hasLength(10));
      expect(colors.where((c) => c == matcha.light.error), hasLength(5));
      expect(find.bySemanticsLabel('50%'), findsOneWidget);
    });
  });

  testWidgets('DsBadge memakai sudut 6 dan huruf piksel', (tester) async {
    await tester.pumpWidget(_host(const DsBadge(label: 'Transport')));
    final box = tester.widget<Container>(find.ancestor(of: find.text('Transport'), matching: find.byType(Container)));
    expect((box.decoration! as BoxDecoration).borderRadius, DsRadius.badgeAll);
    expect(tester.widget<Text>(find.text('Transport')).style!.fontFamily, DsFonts.pixel);
  });

  group('DsLedgerRow', () {
    for (final (kind, expected) in [
      (DsLedgerKind.expense, matcha.light.textPrimary),
      (DsLedgerKind.income, matcha.light.income),
      (DsLedgerKind.transfer, matcha.light.textSecondary),
    ]) {
      testWidgets('nominal $kind berwarna sesuai jenis', (tester) async {
        await tester.pumpWidget(
          _host(
            SizedBox(
              width: 360,
              child: DsLedgerRow(
                leading: const DsIconTile(icon: Icons.coffee),
                title: 'Kopi',
                amount: 'Rp 28.000',
                subtitle: 'Kafe · 14:20',
                kind: kind,
              ),
            ),
          ),
        );
        expect(tester.widget<Text>(find.text('Rp 28.000')).style!.color, expected);
        expect(tester.widget<Text>(find.text('Kafe · 14:20')).style!.color, matcha.light.textMuted);
      });
    }

    testWidgets('judul panjang terpotong, nominal utuh', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 240,
            child: DsLedgerRow(
              leading: const DsIconTile(icon: Icons.coffee),
              title: 'Judul transaksi yang sangat panjang sekali sampai tidak muat',
              amount: 'Rp 1.500.000',
              onTap: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Rp 1.500.000'), findsOneWidget);
    });
  });

  testWidgets('DsHeroBalanceCard menyamarkan saldo dan memanggil tombol mata', (tester) async {
    var toggled = false;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 360,
          child: DsHeroBalanceCard(
            label: 'TOTAL SALDO',
            currencySymbol: 'Rp',
            amount: '14.850.000',
            hidden: true,
            toggleLabel: 'Tampilkan saldo',
            onToggleHidden: () => toggled = true,
            stats: const [
              DsHeroStatTile(icon: Icons.arrow_circle_up, label: 'MASUK', value: '+Rp 8.500.000'),
              DsHeroStatTile(icon: Icons.arrow_circle_down, label: 'KELUAR', value: '-Rp 3.650.000', income: false),
            ],
            actions: [
              DsButton.onHero(label: 'Catat', onPressed: () {}),
              DsButton.onHeroTonal(label: 'Transfer', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    expect(find.text('14.850.000'), findsNothing);
    expect(find.text('••••••••'), findsOneWidget);
    await tester.tap(find.byTooltip('Tampilkan saldo'));
    expect(toggled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DsNavBar memilih tab dan tombol tengah di posisi tengah', (tester) async {
    int? selected;
    var center = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: DsTheme.light,
        home: Scaffold(
          bottomNavigationBar: DsNavBar(
            items: const [
              DsNavItem(icon: Icons.home, label: 'Beranda'),
              DsNavItem(icon: Icons.history, label: 'Riwayat'),
              DsNavItem(icon: Icons.event_note, label: 'Rencana'),
              DsNavItem(icon: Icons.wallet, label: 'Dompet'),
            ],
            currentIndex: 0,
            onSelected: (i) => selected = i,
            centerLabel: 'Catat',
            onCenterPressed: () => center++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Rencana'));
    expect(selected, 2);
    await tester.tap(find.text('Catat'));
    expect(center, 1);
    final riwayat = tester.getCenter(find.text('Riwayat')).dx;
    final catat = tester.getCenter(find.text('Catat')).dx;
    final rencana = tester.getCenter(find.text('Rencana')).dx;
    expect(catat, inExclusiveRange(riwayat, rencana));
  });

  testWidgets('komponen gabungan tampil di mode gelap tanpa galat', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: DsTheme.dark,
        home: Scaffold(
          appBar: const DsTopBar(wordmark: 'tanukonomy', actions: [DsAvatar(semanticLabel: 'Akun')]),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const DsPageHeader(title: 'Halo, Kenji!', subtitle: 'Ringkasan hari ini', trailing: DsStatusPill(label: 'LVL 12', pulse: false)),
              const SizedBox(height: 14),
              const DsMascotCard(
                mascot: Icon(Icons.pets),
                title: 'Mood: Santai',
                meterValue: 0.84,
                meterLabel: '84% sehat',
                badge: DsBadge(label: '84% SEHAT', tone: DsBadgeTone.income),
                note: 'Aman sampai akhir pekan',
              ),
              const SizedBox(height: 14),
              const DsBudgetMeterCard(
                title: 'Batas hari ini',
                spent: 'Rp 185.000',
                total: 'Rp 250.000',
                remaining: 'Sisa Rp 65.000',
                value: 0.74,
                meterLabel: '74% terpakai',
                footer: ['00:00', '24:00'],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DsQuickActionTile(tile: const DsIconTile(icon: Icons.insights), label: 'Laporan', onPressed: () {}),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DsInlineBanner(
                icon: Icons.explore,
                eyebrow: 'MISI',
                message: 'Pesan satu baris',
                action: DsButton.compact(label: 'KLAIM', onPressed: () {}),
              ),
              const SizedBox(height: 14),
              DsSectionHeader(title: 'Transaksi terbaru', actionLabel: 'Semua', onAction: () {}),
              const DsListCard(
                children: [
                  DsLedgerRow(leading: DsIconTile(icon: Icons.coffee), title: 'Kopi', amount: 'Rp 28.000'),
                  DsLedgerRow(leading: DsIconTile(icon: Icons.work), title: 'Gaji', amount: 'Rp 9.000.000', kind: DsLedgerKind.income),
                ],
              ),
              const DsFootnote(text: 'DISIMPAN DI PERANGKAT'),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Halo, Kenji!'), findsOneWidget);
  });
}
