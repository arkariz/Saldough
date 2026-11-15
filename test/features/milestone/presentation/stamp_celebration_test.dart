import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/stamp_visuals.dart';
import 'package:saldough/features/milestone/presentation/widgets/legacy_banner_slide.dart';
import 'package:saldough/features/milestone/presentation/widgets/stamp_celebration.dart';

import '../../../helpers/reduced_motion.dart';

Widget _host(Widget child) => MaterialApp(
  theme: DsTheme.light,
  builder: reducedMotion,
  home: Scaffold(body: child),
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.id));

  test('delapan id punya aset, sudut tetap, dan nama sendiri', () {
    const ids = [
      'wallet_first',
      'record_first',
      'period_tidy',
      'recurring_clear',
      'inbox_clear',
      'backup_first',
      'budget_first',
      'freelance_paid',
    ];
    expect({for (final id in ids) stampAsset(id)}, hasLength(8));
    expect({for (final id in ids) stampName(id)}, hasLength(8));
    for (final id in ids) {
      expect(stampRotation(id), inInclusiveRange(-7, 6));
    }
  });

  testWidgets('segel diraih dan terkunci memakai label semantik, tanpa gembok', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            DsStampSeal(asset: 'assets/icons_clay/bank_wallet.svg', semanticLabel: 'Dompet pertama, diraih 25 Okt'),
            DsStampSeal(
              asset: 'assets/icons_clay/bank_wallet.svg',
              semanticLabel: 'Dompet pertama, belum diraih',
              earned: false,
            ),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Dompet pertama, diraih 25 Okt'), findsOneWidget);
    expect(find.bySemanticsLabel('Dompet pertama, belum diraih'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNothing);
  });

  testWidgets('snackbar: satu stempel menyebut nama, beberapa digabung, aksi Lihat', (tester) async {
    var seen = 0;
    late BuildContext captured;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final messenger = ScaffoldMessenger.of(captured)
      ..showSnackBar(stampSnackBar(captured, ids: ['wallet_first'], onSee: () => seen++));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Stempel baru: Dompet pertama'), findsOneWidget);
    await tester.tap(find.text('Lihat'));
    expect(seen, 1);

    messenger
      ..clearSnackBars()
      ..showSnackBar(stampSnackBar(captured, ids: ['wallet_first', 'record_first'], onSee: () {}));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('2 stempel baru'), findsOneWidget);
  });

  testWidgets('lembar pengenalan: tutup dan Atur di Akun', (tester) async {
    var settings = 0;
    late BuildContext captured;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    var closed = false;
    unawaited(showFirstStampSheet(captured, id: 'wallet_first', onSettings: () => settings++).whenComplete(() => closed = true));
    await tester.pumpAndSettle();
    expect(find.text(t.stamps.firstSheet.title), findsOneWidget);
    await tester.tap(find.text(t.stamps.firstSheet.settings));
    await tester.pumpAndSettle();
    expect(settings, 1);
    expect(closed, isTrue);
  });

  test('slide banner pengguna lama: id, aksi, dan urutan di belakang pembaruan', () {
    var seen = 0;
    var dismissed = 0;
    final slide = legacyBannerSlide(onSee: () => seen++, onDismiss: () => dismissed++);
    expect(slide.id, legacyBannerStatusId);
    expect(slide.order, greaterThan(-3), reason: 'pembaruan (order -3) lebih dulu');
    slide.onAction!();
    slide.onDismiss!();
    expect([seen, dismissed], [1, 1]);
  });
}
