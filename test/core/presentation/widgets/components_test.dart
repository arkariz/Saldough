import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Komponen dasar design system (T-14.3, ADR-034): varian, keadaan nonaktif,
/// dan semantik.
void main() {
  const c = AppColors.light;

  Future<void> pump(WidgetTester tester, Widget child, {double width = 360}) {
    tester.view
      ..physicalSize = Size(width, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  ShapeDecoration shapeOf(WidgetTester tester, Finder within) => tester
      .widgetList<Container>(
        find.descendant(of: within, matching: find.byType(Container)),
      )
      .map((w) => w.decoration)
      .whereType<ShapeDecoration>()
      .first;

  group('AppButton', () {
    testWidgets(
      'primary brand, secondary surface2, text tanpa isian, danger teks danger',
      (tester) async {
        await pump(
          tester,
          Column(
            children: [
              AppButton(label: 'Simpan', onPressed: () {}),
              AppButton.secondary(label: 'Tambah', onPressed: () {}),
              AppButton.text(label: 'Batal', onPressed: () {}),
              AppButton.danger(label: 'Hapus dompet', onPressed: () {}),
            ],
          ),
        );
        Color? fillOf(String label) =>
            (tester
                        .widget<AnimatedContainer>(
                          find
                              .ancestor(
                                of: find.text(label),
                                matching: find.byType(AnimatedContainer),
                              )
                              .first,
                        )
                        .decoration!
                    as ShapeDecoration)
                .color;
        expect(fillOf('Simpan'), c.brand);
        expect(fillOf('Tambah'), c.surface2);
        expect(fillOf('Batal'), Colors.transparent);
        expect(
          tester.widget<Text>(find.text('Hapus dompet')).style!.color,
          c.danger,
        );
        expect(
          tester.widget<Text>(find.text('Simpan')).style!.color,
          c.onBrand,
        );
      },
    );

    testWidgets('nonaktif: opacity-disabled dan tidak memanggil handler', (
      tester,
    ) async {
      await pump(tester, const AppButton(label: 'Simpan', onPressed: null));
      expect(
        tester.widget<Opacity>(find.byType(Opacity).first).opacity,
        AppSize.disabledOpacity,
      );
      expect(
        tester.getSemantics(find.byType(AppButton)),
        isSemantics(isButton: true, isEnabled: false),
      );
    });

    testWidgets('memuat: pemutar menggantikan teks dan ketukan diabaikan', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        AppButton(label: 'Simpan', loading: true, onPressed: () => taps++),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Simpan'), findsNothing);
      await tester.tap(find.byType(AppButton));
      expect(taps, 0);
    });

    testWidgets(
      'kecil 36px tetap punya area sentuh 48px; expand selebar induk',
      (tester) async {
        await pump(
          tester,
          Column(
            children: [
              AppButton(label: 'Cek', small: true, onPressed: () {}),
              AppButton(label: 'Simpan', expand: true, onPressed: () {}),
            ],
          ),
        );
        expect(
          tester.getSize(find.byType(AppButton).first).height,
          greaterThanOrEqualTo(48),
        );
        expect(tester.getSize(find.byType(AnimatedContainer).first).height, 36);
        expect(tester.getSize(find.byType(AnimatedContainer).last).width, 328);
      },
    );
  });

  group('AppChip', () {
    testWidgets(
      'terpilih: brandSoft dengan ikon centang; jumlah setelah label',
      (tester) async {
        await pump(
          tester,
          AppChip(
            label: 'Pengeluaran',
            count: 24,
            selected: true,
            onTap: () {},
          ),
        );
        expect(shapeOf(tester, find.byType(AppChip)).color, c.brandSoft);
        expect(
          find.byWidgetPredicate(
            (w) => w is AppIcon && w.iconKey == IconKey.check,
          ),
          findsOneWidget,
        );
        expect(find.text('24'), findsOneWidget);
        expect(
          tester.getSemantics(find.byType(AppChip)),
          isSemantics(isSelected: true),
        );
      },
    );

    testWidgets('tidak terpilih surface2, di atas bg surface; area sentuh 48', (
      tester,
    ) async {
      await pump(
        tester,
        AppChip(label: 'Makan', icon: IconKey.categoryFood, onTap: () {}),
      );
      expect(shapeOf(tester, find.byType(AppChip)).color, c.surface2);
      expect(tester.getSize(find.byType(AppChip)).height, 48);
      await pump(tester, AppChip(label: 'Makan', onBg: true, onTap: () {}));
      expect(shapeOf(tester, find.byType(AppChip)).color, c.surface);
    });
  });

  group('AppSegmentedControl', () {
    testWidgets(
      'memanggil onChanged; tiga segmen "Pengeluaran" muat di 360dp',
      (tester) async {
        String? picked;
        await pump(
          tester,
          AppSegmentedControl<String>(
            options: const [
              ('e', 'Pengeluaran'),
              ('i', 'Pemasukan'),
              ('t', 'Transfer'),
            ],
            selected: 'e',
            counts: const {'e': 3},
            onChanged: (v) => picked = v,
          ),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Transfer'));
        expect(picked, 't');
        expect(
          tester.getSemantics(find.text('Pengeluaran 3')),
          isSemantics(isChecked: true, isInMutuallyExclusiveGroup: true),
        );
      },
    );
  });

  group('AppProgressBar', () {
    test('status: aman < 85%, hampir habis 85–100%, lewat > 100%', () {
      expect(AppProgressBar.statusFor(0.5), AppBarStatus.safe);
      expect(AppProgressBar.statusFor(0.85), AppBarStatus.nearlyOut);
      expect(AppProgressBar.statusFor(1), AppBarStatus.nearlyOut);
      expect(AppProgressBar.statusFor(1.01), AppBarStatus.over);
    });

    testWidgets('tinggi 10px, tipis 6px; dibaca sebagai persen', (
      tester,
    ) async {
      await pump(
        tester,
        const Column(
          children: [
            AppProgressBar(value: 0.64, pace: 0.5),
            AppProgressBar(value: 0.2, thin: true),
          ],
        ),
      );
      expect(tester.getSize(find.byType(AppProgressBar).first).height, 10);
      expect(tester.getSize(find.byType(AppProgressBar).last).height, 6);
      expect(
        tester.getSemantics(find.byType(AppProgressBar).first).value,
        '64%',
      );
    });
  });

  group('AppMoneyText', () {
    testWidgets('tanda dan warna per jenis', (tester) async {
      await pump(
        tester,
        const Column(
          children: [
            AppMoneyText(4500000, kind: MoneyKind.expense),
            AppMoneyText(850000000, kind: MoneyKind.income),
            AppMoneyText(30000000, kind: MoneyKind.transfer),
            AppMoneyText(-3600000, kind: MoneyKind.remaining),
          ],
        ),
      );
      Color? colorOf(String text) => tester.widget<Text>(find.text(text)).style!.color;
      expect(colorOf('−Rp45.000'), c.ink);
      expect(colorOf('+Rp8.500.000'), c.positive);
      expect(colorOf('Rp300.000'), c.ink2);
      expect(colorOf('−Rp36.000'), c.danger);
      final style = tester.widget<Text>(find.text('−Rp45.000')).style!;
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('nol tanpa tanda: Rp0, bukan −Rp0 atau +Rp0 (QA F5)', () {
      expect(AppMoneyText.format(0, MoneyKind.expense), 'Rp0');
      expect(AppMoneyText.format(0, MoneyKind.income), 'Rp0');
      expect(AppMoneyText.format(100, MoneyKind.expense), '−Rp1');
    });
  });

  testWidgets('AppIconButton punya aksi ketuk untuk pembaca layar (QA F7)', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pump(tester, AppIconButton(icon: IconKey.add, label: 'Tambah', onPressed: () => taps++));
    final node = tester.getSemantics(find.bySemanticsLabel('Tambah'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel('Tambah'));
    expect(taps, 1);
    handle.dispose();
  });

  group('AppBadge dan AppBanner', () {
    testWidgets('badge nada warning: warningSoft + teks warning, huruf biasa', (
      tester,
    ) async {
      await pump(tester, const AppBadge('Perlu dicek', tone: AppTone.warning));
      expect(shapeOf(tester, find.byType(AppBadge)).color, c.warningSoft);
      expect(
        tester.widget<Text>(find.text('Perlu dicek')).style!.color,
        c.warning,
      );
    });

    testWidgets('banner: satu kalimat dan satu tindakan', (tester) async {
      var taps = 0;
      await pump(
        tester,
        AppBanner(
          message: '3 transaksi menunggu dicek.',
          actionLabel: 'Cek',
          onAction: () => taps++,
        ),
      );
      await tester.tap(find.text('Cek'));
      expect(taps, 1);
      expect(shapeOf(tester, find.byType(AppBanner)).color, c.warningSoft);
    });
  });

  group('AppCard, AppListCard, AppListRow, AppSectionHeader', () {
    testWidgets('kartu surface bersudut piksel; dapat diketuk', (tester) async {
      var taps = 0;
      await pump(
        tester,
        AppCard(
          onTap: () => taps++,
          semanticsLabel: 'Buka',
          child: const Text('isi'),
        ),
      );
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AppCard),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, c.surface);
      expect(material.shape, const PixelCornerBorder());
      await tester.tap(find.text('isi'));
      expect(taps, 1);
    });

    testWidgets(
      'baris: tinggi minimal 64, judul satu baris, pemisah menjorok',
      (tester) async {
        await pump(
          tester,
          const AppListCard(
            children: [
              AppListRow(
                title: 'Makan siang dengan judul yang sangat panjang sekali',
                subtitle: 'BCA · 12.00',
              ),
              AppListRow(title: 'Kopi', subtitle: 'Tunai · 08.00'),
            ],
          ),
        );
        expect(
          tester.getSize(find.byType(AppListRow).first).height,
          greaterThanOrEqualTo(64),
        );
        expect(
          tester.widget<Divider>(find.byType(Divider)).indent,
          AppListCard.tileIndent,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('judul bagian adalah header dengan tautan', (tester) async {
      var taps = 0;
      await pump(
        tester,
        AppSectionHeader(
          'Transaksi terbaru',
          actionLabel: 'Lihat semua',
          onAction: () => taps++,
        ),
      );
      await tester.tap(find.text('Lihat semua'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.text('Transaksi terbaru')),
        isSemantics(isHeader: true),
      );
    });
  });

  testWidgets('AppHeroCard: latar brand, teks onBrand, tanuki tajam', (
    tester,
  ) async {
    await pump(
      tester,
      const AppHeroCard(
        label: 'Total saldo',
        amount: HeroAmount('Rp27.522.000'),
        linkLabel: 'Di 4 dompet',
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.filterQuality, FilterQuality.none);
    expect(
      tester.widget<Text>(find.text('Total saldo')).style!.color,
      c.onBrand,
    );
  });

  group('AppNavBar', () {
    Widget bar({
      required ValueChanged<int> onSelected,
      required VoidCallback onRecord,
      VoidCallback? onLong,
      int selected = 0,
    }) => AppNavBar(
      destinations: const [
        (icon: IconKey.home, label: 'Beranda'),
        (icon: IconKey.transactions, label: 'Riwayat'),
        (icon: IconKey.budget, label: 'Rencana'),
        (icon: IconKey.wallets, label: 'Dompet'),
      ],
      selectedIndex: selected,
      onSelected: onSelected,
      recordLabel: 'Catat',
      onRecord: onRecord,
      onRecordLongPress: onLong,
    );

    testWidgets('ikon piksel tab: 32px utuh, tujuan tak aktif diredupkan', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PixelTheme.light,
          home: Scaffold(
            bottomNavigationBar: AppNavBar(
              destinations: const [
                (icon: IconKey.navHome, label: 'Beranda'),
                (icon: IconKey.navHistory, label: 'Riwayat'),
                (icon: IconKey.navPlan, label: 'Rencana'),
                (icon: IconKey.navWallets, label: 'Dompet'),
              ],
              selectedIndex: 1,
              onSelected: (_) {},
              recordLabel: 'Catat',
              onRecord: () {},
            ),
          ),
        ),
      );
      for (final key in [IconKey.navHome, IconKey.navHistory, IconKey.navPlan, IconKey.navWallets]) {
        expect(isPixelIcon(key), isTrue, reason: key.name);
        final icon = find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == key);
        expect(tester.getSize(icon), const Size.square(AppSize.pixelIcon));
        final opacity = tester.widget<Opacity>(find.ancestor(of: icon, matching: find.byType(Opacity)).first);
        expect(opacity.opacity, key == IconKey.navHistory ? 1 : lessThan(1));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('ketuk tujuan, ketuk Catat, dan tekan lama Catat (suara)', (
      tester,
    ) async {
      int? picked;
      var records = 0;
      var voices = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: PixelTheme.light,
          home: Scaffold(
            bottomNavigationBar: bar(
              onSelected: (i) => picked = i,
              onRecord: () => records++,
              onLong: () => voices++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Rencana'));
      expect(picked, 2);
      await tester.tap(find.byKey(const ValueKey('nav-catat')));
      expect(records, 1);
      await tester.longPress(find.byKey(const ValueKey('nav-catat')));
      expect(voices, 1);
      expect(records, 1);
    });

    testWidgets(
      'tujuan aktif: pil brandSoft dan ikon terisi; Catat brand bersudut piksel',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: PixelTheme.light,
            home: Scaffold(
              bottomNavigationBar: bar(
                onSelected: (_) {},
                onRecord: () {},
                selected: 1,
              ),
            ),
          ),
        );
        final pill = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.byWidgetPredicate(
              (w) => w is AppIcon && w.iconKey == IconKey.transactions,
            ),
            matching: find.byType(AnimatedContainer),
          ),
        );
        expect((pill.decoration! as ShapeDecoration).color, c.brandSoft);
        expect(
          tester
              .widget<AppIcon>(
                find.byWidgetPredicate(
                  (w) => w is AppIcon && w.iconKey == IconKey.transactions,
                ),
              )
              .fill,
          isTrue,
        );
        expect(
          tester
              .widget<AppIcon>(
                find.byWidgetPredicate(
                  (w) => w is AppIcon && w.iconKey == IconKey.home,
                ),
              )
              .fill,
          isFalse,
        );
        expect(
          tester.getSemantics(find.text('Riwayat')),
          isSemantics(isSelected: true, isButton: true),
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('nav-catat'))).height,
          greaterThanOrEqualTo(AppSize.catat),
        );
      },
    );
  });
}
