import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';

void main() {
  group('remindsWhenClosed (ADR-044 §3.5)', () {
    test('bawaan: nyala hanya untuk Plus', () {
      const settings = NotificationCaptureSettings();

      expect(settings.delivery, NotificationDelivery.automatic);
      expect(settings.remindsWhenClosed(isPlus: true), isTrue);
      expect(settings.remindsWhenClosed(isPlus: false), isFalse);
    });

    test('dinyalakan pengguna: nyala untuk semua; dimatikan pengguna: mati untuk semua, termasuk Plus', () {
      const on = NotificationCaptureSettings(delivery: NotificationDelivery.reminderAndInbox);
      const off = NotificationCaptureSettings(delivery: NotificationDelivery.inboxOnly);

      expect(on.remindsWhenClosed(isPlus: false), isTrue);
      expect(off.remindsWhenClosed(isPlus: true), isFalse);
    });
  });

  group('penyimpanan', () {
    test('setelan lama yang menyimpan "tinjau di kotak masuk" tetap mati (pilihan eksplisit)', () async {
      final storage = InMemoryKeyValueStorage();
      final store = NotificationCaptureStoreImpl(storage: storage);
      await store.saveSettings(const NotificationCaptureSettings(delivery: NotificationDelivery.inboxOnly));

      final loaded = (await store.loadSettings()).getOrElse((_) => throw StateError(''));

      expect(loaded.delivery, NotificationDelivery.inboxOnly);
    });

    test('bawaan tersimpan dan terbaca sebagai otomatis; nilai asing jatuh ke otomatis', () async {
      final storage = InMemoryKeyValueStorage();
      final store = NotificationCaptureStoreImpl(storage: storage);
      await store.saveSettings(const NotificationCaptureSettings());

      expect(
        (await store.loadSettings()).getOrElse((_) => throw StateError('')).delivery,
        NotificationDelivery.automatic,
      );
    });
  });
}
