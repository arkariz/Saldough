import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/expense_form_sheet.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/categories.dart';
import '../../../../helpers/keypad.dart';

void main() {
  setUp(() => useCategories(['Makan']));

  const wallets = [
    Wallet(
      id: 'bca',
      name: 'BCA',
      iconKey: 'walletBank',
      initialBalance: 0,
      currentBalance: 500000000,
    ),
  ];

  testWidgets(
    'mengembalikan ExpenseRecorded dengan nominal dikonversi ke sen',
    (tester) async {
      ExpenseRecorded? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showModalBottomSheet<ExpenseRecorded>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const ExpenseFormSheet(wallets: wallets),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await enterAmount(tester, '75000');
      await tester.pump();
      // Daftar dompet terbuka (bukan lembar pemilih): ketuk barisnya langsung.
      // Dropdown dompet: buka lewat tombol "belum dipilih", ketuk itemnya.
      await tester.ensureVisible(find.text(t.record.walletNotSelectedPrompt));
      await tester.tap(find.text(t.record.walletNotSelectedPrompt));
      await tester.pumpAndSettle();
      await tester.tap(find.text(wallets.first.name).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('record-submit')));
      await tester.tap(find.byKey(const ValueKey('record-submit')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.walletId, 'bca');
      expect(result!.amount, 7500000);
    },
  );

  testWidgets(
    'initialWalletId mengisi dompet asal awal tanpa perlu memilih (FR-REC-002)',
    (tester) async {
      ExpenseRecorded? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showModalBottomSheet<ExpenseRecorded>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const ExpenseFormSheet(
                      wallets: wallets,
                      initialWalletId: 'bca',
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text('BCA'),
        findsWidgets,
        reason: 'dompet sudah terisi tanpa disentuh',
      );
      expect(find.text(t.record.walletNotSelectedPrompt), findsNothing);

      await enterAmount(tester, '75000');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('record-submit')));
      await tester.tap(find.byKey(const ValueKey('record-submit')));
      await tester.pumpAndSettle();

      expect(result?.walletId, 'bca');
    },
  );

  Future<void> pumpForm(
    WidgetTester tester, {
    List<Wallet> wallets = wallets,
    ExpenseTransaction? initial,
    List<BudgetItemOption> budgetItems = const [],
  }) {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseFormSheet(wallets: wallets, initial: initial, budgetItems: budgetItems),
        ),
      ),
    );
  }

  group('ExpenseFormSheet -- tata letak rujukan visual', () {
    testWidgets(
      'bagian prototipe Catat tampil: nominal, petak kategori, dompet, tanggal, catatan, keypad; tanpa Aturan Kas',
      (tester) async {
        await pumpForm(tester);

        expect(find.text(t.record.expenseRuleTitle), findsNothing);
        expect(find.text('Rp0', findRichText: true), findsOneWidget);
        expect(find.byType(AppKeypad), findsOneWidget);
        expect(
          find.text(t.record.allCategories),
          findsOneWidget,
        );
        expect(
          find.text(t.record.expenseWalletSectionLabel),
          findsOneWidget,
        );
        expect(
          find.text(t.record.dateFieldLabel),
          findsOneWidget,
        );
        expect(
          find.text(t.record.noteSectionLabel),
          findsOneWidget,
        );
        // Penafian tidak diulang di tiap formulir (UX-9).
        expect(find.textContaining('Tidak mendebit'), findsNothing);
      },
    );

    testWidgets(
      'dropdown dompet menawarkan SEMUA dompet, sama seperti penyaring di layar Transaksi',
      (tester) async {
        await pumpForm(
          tester,
          wallets: const [
            Wallet(
              id: 'bca',
              name: 'BCA',
              iconKey: 'walletBank',
              initialBalance: 0,
              currentBalance: 500000000,
            ),
            Wallet(
              id: 'gopay',
              name: 'GoPay',
              iconKey: 'walletEwallet',
              initialBalance: 0,
              currentBalance: 100000,
            ),
          ],
        );

        expect(find.byType(AppMenuSelectButton<String>), findsWidgets);
        expect(
          find.text('BCA'),
          findsNothing,
          reason: 'menu tertutup sampai tombolnya diketuk',
        );

        await tester.tap(find.text(t.record.walletNotSelectedPrompt));
        await tester.pumpAndSettle();

        expect(find.text('BCA'), findsOneWidget);
        expect(find.text('GoPay'), findsOneWidget);
      },
    );

    testWidgets(
      'akibat ke saldo ditulis sekali di baris dompet ("Saldo jadi"), tanpa ringkasan ganda',
      (tester) async {
        await pumpForm(tester);

        await enterAmount(tester, '75000');
        await tester.pump();
        await tester.tap(find.text(t.record.walletNotSelectedPrompt));
        await tester.pumpAndSettle();
        await tester.tap(find.text('BCA').last);
        await tester.pumpAndSettle();
        await tester.pump();

        expect(find.text(t.record.balanceAfter(amount: 'Rp4.925.000')), findsOneWidget);
        expect(find.textContaining('akan berkurang'), findsNothing);
      },
    );

    testWidgets('mode sunting: judul, label langkah, tombol, dan isian awal', (
      tester,
    ) async {
      await pumpForm(
        tester,
        initial: ExpenseTransaction(
          id: 'e1',
          date: DateTime(2026, 9, 1, 8, 30),
          amount: 7500000,
          note: 'nasi padang',
          walletId: 'bca',
          categoryId: 'Makan',
        ),
      );

      expect(find.text(t.transaction.editSheetTitle), findsOneWidget);
      // Sunting: tanpa mikrofon.
      expect(find.byKey(const ValueKey('record-voice')), findsNothing);
      expect(
        find.widgetWithText(AppButton, t.transaction.saveChangesAction),
        findsOneWidget,
      );
      expect(find.text('Rp75.000', findRichText: true), findsOneWidget);
      expect(find.text('nasi padang'), findsOneWidget);
      expect(find.textContaining('08.30'), findsOneWidget);
    });

    testWidgets(
      'nama dompet sangat panjang + saldo besar + teks 2x + layar 360px: tidak overflow, nama tidak dielipsis',
      (
        tester,
      ) async {
        const longName = 'Rekening Bank Central Asia Utama Pribadi Nomor Satu';
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpForm(
          tester,
          wallets: const [
            Wallet(
              id: 'w',
              name: longName,
              iconKey: 'walletBank',
              initialBalance: 0,
              currentBalance: 123456789000,
            ),
          ],
        );

        await enterAmount(tester, '99999999999');
        await tester.pump();
        await tester.tap(find.text(t.record.walletNotSelectedPrompt));
        await tester.pumpAndSettle();
        await tester.tap(find.text(longName).last);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final name = tester.widgetList<Text>(find.text(longName)).first;
        expect(name.overflow, isNot(TextOverflow.ellipsis));
      },
    );
  });

  testWidgets('Ulangi: Tiap bulan mengganti tombol jadi Catat & Jadwalkan dan ikut terkirim (T-15.3)', (tester) async {
    ExpenseRecorded? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showModalBottomSheet<ExpenseRecorded>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const ExpenseFormSheet(wallets: wallets, initialWalletId: 'bca'),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await enterAmount(tester, '65000');
    await tester.pump();

    await tester.ensureVisible(find.text(t.record.repeat.off));
    await tester.tap(find.text(t.record.repeat.off));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.record.repeat.monthly));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('repeat-done')));
    await tester.pumpAndSettle();

    expect(find.text(t.record.repeat.everyMonthDay(day: DateTime.now().day)), findsOneWidget);
    final submit = find.byKey(const ValueKey('record-submit'));
    expect(tester.widget<AppButton>(submit).label, t.record.repeat.recordAndScheduleAction);

    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(result?.repeat?.frequency, RecurringFrequency.monthly);
  });

  testWidgets('Jadikan Rutin (Ulangi terkunci): ringkasan tidak menjanjikan saldo berkurang (T-17.12)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ExpenseFormSheet(
                  wallets: wallets,
                  initialWalletId: 'bca',
                  initialAmountSen: 3000000,
                  initialRepeat: RecurringPattern(),
                  repeatLocked: true,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(t.record.repeat.noBalanceChange), findsOneWidget);
    expect(find.textContaining('akan berkurang'), findsNothing);
  });

  group('kalkulator papan angka (T-8.18)', () {
    Future<void> openSheet(WidgetTester tester, {ValueChanged<ExpenseRecorded?>? onResult}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final result = await showModalBottomSheet<ExpenseRecorded>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const ExpenseFormSheet(wallets: wallets, initialWalletId: 'bca'),
                  );
                  onResult?.call(result);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('ungkapan tampil di atas nominal; Simpan memakai hasilnya', (tester) async {
      ExpenseRecorded? result;
      await openSheet(tester, onResult: (r) => result = r);

      await enterAmount(tester, '10000+5000*2');
      expect(find.text('10.000 + 5.000 × 2'), findsOneWidget);
      expect(find.text('Rp20.000', findRichText: true), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('record-submit')));
      await tester.tap(find.byKey(const ValueKey('record-submit')));
      await tester.pumpAndSettle();
      expect(result!.amount, 2000000);
    });

    testWidgets('hasil tidak sah menonaktifkan Simpan dan diberi keterangan', (tester) async {
      await openSheet(tester);
      await enterAmount(tester, '100-100');
      expect(find.text(t.record.calc.notPositive), findsOneWidget);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('record-submit'))).onPressed, isNull);

      // Hapus melewati operand dan operator kembali ke nominal biasa.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const ValueKey('keypad-backspace')));
        await tester.pump();
      }
      expect(find.byKey(const ValueKey('record-amount-expression')), findsNothing);
      expect(find.text('Rp100', findRichText: true), findsOneWidget);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('record-submit'))).onPressed, isNotNull);
    });
  });

  group('ExpenseFormSheet -- pos anggaran transaksi tertaut rutin (T-18.12)', () {
    final options = [
      BudgetItemOption(
        budgetId: 'bulanan-okt',
        budgetName: 'Bulanan',
        itemId: 'cicilan-okt',
        itemName: 'Cicilan',
        walletId: 'bca',
        startDate: DateTime(2026, 10, 25),
        endDate: DateTime(2026, 11, 25),
        templateItemId: 'k-cicilan',
        plannedAmount: 291400000,
      ),
    ];
    ExpenseTransaction cicilan({RecurrenceLink? recurrence}) => ExpenseTransaction(
      id: 'cicilan',
      date: DateTime(2026, 10, 24, 9),
      amount: 291400000,
      note: 'Cicilan',
      walletId: 'bca',
      budgetItemId: 'cicilan-okt',
      recurrence: recurrence,
    );

    testWidgets('menyunting cicilan 24 Okt untuk kemunculan 25 Okt: pos periode 25 Okt tetap terpilih', (tester) async {
      await pumpForm(
        tester,
        initial: cicilan(recurrence: RecurrenceLink(ruleId: 'cicilan', occurrenceDate: DateTime(2026, 10, 25))),
        budgetItems: options,
      );
      expect(find.text('Cicilan · Bulanan'), findsOneWidget);
      expect(find.text(t.record.budgetItemOutOfPeriod(name: 'Bulanan')), findsNothing);
    });

    testWidgets('tanpa tautan rutin: tanggal 24 Okt di luar periode, tautannya lepas', (tester) async {
      await pumpForm(tester, initial: cicilan(), budgetItems: options);
      expect(find.text('Cicilan · Bulanan'), findsNothing);
      expect(find.text(t.record.budgetItemOutOfPeriod(name: 'Bulanan')), findsOneWidget);
    });
  });
}
