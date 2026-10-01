import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/foundation/navigation/app_route_registry.dart';

import '../helpers/routes.dart';

/// Registri rute aplikasi (ADR-0004, ADR-030 §3.3): semua modul fitur
/// terdaftar, kuncinya unik, dan `go_router` menerima konfigurasinya.
void main() {
  test('setiap kunci rute fitur terdaftar sekali', () {
    expect(appRouteRegistry().registeredKeys.toSet(), {
      'account.page',
      'budget.detail',
      'freelance.overview',
      'record.sheet',
      'record.edit',
      'record.voice',
      'notificationCapture.settings',
      'notificationCapture.inbox',
      'transaction.detail',
      'transaction.history',
      'wallet.detail',
    });
  });

  test('GoRouter aplikasi dibangun dengan seluruh rute bernama', () {
    final router = AppRouteRegistry.build(
      registry: appRouteRegistry(),
      initialLocation: AppRouteRegistry.homePath,
      homeBuilder: (_, _) => const SizedBox(),
      onboardingBuilder: (_, _) => const SizedBox(),
    );
    addTearDown(router.dispose);

    for (final key in appRouteRegistry().registeredKeys) {
      expect(router.namedLocation(key), '/${key.replaceAll('.', '/')}');
    }
  });
}
