import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/data_portability/domain/file_transfer.dart';
import 'package:saldough/features/data_portability/presentation/bloc/backup_bloc.dart';
import 'package:saldough/features/data_portability/presentation/widgets/backup_sheet.dart';
import 'package:state_management/state_management.dart';

import '../../helpers/fake_backup_gateway.dart';
import '../../helpers/fake_file_transfer.dart';

/// Lembar cadangkan (prototipe `LembarCadangkan.dc.html`).
void main() {
  late FakeBackupGateway gateway;
  late FakeFileTransfer transfer;

  Future<BackupBloc> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    gateway = FakeBackupGateway();
    transfer = FakeFileTransfer();
    final bloc = BackupBloc(gateway: gateway, transfer: transfer)..add(const BackupStarted());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: BlocProvider<BackupBloc>.value(value: bloc, child: const BackupSheet()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return bloc;
  }

  testWidgets('form: ringkasan, daftar ikut dan tidak ikut, catatan, dan tombol Cadangkan', (tester) async {
    await pump(tester);

    expect(find.text(t.dataPortability.backupTitle), findsOneWidget);
    expect(find.textContaining('142 transaksi, 4 dompet, sejak 3'), findsOneWidget);
    expect(find.text(t.dataPortability.backupIncluded), findsOneWidget);
    expect(find.text(t.dataPortability.backupExcluded), findsOneWidget);
    for (final item in [...t.dataPortability.backupIn, ...t.dataPortability.backupOut]) {
      expect(find.text(item), findsOneWidget);
    }
    expect(find.text(t.dataPortability.backupHint), findsOneWidget);
    expect(find.byKey(const ValueKey('backup-go')), findsOneWidget);
  });

  testWidgets('Cadangkan → siap → Simpan ke… menyimpan dan mencatat Cadangan terakhir', (tester) async {
    final bloc = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('backup-go')));
    await tester.pump();
    await tester.pump();

    expect(find.text(t.dataPortability.backupReady), findsOneWidget);
    expect(find.text('tanukonomy-cadangan-2026-10-22.tkbak'), findsOneWidget);
    expect(find.text('142 transaksi · 4 dompet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('backup-save')));
    await tester.pump();
    await tester.pump();
    expect(transfer.saved, hasLength(1));
    expect(gateway.recorded, 1);
    expect(bloc.state.finished, isTrue);
  });

  testWidgets('lembar simpan ditutup: catatan "Belum tersimpan" tampil dan status tidak dicatat', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('backup-go')));
    await tester.pump();
    await tester.pump();
    transfer.saveOutcome = TransferOutcome.cancelled;

    await tester.tap(find.byKey(const ValueKey('backup-save')));
    await tester.pump();
    await tester.pump();
    expect(find.text(t.dataPortability.backupNotSaved), findsOneWidget);
    expect(gateway.recorded, 0);
  });

  testWidgets('muat di 360dp dengan teks 200% di setiap tahap: tidak ada overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester);
    expect(tester.takeException(), isNull, reason: 'tahap form');
    await tester.ensureVisible(find.byKey(const ValueKey('backup-go')));
    await tester.tap(find.byKey(const ValueKey('backup-go')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('backup-save')), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'tahap siap');
  });
}
