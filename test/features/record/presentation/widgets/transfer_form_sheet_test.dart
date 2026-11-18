import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/record_goal_split_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_save_button.dart';
import 'package:saldough/features/record/presentation/widgets/transfer_form_sheet.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import '../../../../helpers/keypad.dart';

void main() {
  const wallets = [
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
      currentBalance: 0,
    ),
  ];

  Future<Widget> openSheet(
    WidgetTester tester,
    void Function(TransferRecorded?) onResult,
  ) async {
    final widget = MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await showModalBottomSheet<TransferRecorded>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const TransferFormSheet(wallets: wallets),
              );
              onResult(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return widget;
  }

  group('TransferFormSheet', () {
    testWidgets(
      'tombol Catat nonaktif kalau dompet asal dan tujuan sama (FR-TXN-003)',
      (tester) async {
        TransferRecorded? result;
        await openSheet(tester, (r) => result = r);

        await enterAmount(tester, '100000');
        await tester.pump();
        // Kedua `WalletPickerField` (asal/tujuan) sama-sama menampilkan
        // "belum dipilih" mula-mula -- ketuk yang pertama (asal), pilih BCA di
        // lembar pemilihnya, lalu ketuk sisanya (satu-satunya yang belum
        // dipilih sekarang, yaitu tujuan) dan pilih BCA lagi supaya sama
        // dengan asal.
        await tester.ensureVisible(
          find.text(t.record.walletNotSelectedPrompt).first,
        );
        await tester.tap(find.text(t.record.walletNotSelectedPrompt).first);
        await tester.pumpAndSettle();
        // `.last` -- di dalam lembar pemilih adalah kemunculan TERBARU nama
        // dompet ini di pohon widget (lembar sebelumnya masih ada di baliknya).
        await tester.tap(find.text('BCA').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(t.record.walletNotSelectedPrompt));
        await tester.tap(find.text(t.record.walletNotSelectedPrompt));
        await tester.pumpAndSettle();
        await tester.tap(find.text('BCA').last);
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('record-submit')), findsOneWidget);
        final button = tester.widget<RecordSaveButton>(find.byKey(const ValueKey('record-submit')));
        expect(button.onPressed, isNull);

        await tester.ensureVisible(find.byKey(const ValueKey('record-submit')));
        await tester.tap(find.byKey(const ValueKey('record-submit')));
        await tester.pumpAndSettle();
        expect(result, isNull);
      },
    );

    testWidgets(
      'mengembalikan TransferRecorded saat dompet asal dan tujuan berbeda',
      (tester) async {
        TransferRecorded? result;
        await openSheet(tester, (r) => result = r);

        await enterAmount(tester, '100000');
        await tester.pump();
        // Field pertama (asal) -> BCA, field kedua (tujuan) -> GoPay.
        await tester.ensureVisible(
          find.text(t.record.walletNotSelectedPrompt).first,
        );
        await tester.tap(find.text(t.record.walletNotSelectedPrompt).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('BCA').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(t.record.walletNotSelectedPrompt));
        await tester.tap(find.text(t.record.walletNotSelectedPrompt));
        await tester.pumpAndSettle();
        await tester.tap(find.text('GoPay').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const ValueKey('record-submit')));
        await tester.tap(find.byKey(const ValueKey('record-submit')));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.fromWalletId, 'bca');
        expect(result!.toWalletId, 'gopay');
        expect(result!.amount, 10000000);
      },
    );

    testWidgets(
      'initialWalletId mengisi dompet ASAL awal, tujuan masih perlu dipilih (FR-REC-002)',
      (tester) async {
        TransferRecorded? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await showModalBottomSheet<TransferRecorded>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const TransferFormSheet(
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
          reason: 'dompet ASAL sudah terisi tanpa disentuh',
        );
        expect(
          find.text(t.record.walletNotSelectedPrompt),
          findsOneWidget,
          reason: 'dompet TUJUAN masih kosong',
        );

        await enterAmount(tester, '100000');
        await tester.pump();
        await tester.ensureVisible(find.text(t.record.walletNotSelectedPrompt));
        await tester.tap(find.text(t.record.walletNotSelectedPrompt));
        await tester.pumpAndSettle();
        await tester.tap(find.text('GoPay').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('record-submit')));
        await tester.tap(find.byKey(const ValueKey('record-submit')));
        await tester.pumpAndSettle();

        expect(result?.fromWalletId, 'bca');
        expect(result?.toWalletId, 'gopay');
      },
    );
  });

  group('Bagi ke beberapa tujuan (ADR-048 §9)', () {
    final created = DateTime(2026, 11);
    final goals = [
      SavingsGoal(id: 'a', name: 'Darurat', targetAmount: 1, iconKey: 'walletSavings', walletId: 'wa', createdAt: created),
      SavingsGoal(id: 'b', name: 'Liburan', targetAmount: 1, iconKey: 'walletSavings', walletId: 'wb', createdAt: created),
      SavingsGoal(id: 'c', name: 'Rumah', targetAmount: 1, iconKey: 'walletSavings', walletId: 'wc', createdAt: created),
    ];
    const allWallets = [
      ...wallets,
      Wallet(id: 'wa', name: 'Darurat', iconKey: 'walletSavings', initialBalance: 0, currentBalance: 0),
      Wallet(id: 'wb', name: 'Liburan', iconKey: 'walletSavings', initialBalance: 0, currentBalance: 0),
      Wallet(id: 'wc', name: 'Rumah', iconKey: 'walletSavings', initialBalance: 0, currentBalance: 0),
    ];

    Future<void> open(WidgetTester tester, void Function(Object?) onResult, {List<SavingsGoal>? splitGoals}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  onResult(
                    await showModalBottomSheet<Object>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => TransferFormSheet(
                        wallets: allWallets,
                        initialWalletId: 'bca',
                        splitGoals: splitGoals ?? goals,
                        goalWalletIds: const {'wa', 'wb', 'wc'},
                        rememberedSplit: const {'a': 50, 'b': 30, 'c': 20},
                      ),
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
    }

    Future<void> turnOn(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const ValueKey('split-toggle')));
      await tester.tap(find.byKey(const ValueKey('split-toggle')));
      await tester.pumpAndSettle();
    }

    testWidgets('sakelar tidak tampil bila tujuan Active kurang dari dua', (tester) async {
      await open(tester, (_) {}, splitGoals: [goals.first]);
      expect(find.byKey(const ValueKey('split-toggle')), findsNothing);
    });

    testWidgets('mode bagi: persen terakhir terisi, Ke dompet disembunyikan, hasil SplitTransferRecorded', (tester) async {
      Object? result;
      await open(tester, (r) => result = r);
      await turnOn(tester);

      expect(find.text(t.record.destinationWalletFieldLabel), findsNothing);
      expect(find.byKey(const ValueKey('split-goal-a')), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      await enterAmount(tester, '100000');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('record-submit')));
      await tester.tap(find.byKey(const ValueKey('record-submit')));
      await tester.pumpAndSettle();

      expect(result, isA<SplitTransferRecorded>());
      final split = result! as SplitTransferRecorded;
      expect(split.fromWalletId, 'bca');
      expect(split.amount, 10000000);
      expect(split.percents, {'a': 50, 'b': 30, 'c': 20});
    });

    Future<void> press(WidgetTester tester, String key) async {
      final finder = find.byKey(ValueKey('keypad-$key'));
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();
    }

    Future<void> select(WidgetTester tester, String goalId) async {
      await tester.ensureVisible(find.byKey(ValueKey('split-percent-$goalId')));
      await tester.tap(find.byKey(ValueKey('split-percent-$goalId')));
      await tester.pump();
    }

    testWidgets('papan angka mengisi persen tujuan aktif; bukan 100: Catat nonaktif', (tester) async {
      await open(tester, (_) {});
      await turnOn(tester);
      await enterAmount(tester, '100000');
      await tester.pump();

      await select(tester, 'c');
      await press(tester, 'backspace');
      await press(tester, 'backspace');
      await press(tester, '1');
      await press(tester, '0');

      expect(find.text('10%'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text(t.record.split.totalShort(n: 10)), findsOneWidget);
      expect(find.text('Rp100.000'), findsOneWidget, reason: 'nominal tidak berubah selama persen yang diisi');
      final button = tester.widget<RecordSaveButton>(find.byKey(const ValueKey('record-submit')));
      expect(button.onPressed, isNull);

      // Isi sisa mengembalikan Rumah ke 20%.
      await tester.tap(find.byKey(const ValueKey('split-fill')));
      await tester.pump();
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('hanya tujuan yang ikut tampil; keluarkan, tambah, dan bagi rata', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet<Object>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => TransferFormSheet(
                    wallets: allWallets,
                    splitGoals: goals,
                    goalWalletIds: const {'wa', 'wb', 'wc'},
                    rememberedSplit: const {'a': 60, 'b': 40},
                    startInSplit: true,
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

      expect(find.byKey(const ValueKey('split-goal-c')), findsNothing, reason: 'Rumah tidak ikut pembagian terakhir');

      await tester.ensureVisible(find.byKey(const ValueKey('split-add')));
      await tester.tap(find.byKey(const ValueKey('split-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('split-add-c')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('split-goal-c')), findsOneWidget);
      expect(find.byKey(const ValueKey('split-add')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('split-even')));
      await tester.pump();
      expect(find.text('34%'), findsOneWidget);
      expect(find.text('33%'), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('split-remove-a')));
      await tester.pump();
      expect(find.byKey(const ValueKey('split-goal-a')), findsNothing);
      expect(find.text('66%'), findsOneWidget);
    });
  });

  test('percentAfterKey: angka di belakang, hapus, tolak > 100', () {
    expect(percentAfterKey(3, '5'), 35);
    expect(percentAfterKey(35, 'backspace'), 3);
    expect(percentAfterKey(1, '000'), 100);
    expect(percentAfterKey(50, '0'), 50, reason: '500 ditolak');
    expect(percentAfterKey(40, 'clear'), 0);
    expect(percentAfterKey(4, '+'), 4);
  });
}
