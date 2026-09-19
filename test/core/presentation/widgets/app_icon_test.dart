import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';

void main() {
  Future<void> pumpIcon(WidgetTester tester, IconKey key) {
    return tester.pumpWidget(MaterialApp(home: AppIcon(key)));
  }

  group('AppIcon', () {
    const mappedKeys = [
      IconKey.home,
      IconKey.budget,
      IconKey.record,
      IconKey.transactions,
      IconKey.wallets,
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
      IconKey.check,
      IconKey.calendar,
      IconKey.categoryHousehold,
      IconKey.categoryBills,
      IconKey.categoryOther,
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
      IconKey.search,
      IconKey.filter,
    ];

    const fallbackKeys = [
      IconKey.empty,
      IconKey.add,
      IconKey.edit,
      IconKey.delete,
      IconKey.chevronLeft,
      IconKey.chevronRight,
      IconKey.dropdown,
      IconKey.locked,
    ];

    for (final key in mappedKeys) {
      testWidgets('$key merender SvgPicture dari aset pixel-art', (tester) async {
        await pumpIcon(tester, key);
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
      });
    }

    for (final key in fallbackKeys) {
      testWidgets('$key merender Icon Material sebagai isian sementara', (tester) async {
        await pumpIcon(tester, key);
        expect(find.byType(Icon), findsOneWidget);
        expect(find.byType(SvgPicture), findsNothing);
      });
    }

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
}
