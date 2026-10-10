import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';

class _Amount extends StatelessWidget {
  const _Amount();

  @override
  Widget build(BuildContext context) => Text(AppMoneyFormatter.format(5000000));
}

void main() {
  testWidgets('mengganti mata uang membangun ulang layar dasar dan rute yang terbuka di atasnya', (tester) async {
    addTearDown(() => ActiveCurrency.notifier.value = AppCurrency.idr);
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ActiveCurrencyRebuilder(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: _Amount()),
        ),
      ),
    );
    navigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: _Amount())));
    await tester.pumpAndSettle();

    ActiveCurrency.notifier.value = AppCurrency.usd;
    await tester.pump();

    expect(find.text(r'$50.000,00', skipOffstage: false), findsNWidgets(2));
    expect(find.text('Rp50.000', skipOffstage: false), findsNothing);
  });
}
