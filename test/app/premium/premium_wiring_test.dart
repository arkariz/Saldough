import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart' show GetIt;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/app/premium/premium_wiring.dart';
import 'package:saldough/features/premium/data/revenuecat_plan_source.dart';

/// Sumber RevenueCat hanya ada di Android dengan kunci (ADR-041 §3.5, P-6).
void main() {
  GetIt container({
    String key = 'goog_xxx',
    TargetPlatform platform = TargetPlatform.android,
  }) {
    final c = GetIt.asNewInstance()
      ..registerSingleton<KeyValueStorage>(InMemoryKeyValueStorage());
    registerEntitlements(c, revenueCatKey: key, platform: platform);
    return c;
  }

  test('Android dengan kunci: sumber terdaftar', () {
    expect(container().isRegistered<RevenueCatPlanSource>(), isTrue);
  });

  test('tanpa kunci: tidak ada sumber RevenueCat', () {
    expect(container(key: '').isRegistered<RevenueCatPlanSource>(), isFalse);
  });

  test('bukan Android (iOS belum didukung): tidak ada sumber', () {
    expect(
      container(
        platform: TargetPlatform.iOS,
      ).isRegistered<RevenueCatPlanSource>(),
      isFalse,
    );
  });
}
