import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// PlusBadge dan PlusLocked (T-24.17b).
void main() {
  setUp(() => addTearDown(ActivePlan.reset));

  Future<void> pump(WidgetTester tester, Widget child, {double scale = 1}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: c!,
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  group('PlusBadge', () {
    testWidgets('Gratis: tampil; Plus: hilang saat paket berubah', (tester) async {
      await pump(tester, const PlusBadge());
      expect(find.text(t.premium.plusBadge), findsOneWidget);
      ActivePlan.notifier.value = const PlusPlan(source: PlanSource.purchase);
      await tester.pump();
      expect(find.text(t.premium.plusBadge), findsNothing);
    });

    testWidgets('syarat when: tidak tampil bila batas belum tercapai', (tester) async {
      await pump(tester, PlusBadge(when: () => false));
      expect(find.text(t.premium.plusBadge), findsNothing);
    });

    testWidgets('di tombol: lencana di sisi label, tombol tetap bisa diketuk', (tester) async {
      var taps = 0;
      await pump(tester, AppButton.secondary(label: 'Template baru', onPressed: () => taps++, badge: const PlusBadge()));
      expect(find.text(t.premium.plusBadge), findsOneWidget);
      await tester.tap(find.text('Template baru'));
      expect(taps, 1);
    });
  });

  group('PlusLocked', () {
    Widget locked({VoidCallback? onSee, VoidCallback? onFree}) => PlusLocked(
      preview: const Text('DATA ASLI'),
      title: 'Judul batas',
      text: 'Yang tetap gratis.',
      freeLabel: 'Jalan gratis',
      onSee: onSee ?? () {},
      onFree: onFree ?? () {},
    );

    testWidgets('kartu memuat lencana, judul, kalimat, dan dua tombol; pratinjau tak terbaca pembaca layar', (
      tester,
    ) async {
      var see = 0;
      var free = 0;
      await pump(tester, locked(onSee: () => see++, onFree: () => free++));
      expect(find.text('Judul batas'), findsOneWidget);
      expect(find.text('Yang tetap gratis.'), findsOneWidget);
      expect(find.text(t.premium.plusBadge), findsOneWidget);
      expect(find.text('DATA ASLI', skipOffstage: false), findsOneWidget);
      expect(find.bySemanticsLabel('DATA ASLI'), findsNothing);
      await tester.tap(find.text(t.premium.seePlus));
      await tester.tap(find.text('Jalan gratis'));
      expect(see, 1);
      expect(free, 1);
    });

    testWidgets('360dp teks 200%: tanpa overflow', (tester) async {
      await pump(tester, locked(), scale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
