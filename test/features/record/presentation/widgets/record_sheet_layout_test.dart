import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/widgets/expense_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/income_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_host.dart';
import 'package:saldough/features/record/presentation/widgets/transfer_form_sheet.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Tata letak sheet Catat di layar sempit (QA PR #43 F1, F3, F6, F9), dengan
/// font asli dimuat supaya lebar dan tinggi teks terukur seperti di perangkat.
void main() {
  setUpAll(() async {
    final loader = FontLoader('PlusJakartaSans')..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
    await loader.load();
  });

  const wallets = [
    Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000),
    Wallet(id: 'cash', name: 'Tunai', iconKey: 'walletCash', initialBalance: 0, currentBalance: 37600000),
  ];
  final now = DateTime.now();
  final budgetItems = [
    BudgetItemOption(
      budgetId: 'b',
      budgetName: 'Oktober',
      itemId: 'makan',
      itemName: 'Makan',
      walletId: 'bca',
      startDate: DateTime(now.year, now.month),
      endDate: DateTime(now.year, now.month + 1),
    ),
  ];

  void useBuiltInCategories() {
    ActiveCategories.notifier.value = [
      for (final key in ['transport', 'food', 'groceries', 'bills', 'entertainment', 'education'])
        Category(id: key, kind: CategoryKind.expense, name: t.category.builtIn[key]!, builtInKey: key),
      for (final key in ['salary', 'freelance', 'bonus', 'gift'])
        Category(id: key, kind: CategoryKind.income, name: t.category.builtIn[key]!, builtInKey: key),
    ];
    addTearDown(() => ActiveCategories.notifier.value = const []);
  }

  /// Lembar penuh layar seperti di aplikasi: bilah status [top], navigasi
  /// sistem [bottom].
  Future<void> open(WidgetTester tester, Widget form, {required Size size, double top = 24, double bottom = 48}) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1
      ..padding = FakeViewPadding(top: top, bottom: bottom);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showFullScreenSheet<void>(
                context,
                builder: (_) => RecordVoiceAction(onVoice: () {}, child: form),
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

  RecordKindSwitcher switcher(RecordChoice choice) => RecordKindSwitcher(selected: choice, onChanged: (_) {});

  /// Atas bilah papan angka: isian di atasnya terlihat tanpa menggulir.
  double keypadTop(WidgetTester tester) => tester.getTopLeft(find.byType(AppKeypad)).dy;

  void expectAbove(WidgetTester tester, Finder finder, double limit, String what) {
    expect(finder, findsWidgets, reason: what);
    expect(tester.getRect(finder.first).bottom, lessThanOrEqualTo(limit), reason: '$what tertutup papan angka');
  }

  /// Baris yang memuat [text] di daftar isian Catat.
  Finder rowOf(String text) => find.ancestor(of: find.text(text), matching: find.byType(ConstrainedBox)).first;

  void expectSingleLine(WidgetTester tester, Finder text, String what) {
    for (final element in text.evaluate()) {
      final paragraph = element.renderObject! as RenderParagraph;
      expect(
        paragraph.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(paragraph.size.width + 0.5),
        reason: '"$what" terbungkus ke baris kedua',
      );
    }
  }

  for (final locale in [AppLocale.id, AppLocale.en]) {
    group('locale ${locale.languageCode}', () {
      setUp(() async => LocaleSettings.setLocale(locale));
      tearDown(() => LocaleSettings.setLocaleSync(AppLocale.id));

      testWidgets('360×800: nominal, kategori, dompet, tanggal, catatan terlihat tanpa menggulir (F1)', (tester) async {
        useBuiltInCategories();
        await open(
          tester,
          ExpenseFormSheet(
            wallets: wallets,
            initialWalletId: 'bca',
            budgetItems: budgetItems,
            kindSwitcher: switcher(RecordChoice.expense),
          ),
          size: const Size(360, 800),
        );
        expect(tester.takeException(), isNull);
        final limit = keypadTop(tester);
        expectAbove(tester, find.byKey(const ValueKey('record-amount')), limit, 'nominal');
        expectAbove(tester, find.byKey(const ValueKey('category-all')), limit, 'kategori');
        expectAbove(tester, rowOf(t.record.expenseWalletSectionLabel), limit, 'dompet');
        expectAbove(tester, find.byKey(const ValueKey('record-date')), limit, 'tanggal');
        expectAbove(tester, rowOf(t.record.noteSectionLabel), limit, 'catatan');
      });

      testWidgets('384×832 (perangkat QA): pos anggaran juga terlihat (F1)', (tester) async {
        useBuiltInCategories();
        await open(
          tester,
          ExpenseFormSheet(
            wallets: wallets,
            initialWalletId: 'bca',
            budgetItems: budgetItems,
            kindSwitcher: switcher(RecordChoice.expense),
          ),
          size: const Size(384, 832),
          top: 32,
        );
        expectAbove(tester, rowOf(t.record.budgetItemNone), keypadTop(tester), 'pos anggaran');
      });

      testWidgets('label kategori tidak dipecah di tengah kata di 360dp (F3)', (tester) async {
        useBuiltInCategories();
        await open(
          tester,
          ExpenseFormSheet(wallets: wallets, kindSwitcher: switcher(RecordChoice.expense)),
          size: const Size(360, 800),
        );
        // Tiap kata label petak muat sebaris di petaknya.
        for (final key in ['transport', 'food', 'groceries']) {
          final label = find.descendant(of: find.byKey(ValueKey('category-$key')), matching: find.byType(RichText));
          final paragraph = tester.renderObject<RenderParagraph>(label);
          final words = t.category.builtIn[key]!.split(' ');
          for (final word in words) {
            final painter = TextPainter(
              text: TextSpan(text: word, style: paragraph.text.style),
              textDirection: TextDirection.ltr,
            )..layout();
            expect(painter.width, lessThanOrEqualTo(paragraph.size.width), reason: '"$word" dipecah');
            painter.dispose();
          }
        }
      });

      testWidgets('label dompet Pemasukan sebaris walau ada pratinjau saldo (F9)', (tester) async {
        useBuiltInCategories();
        await open(
          tester,
          IncomeFormSheet(wallets: wallets, initialWalletId: 'bca', kindSwitcher: switcher(RecordChoice.income)),
          size: const Size(360, 800),
        );
        await tester.tap(find.byKey(const ValueKey('keypad-9')));
        await tester.pump();
        expectSingleLine(tester, find.text(t.record.toWalletFieldLabel), t.record.toWalletFieldLabel);
      });

      testWidgets('transfer ke dompet sama: tanpa pratinjau saldo, galat terlihat (F6)', (tester) async {
        await open(
          tester,
          TransferFormSheet(
            wallets: wallets,
            initialWalletId: 'bca',
            initialToWalletId: 'bca',
            kindSwitcher: switcher(RecordChoice.transfer),
          ),
          size: const Size(360, 800),
        );
        await tester.tap(find.byKey(const ValueKey('keypad-9')));
        await tester.pump();
        expect(find.textContaining(t.record.balanceAfter(amount: '')), findsNothing);
        expectAbove(tester, find.text(t.record.sameWalletWarning), keypadTop(tester), 'galat dompet sama');
      });
    });
  }
}
