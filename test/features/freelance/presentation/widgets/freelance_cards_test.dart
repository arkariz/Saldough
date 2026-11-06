import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_amount.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_kind.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/net_pay_breakdown.dart';
import 'package:saldough/features/freelance/domain/entities/payment_status.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_cards.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_notice.dart';
import 'package:saldough/features/freelance/presentation/widgets/net_pay_breakdown_card.dart';

void main() {
  final entry = WorklogEntry(
    id: 'w',
    projectId: 'p',
    date: DateTime(2026, 11, 3),
    hours: 4,
    hourlyRate: 15000000,
    note: 'Revisi halaman beranda dan penyesuaian tampilan di layar kecil',
  );
  final pending = FreelancePayment(
    id: 'pay',
    projectId: 'p',
    entryIds: const ['w'],
    expectedDate: DateTime(2026, 11, 12),
  );
  final paid = FreelancePayment(
    id: 'pay',
    projectId: 'p',
    entryIds: const ['w'],
    expectedDate: DateTime(2026, 11, 12),
    status: PaymentStatus.paid,
    walletId: 'bri',
    incomeTransactionId: 'tx',
    receivedDate: DateTime(2026, 11, 10),
  );
  const rule = DeductionRule(id: 'd', label: 'Pajak', kind: DeductionKind.percentage, value: 25);
  const breakdown = NetPayBreakdown(
    grossPay: 60000000,
    deductions: [DeductionAmount(rule: rule, amount: 1500000)],
    netPay: 58500000,
  );

  Future<void> pump(WidgetTester tester, Widget child, {double scale = 1}) async {
    tester.view
      ..physicalSize = const Size(360, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: c!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  testWidgets('entri belum ditagih: lencana netral, bisa diketuk, tanpa keterangan terkunci', (tester) async {
    var tapped = false;
    await pump(
      tester,
      WorklogEntryCard(entry: entry, payment: null, walletName: null, onTap: () => tapped = true),
    );
    expect(find.text(t.freelance.statusUnbilled), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    await tester.tap(find.byType(WorklogEntryCard));
    expect(tapped, isTrue);
  });

  testWidgets('entri tertunda dan diterima: terkunci dengan keterangan tanggal dan dompet', (tester) async {
    await pump(tester, WorklogEntryCard(entry: entry, payment: pending, walletName: null, onTap: null));
    expect(find.text(t.freelance.statusPending), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

    await pump(tester, WorklogEntryCard(entry: entry, payment: paid, walletName: 'BRI', onTap: null));
    await tester.pump();
    expect(find.text(t.freelance.statusPaid), findsOneWidget);
    expect(find.textContaining('BRI'), findsOneWidget);
  });

  testWidgets('kartu tagihan: rincian gaji, menu tiga titik, dan aksi utama penuh lebar', (tester) async {
    await pump(
      tester,
      FreelancePaymentCard(
        payment: pending,
        title: '3 Nov',
        breakdown: breakdown,
        entryCount: 1,
        hours: 4,
        walletName: null,
        menu: const Icon(Icons.more_horiz_rounded),
        actions: [DsButton(label: t.freelance.receiveAction, expand: true, onPressed: () {})],
      ),
    );
    expect(find.byType(NetPayBreakdownCard), findsOneWidget);
    expect(find.text(t.freelance.netPayLabel), findsOneWidget);
    expect(find.text(t.freelance.receiveAction), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
  });

  testWidgets('pemberitahuan: dua nada tampil dengan judul dan isi', (tester) async {
    await pump(
      tester,
      const Column(
        children: [
          FreelanceNotice(title: 'Judul A', body: 'Isi A'),
          FreelanceNotice(title: 'Judul B', body: 'Isi B', tone: FreelanceNoticeTone.positive),
        ],
      ),
    );
    expect(find.text('Judul A'), findsOneWidget);
    expect(find.text('Isi B'), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('360dp teks ${scale}x: kartu entri dan tagihan bercatatan panjang tanpa luap', (tester) async {
      await pump(
        tester,
        Column(
          children: [
            WorklogEntryCard(entry: entry, payment: paid, walletName: 'Dompet Tabungan Utama', onTap: null),
            FreelancePaymentCard(
              payment: paid,
              title: '3 Nov – 10 Nov',
              breakdown: breakdown,
              entryCount: 2,
              hours: 12,
              walletName: 'Dompet Tabungan Utama',
              actions: [DsInlineAction(label: t.freelance.receiptCancelAction, onPressed: () {})],
            ),
          ],
        ),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
