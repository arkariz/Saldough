import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';

/// Sembunyikan nominal (T-14.6, ADR-034 §4).
void main() {
  tearDown(() => AmountVisibility.notifier.value = false);

  test('formatter menulis Rp••••• selama disembunyikan; tanda tetap', () {
    expect(AppMoneyFormatter.format(4500000), 'Rp45.000');
    AmountVisibility.toggle();
    expect(AppMoneyFormatter.format(4500000), 'Rp•••••');
    expect(AppMoneyFormatter.format(-4500000), '−Rp•••••');
    expect(AppMoneyText.format(4500000, MoneyKind.income), '+Rp•••••');
    AmountVisibility.toggle();
    expect(AppMoneyFormatter.format(4500000), 'Rp45.000');
  });

  testWidgets('layar terbuka dibangun ulang saat setelan berganti', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: const ActiveCurrencyRebuilder(
          child: Scaffold(body: AppMoneyText(4500000)),
        ),
      ),
    );
    expect(find.text('Rp45.000'), findsOneWidget);
    AmountVisibility.toggle();
    await tester.pump();
    expect(find.text('Rp•••••'), findsOneWidget);
  });

  test('repository: bawaan tampil, menyimpan dan membaca balik', () async {
    final repository = AmountVisibilityRepositoryImpl(
      storage: InMemoryKeyValueStorage(),
    );
    expect((await repository.load()).getOrElse((_) => true), isFalse);
    await repository.save(hidden: true);
    expect((await repository.load()).getOrElse((_) => false), isTrue);
  });
}
