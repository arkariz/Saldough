import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/startup/boot_failure_app.dart';
import 'package:saldough/core/foundation/boot/boot_trace.dart';

/// Penjaga startup: jejak langkah dan layar darurat yang menyebut langkahnya.
void main() {
  setUp(BootTrace.reset);

  test('jejak mencatat langkah terakhir dan runutnya; layar tampil menghentikan penjaga', () {
    BootTrace.mark('di.run');
    BootTrace.mark('language');
    expect(BootTrace.step, 'language');
    expect(BootTrace.history, ['di.run', 'language']);
    expect(BootTrace.shown, isFalse);
    BootTrace.markShown();
    expect(BootTrace.shown, isTrue);
  });

  test('runut dibatasi 40 langkah', () {
    for (var i = 0; i < 50; i++) {
      BootTrace.mark('s$i');
    }
    expect(BootTrace.history.length, 40);
    expect(BootTrace.history.first, 's10');
  });

  testWidgets('tertahan: menyebut langkah dan menyediakan Coba lagi', (tester) async {
    var retried = 0;
    await tester.pumpWidget(BootFailureApp(step: 'entitlements', stuck: true, onRetry: () => retried++));
    expect(find.byKey(const ValueKey('boot-failure-title')), findsOneWidget);
    expect(find.textContaining('Langkah: entitlements'), findsOneWidget);
    expect(find.textContaining('lebih lama dari biasanya'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('boot-failure-retry')));
    expect(retried, 1);
  });

  testWidgets('galat: menyebut galat dan langkah', (tester) async {
    await tester.pumpWidget(BootFailureApp(step: 'di.run', stuck: false, error: StateError('x')));
    expect(find.textContaining('Langkah: di.run'), findsOneWidget);
    expect(find.textContaining('Galat: Bad state: x'), findsOneWidget);
    expect(find.byKey(const ValueKey('boot-failure-retry')), findsNothing);
  });
}
