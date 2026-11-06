import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_amount.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_kind.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/net_pay_breakdown.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/presentation/widgets/entry_form_sheet.dart';
import 'package:saldough/features/freelance/presentation/widgets/payment_form_sheet.dart';
import 'package:saldough/features/freelance/presentation/widgets/project_form_sheet.dart';
import 'package:saldough/features/freelance/presentation/widgets/receive_payment_sheet.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  const rule = DeductionRule(id: 'd', label: 'Pajak', kind: DeductionKind.percentage, value: 25);
  const project = FreelanceProject(
    id: 'p',
    name: 'Studio Kopi Senja — redesain situs',
    hourlyRate: 15000000,
    deductionRules: [rule],
  );
  final entry = WorklogEntry(id: 'w', projectId: 'p', date: DateTime(2026, 11, 3), hours: 4, hourlyRate: 15000000);
  const breakdown = NetPayBreakdown(
    grossPay: 60000000,
    deductions: [DeductionAmount(rule: rule, amount: 1500000)],
    netPay: 58500000,
  );
  const wallet = Wallet(id: 'bri', name: 'BRI', iconKey: 'walletBank', initialBalance: 0, currentBalance: 1000000);

  Future<void> pump(WidgetTester tester, Widget sheet, {double scale = 1}) async {
    tester.view
      ..physicalSize = const Size(360, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: c!,
        ),
        home: Scaffold(body: sheet),
      ),
    );
    await tester.pumpAndSettle();
  }

  final sheets = <String, Widget Function()>{
    'proyek (ubah, ada potongan)': () => const ProjectFormSheet(initial: project, canDelete: true),
    'jam kerja (ubah)': () => EntryFormSheet(projects: const [project], initial: entry),
    'buat tagihan': () => PaymentFormSheet(
      projects: const [project],
      unbilledEntries: {
        'p': [entry],
      },
      initialProjectId: 'p',
    ),
    'catat diterima': () =>
        const ReceivePaymentSheet(projectName: 'Studio Kopi Senja', breakdown: breakdown, wallets: [wallet]),
  };

  for (final MapEntry(:key, :value) in sheets.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('lembar $key, 360dp teks ${scale}x: tanpa luap', (tester) async {
        await pump(tester, value(), scale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('lembar proyek: tambah potongan membuka lembar potongan; jenis nominal tetap mengganti kolom', (
    tester,
  ) async {
    await pump(tester, const ProjectFormSheet(initial: project));
    expect(find.text('Pajak · 2,5%'), findsOneWidget);

    await tester.tap(find.text(t.freelance.deductionAddAction));
    await tester.pumpAndSettle();
    expect(find.text(t.freelance.deductionTitle), findsWidgets);
    expect(find.text(t.freelance.deductionPercentLabel), findsOneWidget);

    await tester.tap(find.text(t.freelance.deductionKindFixed));
    await tester.pumpAndSettle();
    expect(find.text(t.freelance.deductionAmountLabel), findsOneWidget);
    expect(find.text(t.freelance.deductionPercentLabel), findsNothing);
  });

  testWidgets('lembar jam kerja: tombol jam cepat mengisi kolom jam dan menghitung diperoleh', (tester) async {
    await pump(tester, const EntryFormSheet(projects: [project], initialProjectId: 'p'));
    await tester.tap(find.text(t.freelance.hoursValue(hours: 4)));
    await tester.pumpAndSettle();
    // 4 jam × Rp150.000 = Rp600.000
    expect(find.text('Rp600.000'), findsWidgets);
  });
}
