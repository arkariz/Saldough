import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/fake_notification_capture_gateway.dart';

/// ADR-042: ikat pola ke rutin (§3.4) dan penyimpanan contoh notifikasi (§3.2).
void main() {
  late InMemoryKeyValueStorage storage;
  late FakeNotificationCaptureGateway gateway;
  late RecurringRuleRepositoryImpl rules;
  late NotificationSettingsBloc bloc;

  RecurringRule rule(String id) => RecurringRule(
    id: id,
    kind: RecurringKind.expense,
    amount: 5000000,
    walletId: 'bri',
    note: id,
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9, 29)),
  );

  Future<RecurringRule> stored(String id) async =>
      (await rules.listRules()).getOrElse((_) => []).firstWhere((r) => r.id == id);

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    gateway = FakeNotificationCaptureGateway();
    rules = RecurringRuleRepositoryImpl(storage: storage);
    await rules.saveRule(rule('netflix'));
    await rules.saveRule(rule('spotify'));
    bloc = NotificationSettingsBloc(
      gateway: gateway,
      store: NotificationCaptureStoreImpl(storage: storage),
      walletRepository: WalletRepositoryImpl(storage: storage),
      recurringRules: rules,
    );
    addTearDown(bloc.close);
  });

  NotificationPatternBound bind(
    String? ruleId, {
    String patternId = 'p1',
    NotificationPatternKind kind = NotificationPatternKind.expense,
  }) => NotificationPatternBound(
    packageName: 'com.jago',
    patternId: patternId,
    patternLabel: 'Langganan',
    patternKind: kind,
    ruleId: ruleId,
  );

  group('ikat pola ke rutin', () {
    test('mengikat menyimpan ikatan di rutin', () async {
      bloc.add(bind('netflix'));
      await pumpEventQueue();
      expect((await stored('netflix')).notificationBinding?.patternId, 'p1');
      expect((await stored('spotify')).notificationBinding, isNull);
    });

    test('satu pola hanya ke satu rutin: mengikat ulang memindahkan ikatan', () async {
      bloc.add(bind('netflix'));
      await pumpEventQueue();
      bloc.add(bind('spotify'));
      await pumpEventQueue();
      expect((await stored('netflix')).notificationBinding, isNull);
      expect((await stored('spotify')).notificationBinding?.patternId, 'p1');
    });

    test('satu rutin hanya satu pola: mengikat pola lain menggantikan', () async {
      bloc.add(bind('netflix'));
      await pumpEventQueue();
      bloc.add(bind('netflix', patternId: 'p2'));
      await pumpEventQueue();
      expect((await stored('netflix')).notificationBinding?.patternId, 'p2');
    });

    test('jenis beda ditolak: pola pengeluaran tidak bisa diikat ke rutin pemasukan (F23-6)', () async {
      await rules.saveRule(
        RecurringRule(
          id: 'gaji',
          kind: RecurringKind.income,
          amount: 100000000,
          walletId: 'bri',
          note: 'Gaji',
          schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9, 25)),
        ),
      );
      bloc.add(bind('gaji'));
      await pumpEventQueue();
      expect((await stored('gaji')).notificationBinding, isNull);
      bloc.add(bind('gaji', kind: NotificationPatternKind.income));
      await pumpEventQueue();
      expect((await stored('gaji')).notificationBinding?.patternId, 'p1');
    });

    test('pola transfer hanya ke rutin transfer', () {
      expect(NotificationPatternKind.transferBetween.recurringKind, RecurringKind.transfer);
      expect(NotificationPatternKind.transferOut.recurringKind, RecurringKind.transfer);
      expect(NotificationPatternKind.income.recurringKind, RecurringKind.income);
    });

    test('Tidak terikat melepas ikatan pola', () async {
      bloc.add(bind('netflix'));
      await pumpEventQueue();
      bloc.add(bind(null));
      await pumpEventQueue();
      expect((await stored('netflix')).notificationBinding, isNull);
    });
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
