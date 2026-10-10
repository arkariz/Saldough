import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/theme/theme.dart';

void main() {
  Future<void> pumpIcon(WidgetTester tester, IconKey key) {
    return tester.pumpWidget(MaterialApp(home: AppIcon(key)));
  }

  group('AppIcon', () {
    // Benda: ikon piksel (design system bagian Ikon).
    const pixelKeys = [
      IconKey.walletBank,
      IconKey.walletCash,
      IconKey.walletEwallet,
      IconKey.walletSavings,
      IconKey.walletCard,
      IconKey.income,
      IconKey.expense,
      IconKey.transfer,
      IconKey.categoryTransport,
      IconKey.categoryEntertainment,
      IconKey.categoryFood,
      IconKey.freelance,
      IconKey.worklog,
      IconKey.pending,
      IconKey.paid,
      IconKey.overBudget,
      IconKey.categoryHousehold,
      IconKey.categoryBills,
      IconKey.categoryCoffee,
      IconKey.categoryEducation,
      IconKey.categoryElectricity,
      IconKey.categoryEmergencyFund,
      IconKey.categoryFuel,
      IconKey.categoryGroceries,
      IconKey.categoryHealth,
      IconKey.categoryInternet,
      IconKey.categoryInvestment,
      IconKey.categoryPets,
      IconKey.categoryShopping,
      IconKey.empty,
      IconKey.categoryFamily,
      IconKey.categoryDonation,
      IconKey.categoryBonus,
      IconKey.categoryGift,
      IconKey.categoryOther,
      IconKey.accountPixel,
    ];

    // Tindakan dan navigasi: Material Symbols.
    const symbolKeys = [
      IconKey.home,
      IconKey.budget,
      IconKey.record,
      IconKey.transactions,
      IconKey.wallets,
      IconKey.check,
      IconKey.account,
      IconKey.moreHorizontal,
      IconKey.reorder,
      IconKey.dragHandle,
      IconKey.calendar,
      IconKey.search,
      IconKey.filter,
      IconKey.locked,
      IconKey.add,
      IconKey.edit,
      IconKey.delete,
      IconKey.chevronLeft,
      IconKey.chevronRight,
      IconKey.dropdown,
    ];

    for (final key in pixelKeys) {
      testWidgets('$key merender SvgPicture dari aset piksel', (tester) async {
        await pumpIcon(tester, key);
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
        expect(isPixelIcon(key), isTrue);
      });
    }

    for (final key in symbolKeys) {
      testWidgets('$key merender Material Symbols Rounded', (tester) async {
        await pumpIcon(tester, key);
        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon!.fontFamily, 'MaterialSymbolsRounded');
        expect(find.byType(SvgPicture), findsNothing);
        expect(isPixelIcon(key), isFalse);
      });
    }

    testWidgets('fill menyalakan varian berisi (tab aktif)', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppIcon(IconKey.home, fill: true)));
      expect(tester.widget<Icon>(find.byType(Icon)).fill, 1);
    });

    testWidgets('seluruh IconKey terpetakan (tidak ada yang gagal assert)', (tester) async {
      for (final key in IconKey.values) {
        await pumpIcon(tester, key);
        expect(tester.takeException(), isNull, reason: 'IconKey.$key gagal dirender');
      }
    });

    testWidgets('size diteruskan ke Icon Material', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppIcon(IconKey.add, size: 40)));
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 40);
    });

    testWidgets('color diteruskan ke Icon Material', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppIcon(IconKey.delete, color: Colors.red)),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, Colors.red);
    });
  });

  group('walletIconKey', () {
    test('memetakan nama IconKey dompet ke IconKey yang sama', () {
      expect(walletIconKey('walletBank'), IconKey.walletBank);
      expect(walletIconKey('walletCash'), IconKey.walletCash);
      expect(walletIconKey('walletEwallet'), IconKey.walletEwallet);
      expect(walletIconKey('walletSavings'), IconKey.walletSavings);
      expect(walletIconKey('walletCard'), IconKey.walletCard);
    });

    test('kunci tidak dikenal atau bukan jenis dompet jatuh ke ikon dompet generik, bukan melempar', () {
      expect(walletIconKey('bank'), IconKey.wallets);
      expect(walletIconKey(''), IconKey.wallets);
      // Nama IconKey yang valid tapi bukan jenis dompet tidak boleh lolos.
      expect(walletIconKey('categoryFood'), IconKey.wallets);
    });
  });

  group('AppIcon -- garis tepi ikon piksel di mode gelap (B-23)', () {
    const mapper = PixelOutlineColorMapper(Color(0xFF857A71));

    test('hanya warna garis tepi #1E1B19 yang diganti', () {
      expect(mapper.substitute(null, 'rect', 'fill', const Color(0xFF1E1B19)), const Color(0xFF857A71));
      expect(mapper.substitute(null, 'rect', 'fill', const Color(0xFFC2410C)), const Color(0xFFC2410C));
      expect(mapper.substitute(null, 'rect', 'fill', const Color(0x801E1B19)), const Color(0x801E1B19));
    });

    testWidgets('tema gelap memasang pemeta warna lineStrong; tema terang tidak', (tester) async {
      ColorMapper? mapperOf() =>
          (tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader as SvgAssetLoader).colorMapper;

      await tester.pumpWidget(MaterialApp(theme: PixelTheme.dark, home: const AppIcon(IconKey.categoryCoffee)));
      expect(mapperOf(), PixelOutlineColorMapper(AppColors.dark.lineStrong));

      await tester.pumpWidget(MaterialApp(theme: PixelTheme.light, home: const AppIcon(IconKey.categoryCoffee)));
      await tester.pumpAndSettle(); // Pergantian tema dianimasikan.
      expect(mapperOf(), isNull);
    });
  });
}
