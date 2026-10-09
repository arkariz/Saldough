import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/source_icons.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';

/// PNG 1×1 transparan.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  setUp(() {
    SourceIcons.notifier.value = const {};
    SourceIcons.loader = null;
    ActiveCategories.notifier.value = const [
      Category(id: 'health', name: 'Kesehatan', kind: CategoryKind.expense, iconKey: 'categoryHealth'),
    ];
  });

  Future<void> pump(WidgetTester tester, Transaction transaction) => tester.pumpWidget(
    MaterialApp(
      theme: PixelTheme.light,
      home: Scaffold(body: Center(child: TransactionIcon.of(transaction))),
    ),
  );

  ExpenseTransaction expense({String? categoryId, String? sourceIconId}) => ExpenseTransaction(
    id: 't',
    date: DateTime(2026, 10),
    amount: 100,
    note: '',
    walletId: 'w',
    categoryId: categoryId,
    sourceIconId: sourceIconId,
  );

  testWidgets('kategori jadi ikon utama; pengeluaran tanpa kategori, ikon jenis (QA F8)', (tester) async {
    await pump(tester, expense(categoryId: 'health'));
    expect(find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.expense), findsNothing);
    expect(find.byType(AppIconTile), findsOneWidget);

    // Bukan "•••" (ikon tombol Semua kategori), tapi ikon jenis seperti
    // pemasukan dan transfer.
    await pump(tester, expense());
    expect(find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.expense), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.categoryOther), findsNothing);
  });

  testWidgets('lencana notifikasi muncul begitu ikonnya termuat, tanpa melebarkan ikon', (tester) async {
    await pump(tester, expense(categoryId: 'health', sourceIconId: 'ikon1'));
    expect(find.byType(Image), findsNothing);
    final before = tester.getSize(find.byType(TransactionIcon));

    SourceIcons.put('ikon1', _png);
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(tester.getSize(find.byType(TransactionIcon)), before);
  });

  testWidgets('ikon yang belum termuat diminta ke loader sekali', (tester) async {
    var calls = 0;
    SourceIcons.loader = (id) async {
      calls++;
      SourceIcons.put(id, _png);
      return _png;
    };
    await pump(tester, expense(sourceIconId: 'ikon2'));
    await tester.pump();
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(Image), findsOneWidget);
  });
}
