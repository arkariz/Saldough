import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/fake_notification_capture_gateway.dart';

/// ADR-042 §3.2: penyimpanan contoh notifikasi.
void main() {
  late InMemoryKeyValueStorage storage;
  late FakeNotificationCaptureGateway gateway;
  late NotificationSettingsBloc bloc;

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    gateway = FakeNotificationCaptureGateway();
    bloc = NotificationSettingsBloc(
      gateway: gateway,
      store: NotificationCaptureStoreImpl(storage: storage),
      walletRepository: WalletRepositoryImpl(storage: storage),
    );
    addTearDown(bloc.close);
  });

  group('contoh notifikasi', () {
    test('menyalakan tersimpan di setelan dan diteruskan ke native', () async {
      bloc.add(const NotificationSamplesToggled(on: true));
      await pumpEventQueue();
      expect(bloc.state.settings.saveSamples, isTrue);
      expect(gateway.configuredSaveSamples, isTrue);
    });

    test('menyalakan lalu langsung memuat contoh: setelan tidak tertimpa (F23-5)', () async {
      gateway.sampleStore = {
        'com.jago': [
          CapturedNotification(id: '1', packageName: 'com.jago', title: 't', body: 'b', postedAt: DateTime(2026, 10)),
        ],
      };
      bloc
        ..add(const NotificationSamplesToggled(on: true))
        ..add(const NotificationSamplesRequested('com.jago'));
      await pumpEventQueue();
      expect(bloc.state.settings.saveSamples, isTrue);
      expect(bloc.state.samples, hasLength(1));
    });

    test('mematikan menghapus semua contoh', () async {
      bloc.add(const NotificationSamplesToggled(on: true));
      await pumpEventQueue();
      gateway.sampleStore = {
        'com.jago': [
          CapturedNotification(id: '1', packageName: 'com.jago', title: 't', body: 'b', postedAt: DateTime(2026, 10)),
        ],
      };
      bloc.add(const NotificationSamplesRequested('com.jago'));
      await pumpEventQueue();
      expect(bloc.state.samples, hasLength(1));

      bloc.add(const NotificationSamplesToggled(on: false));
      await pumpEventQueue();
      expect(bloc.state.settings.saveSamples, isFalse);
      expect(bloc.state.samples, isEmpty);
      expect(gateway.clearedSamples, 1);
    });

    test('menghapus sumber menghapus contohnya', () async {
      bloc.add(const NotificationSourceRemoved('com.jago'));
      await pumpEventQueue();
      expect(gateway.clearedSamples, 1);
    });
  });
}
