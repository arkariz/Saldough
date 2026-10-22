import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/data_portability/domain/backup_failure_codes.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';
import 'package:saldough/features/data_portability/presentation/bloc/restore_bloc.dart';
import 'package:saldough/features/data_portability/presentation/pages/restore_done_page.dart';
import 'package:saldough/features/data_portability/presentation/pages/restore_page.dart';
import 'package:state_management/state_management.dart';

import '../../helpers/fake_file_transfer.dart';
import '../../helpers/fake_restore_gateway.dart';

/// Halaman pulihkan (`Pulihkan.dc.html`): pratinjau, dialog, proses, galat.
void main() {
  late FakeRestoreGateway gateway;
  late List<bool> reboots;

  Future<RestoreBloc> pump(
    WidgetTester tester, {
    RestoreKind source = RestoreKind.account,
    Size size = const Size(360, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    reboots = [];
    final bloc = RestoreBloc(
      gateway: gateway,
      transfer: FakeFileTransfer(),
      reboot: ({required onboarding}) async => reboots.add(onboarding),
    )..add(RestoreStarted(bytes: source == RestoreKind.undo ? null : Uint8List.fromList([1]), source: source));
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: BlocProvider<RestoreBloc>.value(value: bloc, child: const RestorePage()),
      ),
    );
    await tester.pump();
    await tester.pump();
    return bloc;
  }

  setUp(() => gateway = FakeRestoreGateway());

  testWidgets('pratinjau: dua kolom (Cadangan dan Di ponsel ini), Lanjut dan Batal, tanpa banner atau perubahan', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text(t.dataPortability.restoreTitle), findsWidgets);
    expect(find.text(t.dataPortability.kickBackup), findsOneWidget);
    expect(find.text(t.dataPortability.kickNow), findsOneWidget);
    expect(find.text(t.dataPortability.nowLabel), findsOneWidget);
    expect(find.text('138 transaksi'), findsOneWidget);
    expect(find.text('142 transaksi'), findsOneWidget);
    expect(find.text(t.dataPortability.restoreUnchanged), findsOneWidget);
    expect(find.text(t.dataPortability.restoreChanges), findsNothing);
    expect(find.byType(AppBanner), findsNothing);
    expect(find.byKey(const ValueKey('restore-next')), findsOneWidget);
    expect(find.byKey(const ValueKey('restore-cancel')), findsOneWidget);
  });

  testWidgets('cadangan lebih lama: banner; mata uang berbeda dan draf hilang: bagian Yang akan berubah', (
    tester,
  ) async {
    gateway.preview = RestorePreview(
      source: RestoreKind.account,
      backup: gateway.preview.backup,
      backupCreatedAt: DateTime(2026, 10, 12),
      current: gateway.preview.current,
      isOlderThanCurrent: true,
      newCurrency: 'USD',
      lostInboxDrafts: 3,
    );
    await pump(tester);

    expect(find.byType(AppBanner), findsOneWidget);
    expect(find.textContaining('12 Okt 2026 akan hilang'), findsOneWidget);
    expect(find.text(t.dataPortability.restoreChanges), findsOneWidget);
    expect(find.text(t.dataPortability.changeCurrency(code: 'USD')), findsOneWidget);
    expect(find.text(t.dataPortability.changeDrafts(n: 3)), findsOneWidget);
  });

  testWidgets('Lanjut membuka dialog; Batal menutupnya tanpa menyiapkan apa pun', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('restore-next')));
    await tester.pumpAndSettle();

    expect(find.text(t.dataPortability.restoreConfirmTitle), findsOneWidget);
    expect(find.text(t.dataPortability.restoreConfirmBody), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(t.common.cancel)));
    await tester.pumpAndSettle();
    expect(find.text(t.dataPortability.restoreConfirmTitle), findsNothing);
    expect(gateway.staged, isEmpty);
    expect(reboots, isEmpty);
  });

  testWidgets('dialog untuk cadangan lebih lama menyebut catatan yang akan hilang', (tester) async {
    gateway.preview = RestorePreview(
      source: RestoreKind.account,
      backup: gateway.preview.backup,
      backupCreatedAt: DateTime(2026, 10, 12),
      current: gateway.preview.current,
      isOlderThanCurrent: true,
      newCurrency: null,
      lostInboxDrafts: 0,
    );
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('restore-next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('akan hilang dari ponsel ini'), findsWidgets);
  });

  testWidgets('Ganti data: daftar langkah dengan langkah 1 berjalan, lalu aplikasi dimulai ulang', (tester) async {
    final hold = gateway.holdStage = Completer<void>();
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('restore-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.dataPortability.restoreConfirmAction));
    await tester.pump();
    await tester.pump();

    expect(find.text(t.dataPortability.restoreRunTitle), findsOneWidget);
    for (final step in t.dataPortability.restoreSteps) {
      expect(find.text(step), findsOneWidget);
    }
    expect(find.text(t.dataPortability.restoreNoCancel), findsOneWidget);
    expect(find.byKey(const ValueKey('restore-next')), findsNothing, reason: 'tidak bisa dibatalkan');

    hold.complete();
    await tester.pump();
    await tester.pump();
    expect(gateway.staged, hasLength(1));
    expect(reboots, [false]);
  });

  testWidgets('galat berkas tidak bisa dipakai: Pilih berkas lain dan Tutup, datamu tidak berubah', (tester) async {
    gateway.inspectFailure = BackupFailureCodes.invalid;
    await pump(tester);
    expect(find.text(t.dataPortability.errorInvalidTitle), findsOneWidget);
    expect(find.text(t.dataPortability.errorInvalidBody), findsOneWidget);
    expect(find.byKey(const ValueKey('restore-other-file')), findsOneWidget);
    expect(find.byKey(const ValueKey('restore-close')), findsOneWidget);
  });

  testWidgets('galat versi lebih baru: tombol Perbarui aplikasi', (tester) async {
    gateway.inspectFailure = BackupFailureCodes.newer;
    await pump(tester);
    expect(find.text(t.dataPortability.errorNewerTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('restore-update')), findsOneWidget);
    expect(find.byKey(const ValueKey('restore-other-file')), findsNothing);
  });

  testWidgets('galat ruang penyimpanan penuh sesudah Ganti data', (tester) async {
    gateway.stageFailure = BackupFailureCodes.space;
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('restore-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.dataPortability.restoreConfirmAction));
    await tester.pump();
    await tester.pump();
    expect(find.text(t.dataPortability.errorSpaceTitle), findsOneWidget);
    expect(reboots, isEmpty);
  });

  testWidgets('Kembalikan: judul halaman dan penanda Cadangan pengaman', (tester) async {
    gateway.safety = SafetyCopyInfo(createdAt: DateTime(2026, 10, 22), expiresAt: DateTime(2026, 11, 21));
    await pump(tester, source: RestoreKind.undo);
    expect(find.text(t.dataPortability.undoPageTitle), findsOneWidget);
    expect(find.text(t.dataPortability.kickSafety), findsOneWidget);
  });

  testWidgets('muat di 360dp dengan teks 200% di pratinjau dan galat: tidak ada overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    gateway.preview = RestorePreview(
      source: RestoreKind.account,
      backup: gateway.preview.backup,
      backupCreatedAt: DateTime(2026, 10, 12),
      current: gateway.preview.current,
      isOlderThanCurrent: true,
      newCurrency: 'USD',
      lostInboxDrafts: 3,
    );
    await pump(tester);
    expect(tester.takeException(), isNull);
  });

  group('RestoreDonePage', () {
    Future<void> pumpDone(WidgetTester tester, RestoreReport report) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: PixelTheme.light,
          home: RestoreDonePage(report: report),
        ),
      );
      await tester.pump();
    }

    testWidgets('menyebut tanggal cadangan; catatan izin hanya bila cadangan memuat pengingat atau notifikasi', (
      tester,
    ) async {
      await pumpDone(
        tester,
        RestoreReport(
          kind: RestoreKind.account,
          backupCreatedAt: DateTime(2026, 10, 12),
          restoredKeys: const ['settings_recurring_reminders'],
        ),
      );
      expect(find.text(t.dataPortability.restoreDoneTitle(date: '12 Okt 2026')), findsOneWidget);
      expect(find.text(t.dataPortability.restoreDoneNote), findsOneWidget);
      expect(find.byKey(const ValueKey('restore-home')), findsOneWidget);
    });

    testWidgets('tanpa pengingat atau notifikasi: tanpa catatan izin; Kembalikan: judul tersendiri', (tester) async {
      await pumpDone(tester, RestoreReport(kind: RestoreKind.account, backupCreatedAt: DateTime(2026, 10, 12)));
      expect(find.text(t.dataPortability.restoreDoneNote), findsNothing);

      await pumpDone(tester, const RestoreReport(kind: RestoreKind.undo, backupCreatedAt: null));
      expect(find.text(t.dataPortability.undoDoneTitle), findsOneWidget);
    });
  });
}
