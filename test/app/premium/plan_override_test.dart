import 'package:di/di.dart' show GetIt;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/app/premium/debug_plan_page.dart';
import 'package:saldough/app/premium/plan_override.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/theme/theme.dart';

import '../../helpers/fake_entitlements.dart';

/// Pengganti paket untuk uji dan pengembangan (ADR-041 §3.10).
void main() {
  late InMemoryKeyValueStorage storage;

  setUp(() => storage = InMemoryKeyValueStorage());

  PlanOverrideController build({bool isRelease = false, String define = ''}) =>
      PlanOverrideController(
        storage: storage,
        isRelease: isRelease,
        define: define,
      );

  group('PlanOverrideController', () {
    test('tanpa define: otomatis', () {
      expect(build().value, PlanOverride.auto);
    });

    test(
      'define di build non-rilis menjadi nilai awal; nilai tak dikenal = otomatis',
      () {
        expect(build(define: 'plus').value, PlanOverride.plus);
        expect(build(define: 'trial').value, PlanOverride.trial);
        expect(build(define: 'free').value, PlanOverride.free);
        expect(build(define: 'gratis').value, PlanOverride.auto);
      },
    );

    test(
      'pilihan disimpan, menang atas define pada pembukaan berikutnya, dan memberi tahu pendengar',
      () async {
        final first = build(define: 'plus');
        var notified = 0;
        first.addListener(() => notified++);
        await first.select(PlanOverride.free);
        expect(first.value, PlanOverride.free);
        expect(notified, 1);

        final second = build(define: 'plus');
        expect(second.value, PlanOverride.plus);
        await second.load();
        expect(second.value, PlanOverride.free);
      },
    );

    test('memilih otomatis tersimpan dan mengalahkan define', () async {
      await build(define: 'plus').select(PlanOverride.auto);
      final next = build(define: 'plus');
      await next.load();
      expect(next.value, PlanOverride.auto);
    });

    test(
      'build rilis: define, pilihan tersimpan, dan select tidak berefek',
      () async {
        await build().select(PlanOverride.plus);
        final release = build(isRelease: true, define: 'plus');
        expect(release.value, PlanOverride.auto);
        await release.load();
        expect(
          release.value,
          PlanOverride.auto,
          reason: 'pilihan tersimpan diabaikan',
        );
        await release.select(PlanOverride.plus);
        expect(release.value, PlanOverride.auto);
      },
    );

    test('dokumen tersimpan rusak diabaikan', () async {
      await storage.write(
        'entitlement_debug_override',
        '{"schemaVersion":1,"value":"seumur-hidup"}',
      );
      final controller = build();
      await controller.load();
      expect(controller.value, PlanOverride.auto);
    });
  });

  group('DebugPlanRouteModule', () {
    test('non-rilis: satu rute dan satu entri menu pengembang', () {
      const module = DebugPlanRouteModule();
      expect(module.routes, hasLength(1));
      expect(module.devEntries.single.keyId, debugPlanRouteKey.id);
    });

    test('rilis: tanpa rute dan tanpa entri', () {
      const module = DebugPlanRouteModule(isRelease: true);
      expect(module.routes, isEmpty);
      expect(module.devEntries, isEmpty);
    });
  });

  testWidgets(
    'DebugPlanPage: memilih paket mengubah pengganti dan menampilkan paket berlaku',
    (tester) async {
      final controller = build();
      final entitlements = FakeEntitlements();
      final container = GetIt.asNewInstance()
        ..registerSingleton<PlanOverrideController>(controller)
        ..registerSingleton<Entitlements>(entitlements);
      await tester.pumpWidget(
        MaterialApp(
          theme: PixelTheme.light,
          home: DebugPlanPage(container: container),
        ),
      );

      expect(find.text('Berlaku: Gratis'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('plan-plus')));
      await tester.pump();
      expect(controller.value, PlanOverride.plus);

      entitlements.emit(const PlusPlan(source: PlanSource.override));
      await tester.pump();
      await tester.pump();
      expect(find.text('Berlaku: Plus (override)'), findsOneWidget);
    },
  );
}
