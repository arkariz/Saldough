import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/features/data_portability/data/export_service.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/export_data.dart';
import 'package:saldough/features/data_portability/domain/file_transfer.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';
import 'package:saldough/features/data_portability/presentation/bloc/backup_bloc.dart';
import 'package:saldough/features/data_portability/presentation/bloc/backup_state.dart';
import 'package:saldough/features/data_portability/presentation/bloc/export_bloc.dart';
import 'package:saldough/features/data_portability/presentation/bloc/export_state.dart';
import 'package:saldough/features/data_portability/presentation/bloc/restore_bloc.dart';
import 'package:saldough/features/data_portability/presentation/bloc/restore_state.dart';

import '../../helpers/export_fixtures.dart';
import '../../helpers/fake_backup_gateway.dart';
import '../../helpers/fake_file_transfer.dart';
import '../../helpers/fake_restore_gateway.dart';

class _Source implements ExportDataSource {
  @override
  Future<Either<Failure, ExportData>> load() async => right(sampleExportData());
}

/// Peristiwa analitik ekspor, cadangan, dan pemulihan (EXPORT_BACKUP §12):
/// hanya jenis dan ember jumlah baris, tanpa nominal, nama, atau isi data.
void main() {
  late List<AnalyticsEvent> events;

  setUp(() {
    events = [];
    AppAnalytics.debugSink = events.add;
  });

  tearDown(() => AppAnalytics.debugSink = null);

  test('rows_bucket: batas tiap ember', () {
    expect(
      [
        0,
        99,
        100,
        999,
        1000,
        9999,
        10000,
        250000,
      ].map(DataPortabilityEvents.rowsBucket),
      [
        '<100',
        '<100',
        '<1000',
        '<1000',
        '<10000',
        '<10000',
        '10000+',
        '10000+',
      ],
    );
  });

  test(
    'ekspor: export_created dengan format dan ember, tanpa data lain',
    () async {
      final bloc = ExportBloc(
        service: ExportService(
          source: _Source(),
          labels: () => idLabels,
          now: () => DateTime(2026, 10, 22),
        ),
        transfer: FakeFileTransfer(),
      )..add(const ExportStarted());
      addTearDown(bloc.close);
      await bloc.stream.firstWhere((s) => s.phase == ExportPhase.form);
      bloc.add(const ExportRequested());
      await bloc.stream.firstWhere((s) => s.phase == ExportPhase.ready);

      expect(events, [
        const AnalyticsEvent('export_created', {
          'format': 'xlsx',
          'rows_bucket': '<100',
        }),
      ]);
    },
  );

  group('cadangan', () {
    late FakeFileTransfer transfer;
    late BackupBloc bloc;

    setUp(() async {
      transfer = FakeFileTransfer();
      bloc = BackupBloc(gateway: FakeBackupGateway(), transfer: transfer)
        ..add(const BackupStarted());
      addTearDown(bloc.close);
      await bloc.stream.firstWhere((s) => s.phase == BackupPhase.form);
      bloc.add(const BackupRequested());
      await bloc.stream.firstWhere((s) => s.phase == BackupPhase.ready);
    });

    test('dibuat tapi belum disimpan: belum ada peristiwa', () {
      expect(events, isEmpty);
    });

    test('Simpan terkonfirmasi: saved true', () async {
      bloc.add(const BackupSaveRequested());
      await bloc.stream.firstWhere((s) => s.finished);
      expect(events, [
        const AnalyticsEvent('backup_created', {
          'rows_bucket': '<1000',
          'saved': true,
        }),
      ]);
    });

    test('dibatalkan atau tak terkonfirmasi: saved false', () async {
      transfer.saveOutcome = TransferOutcome.cancelled;
      bloc.add(const BackupSaveRequested());
      await bloc.stream.firstWhere((s) => s.notSaved);
      transfer.shareOutcome = TransferOutcome.unconfirmed;
      bloc.add(const BackupShareRequested());
      await bloc.stream.firstWhere((s) => s.finished);
      expect(events.map((e) => e.parameters['saved']), [false, false]);
    });
  });

  group('pulihkan', () {
    late FakeRestoreGateway gateway;

    setUp(() => gateway = FakeRestoreGateway());

    RestoreBloc build(RestoreKind source) {
      final bloc = RestoreBloc(
        gateway: gateway,
        transfer: FakeFileTransfer(),
        reboot: ({required onboarding}) async {},
      )..add(RestoreStarted(bytes: Uint8List.fromList([1]), source: source));
      addTearDown(bloc.close);
      return bloc;
    }

    test('dikonfirmasi: restore_started dengan asalnya', () async {
      final bloc = build(RestoreKind.onboarding);
      await bloc.stream.firstWhere((s) => s.phase == RestorePhase.preview);
      expect(events, isEmpty, reason: 'pratinjau saja belum memulai pemulihan');
      bloc.add(const RestoreConfirmed());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(events, [
        const AnalyticsEvent('restore_started', {'surface': 'onboarding'}),
      ]);
    });

    test('berkas ditolak: restore_failed dengan alasan tiap kode', () async {
      for (final (code, reason) in [
        (BackupFailureCodes.invalid, 'invalid'),
        (BackupFailureCodes.newer, 'newer'),
        (BackupFailureCodes.inconsistent, 'inconsistent'),
        (BackupFailureCodes.space, 'space'),
        (const FailureCode('LAIN'), 'other'),
      ]) {
        events.clear();
        gateway.inspectFailure = code;
        final bloc = build(RestoreKind.account);
        await bloc.stream.firstWhere((s) => s.phase == RestorePhase.error);
        expect(events, [
          AnalyticsEvent('restore_failed', {
            'surface': 'account',
            'reason': reason,
          }),
        ], reason: '$code');
      }
    });

    test('penyiapan gagal sesudah dikonfirmasi: started lalu failed', () async {
      gateway.stageFailure = BackupFailureCodes.space;
      final bloc = build(RestoreKind.account);
      await bloc.stream.firstWhere((s) => s.phase == RestorePhase.preview);
      bloc.add(const RestoreConfirmed());
      await bloc.stream.firstWhere((s) => s.phase == RestorePhase.error);
      expect(events.map((e) => e.name), ['restore_started', 'restore_failed']);
      expect(events.last.parameters['reason'], 'space');
    });
  });
}
