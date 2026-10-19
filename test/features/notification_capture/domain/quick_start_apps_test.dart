import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/services/quick_start_apps.dart';

void main() {
  const gopay = InstalledApp(packageName: 'com.gojek.gopay', label: 'GoPay');
  const bri = InstalledApp(packageName: 'id.co.bri.brimo', label: 'BRImo');
  const calculator = InstalledApp(packageName: 'com.android.calculator2', label: 'Kalkulator');

  group('quickStartApps', () {
    test('hanya aplikasi dengan pola bawaan, urut nama', () {
      expect(quickStartApps([gopay, calculator, bri]), [bri, gopay]);
    });

    test('tanpa aplikasi bawaan terpasang, daftar kosong', () {
      expect(quickStartApps([calculator]), isEmpty);
      expect(quickStartApps(const []), isEmpty);
    });
  });

  group('quickStartSource', () {
    test('memakai filter bawaan dan menyala', () {
      final source = quickStartSource(bri);

      expect(source.packageName, 'id.co.bri.brimo');
      expect(source.appLabel, 'BRImo');
      expect(source.keywords, defaultNotificationKeywords);
      expect(source.enabled, isTrue);
    });
  });

  group('mergeQuickStartSources', () {
    test('sumber baru ditambahkan di akhir', () {
      final merged = mergeQuickStartSources([quickStartSource(bri)], [quickStartSource(gopay)]);

      expect(merged.map((s) => s.packageName), ['id.co.bri.brimo', 'com.gojek.gopay']);
    });

    test('sumber yang sudah ada dipertahankan lengkap dengan filter dan dompetnya', () {
      const custom = NotificationSource(
        packageName: 'id.co.bri.brimo',
        appLabel: 'BRImo',
        keywords: ['kata saya'],
        walletId: 'w1',
      );

      final merged = mergeQuickStartSources([custom], [quickStartSource(bri)]);

      expect(merged, [custom]);
    });

    test('sumber yang dinonaktifkan dinyalakan lagi tanpa kehilangan filter dan dompet', () {
      const off = NotificationSource(
        packageName: 'id.co.bri.brimo',
        appLabel: 'BRImo',
        keywords: ['kata saya'],
        walletId: 'w1',
        enabled: false,
      );

      final merged = mergeQuickStartSources([off], [quickStartSource(bri)]);

      expect(merged.single.enabled, isTrue);
      expect(merged.single.keywords, ['kata saya']);
      expect(merged.single.walletId, 'w1');
    });
  });
}
