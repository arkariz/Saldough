import 'package:di/di.dart' show GetIt, ScopeProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/premium/domain/plus_purchasing.dart';
import 'package:saldough/features/record/presentation/widgets/record_repeat_field.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/recurring/recurring.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_plus_purchasing.dart';
import '../../../../helpers/routes.dart';

/// Sakelar Catat otomatis di "Atur lebih lanjut" (T-17.4, ADR-037 §3.2).
void main() {
  // Otomasi R3 hanya untuk Plus (ADR-041 §3.8); uji ini menguji perilakunya.
  setUp(() => ActivePlan.notifier.value = const PlusPlan(source: PlanSource.prelaunch));
  tearDown(ActivePlan.reset);

  testWidgets('nominal tetap: sakelar tampil dan menyalakan autoRecord; kira-kira menyembunyikan dan mematikannya', (
    tester,
  ) async {
    late RecurringPattern? latest;
    RecurringPattern? value = const RecurringPattern();
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => RecordRepeatField(
                value: value,
                date: DateTime(2026, 10, 5),
                kind: TransactionKind.expense,
                onChanged: (next) => setState(() => value = latest = next),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('record-repeat')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.record.repeat.moreAction));
    await tester.pumpAndSettle();

    final toggle = find.byKey(const ValueKey('repeat-auto-record'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(latest?.autoRecord, isTrue);

    await tester.ensureVisible(find.text(t.record.repeat.amountEstimated));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.record.repeat.amountEstimated));
    await tester.pumpAndSettle();
    expect(latest?.autoRecord, isFalse);
    expect(toggle, findsNothing);
  });

  testWidgets('Gratis: sakelar berlabel Plus, mengetuknya membuka paywall dan nilainya tidak berubah', (tester) async {
    ActivePlan.notifier.value = const FreePlan();
    RecurringPattern? latest;
    RecurringPattern? value = const RecurringPattern();
    final container = GetIt.asNewInstance()
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
      ..registerSingleton<PlusPurchasing>(FakePlusPurchasing(selling: false))
      ..registerSingleton<AuthRepository>(FakeAuthRepository());
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          theme: PixelTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => RecordRepeatField(
                  value: value,
                  date: DateTime(2026, 10, 5),
                  kind: TransactionKind.expense,
                  onChanged: (next) => setState(() => value = latest = next),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('record-repeat')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.record.repeat.moreAction));
    await tester.pumpAndSettle();

    expect(find.text('${t.record.repeat.autoRecordLabel} · ${t.premium.plusBadge}'), findsOneWidget);
    final toggle = find.byKey(const ValueKey('repeat-auto-record'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(latest, isNull, reason: 'nilai tidak berubah');
    expect(find.text(t.premium.signInTitle), findsOneWidget, reason: 'paywall terbuka');
  });

  test('toRule: catat otomatis hanya untuk nominal tetap; of() membawanya', () {
    RecurringRule build(RecurringPattern p) => p.toRule(
      id: 'r',
      kind: RecurringKind.expense,
      amount: 100,
      walletId: 'bca',
      note: 'Kos',
      anchorDate: DateTime(2026, 10),
    );
    final fixed = build(const RecurringPattern(autoRecord: true));
    expect(fixed.autoRecord, isTrue);
    expect(RecurringPattern.of(fixed).autoRecord, isTrue);
    expect(
      build(const RecurringPattern(autoRecord: true, amountMode: RecurringAmountMode.estimated)).autoRecord,
      isFalse,
    );
  });

  testWidgets('Atur lebih lanjut: ketukan di tepi baris, bukan hanya di teksnya, membuka pengaturan (QA Q1)', (
    tester,
  ) async {
    RecurringPattern? value = const RecurringPattern();
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => RecordRepeatField(
                value: value,
                date: DateTime(2026, 10, 5),
                kind: TransactionKind.expense,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('record-repeat')));
    await tester.pumpAndSettle();

    final more = find.byKey(const ValueKey('repeat-more'));
    final rect = tester.getRect(more);
    final label = tester.getRect(find.text(t.record.repeat.moreAction));
    expect(rect.width, greaterThan(label.width * 1.5), reason: 'selebar baris, bukan seukuran teks');
    await tester.tapAt(Offset(rect.left + 12, rect.center.dy));
    await tester.pumpAndSettle();

    expect(more, findsNothing, reason: 'pengaturan lanjutan terbuka menggantikan tombol');
  });
}
