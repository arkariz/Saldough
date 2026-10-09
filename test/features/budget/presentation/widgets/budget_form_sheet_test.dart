import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_sheet.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_item_form_sheet.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  const bca = Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000);

  Future<void> pumpForm(WidgetTester tester, {Budget? initial}) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: BudgetFormSheet(wallets: const [bca], initial: initial),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppButton saveButton(WidgetTester tester, String label) =>
      tester.widget<AppButton>(find.widgetWithText(AppButton, label));

  group('BudgetFormSheet (ADR-017)', () {
    testWidgets('tidak ada kolom nominal rencana; tanpa pos, simpan mati dan alasannya tampil', (tester) async {
      await pumpForm(tester);
      await tester.enterText(find.byType(TextField).first, 'Rumah tangga');
      await tester.pump();

      expect(find.text(t.budget.totalPlannedLabel), findsOneWidget);
      expect(find.text('Rp0'), findsOneWidget);
      expect(find.text(t.budget.itemsRequiredHint), findsOneWidget);
      expect(saveButton(tester, t.budget.saveAddAction).onPressed, isNull);
    });

    testWidgets('total rencana = jumlah pos', (tester) async {
      await pumpForm(
        tester,
        initial: Budget(
          id: 'b1',
          name: 'Rumah tangga',
          walletId: 'bca',
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 9),
          items: const [
            BudgetItem(id: 'mingguan', name: 'Belanja mingguan', quantity: 4, unitPrice: 57660000),
            BudgetItem(id: 'bulanan', name: 'Belanja bulanan', enteredAmount: 76210000),
          ],
        ),
      );

      // 4 × Rp576.600 + Rp762.100 = Rp3.068.500 (DOMAIN_MODEL.md).
      expect(find.text('Rp3.068.500'), findsOneWidget);
      expect(find.text(t.budget.itemsRequiredHint), findsNothing);
      expect(saveButton(tester, t.transaction.saveChangesAction).onPressed, isNotNull);
    });
  });

  group('tata letak 360×640 (QA PR #43 F14)', () {
    // Font asli, supaya lebar label terukur seperti di perangkat.
    setUpAll(() async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
      await loader.load();
    });

    final wallets = [
      for (var i = 0; i < 6; i++)
        Wallet(id: 'w$i', name: 'Dompet $i', iconKey: 'walletBank', initialBalance: 0, currentBalance: 100000000),
    ];

    Future<void> open(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1
        ..padding = const FakeViewPadding(top: 24, bottom: 48);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: PixelTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showFullScreenSheet<void>(
                  context,
                  builder: (_) => BudgetFormSheet(wallets: wallets),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('6 dompet: dompet satu baris, Simpan terlihat di atas navigasi sistem tanpa menggulir', (tester) async {
      await open(tester);
      expect(find.text('Dompet 5'), findsNothing, reason: 'dompet di pemilih, bukan daftar');
      expect(find.byKey(const ValueKey('budget-wallet')), findsOneWidget);
      final save = tester.getRect(find.byKey(const ValueKey('budget-save')));
      expect(save.bottom, lessThanOrEqualTo(640 - 48));
      expect(save.top, greaterThan(0));
      expect(find.byKey(const ValueKey('budget-total')).hitTestable(), findsOneWidget);
      // Label total sebaris di samping tombol.
      final label = tester.renderObject<RenderParagraph>(find.text(t.budget.totalPlannedLabel));
      expect(label.getMaxIntrinsicWidth(double.infinity), lessThanOrEqualTo(label.size.width + 0.5));
    });

    testWidgets('periode satu baris tanpa badge rentang terpisah', (tester) async {
      await open(tester);
      final row = find.byKey(const ValueKey('budget-start'));
      expect(row, findsOneWidget);
      expect(tester.getSize(row).height, lessThanOrEqualTo(64));
      expect(find.byKey(const ValueKey('budget-period-weekly')), findsOneWidget);
    });

    testWidgets('menambah pos memperbarui total di bilah bawah', (tester) async {
      await open(tester);
      expect(tester.widget<Text>(find.byKey(const ValueKey('budget-total'))).data, 'Rp0');
      await tester.ensureVisible(find.text(t.budget.addItemAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.budget.addItemAction));
      await tester.pumpAndSettle();
      final fields = find.descendant(of: find.byType(BudgetItemFormSheet), matching: find.byType(TextField));
      await tester.enterText(fields.first, 'Beras');
      await tester.enterText(fields.last, '50000');
      await tester.pump();
      await tester.ensureVisible(find.text(t.budget.itemSaveAction));
      await tester.tap(find.text(t.budget.itemSaveAction));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.byKey(const ValueKey('budget-total'))).data, 'Rp50.000');
    });
  });
}
