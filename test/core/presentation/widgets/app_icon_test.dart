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
    ];

    const fallbackKeys = [
      IconKey.categoryHousehold,
      IconKey.categoryBills,
      IconKey.categoryOther,
      IconKey.empty,
      IconKey.add,
      IconKey.edit,
      IconKey.delete,
      IconKey.chevronLeft,
      IconKey.chevronRight,
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

    testWidgets('seluruh 32 IconKey terpetakan (tidak ada yang gagal assert)', (tester) async {
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
}
