import 'package:di/di.dart' show GetIt;
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/features/notification_capture/di/notification_capture_module.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';

import '../../../helpers/fake_notification_capture_gateway.dart';

/// Fitur Catat dari notifikasi dinonaktifkan sementara di tingkat build
/// (24 Okt 2026): tanpa `--dart-define=NOTIFICATION_CAPTURE=true` gateway tidak
/// didukung, sehingga pemroses, kotak masuk, banner, dan status penemuan tidur.
void main() {
  test('build bawaan: fitur tidak termasuk dan pintu disembunyikan', () {
    expect(NotificationCaptureAvailability.compiledIn, isFalse);
  });

  test('tanpa gateway dan fitur tidak termasuk: gateway tidak didukung', () {
    final container = GetIt.asNewInstance();
    NotificationCaptureModule.register(container);
    expect(container<NotificationCaptureGateway>().isSupported, isFalse);
  });

  test('gateway uji tetap dipakai apa adanya', () {
    final container = GetIt.asNewInstance();
    final gateway = FakeNotificationCaptureGateway();
    NotificationCaptureModule.register(container, gateway: gateway);
    expect(container<NotificationCaptureGateway>(), same(gateway));
  });
}
