import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/data_portability/data/export_service.dart';
import 'package:saldough/features/data_portability/domain/export_data.dart';
import 'package:saldough/features/data_portability/domain/file_transfer.dart';
import 'package:saldough/features/data_portability/presentation/bloc/export_bloc.dart';
import 'package:saldough/features/data_portability/presentation/bloc/export_state.dart';
import 'package:saldough/features/data_portability/presentation/widgets/export_sheet.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:state_management/state_management.dart';

import '../../helpers/export_fixtures.dart';
import '../../helpers/fake_file_transfer.dart';

class _Source implements ExportDataSource {
  _Source(this.data);

  final ExportData data;

  @override
  Future<Either<Failure, ExportData>> load() async => right(data);
}

/// Lembar ekspor (prototipe `LembarEkspor.dc.html`): form → proses → berkas siap.
void main() {
  late FakeFileTransfer transfer;

  // Berkas dibangun di isolate: hasilnya baru masuk ke zona FakeAsync sesudah
  // `pump`, jadi tunggu waktu nyata lalu pump, berulang sampai siap.
  Future<void> untilReady(WidgetTester tester, ExportBloc bloc) async {
    for (var i = 0; i < 200 && bloc.state.phase != ExportPhase.ready; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
      await tester.pump();
    }
    expect(bloc.state.phase, ExportPhase.ready);
  }

  Future<ExportBloc> pump(WidgetTester tester, ExportData data, {Size size = const Size(360, 800)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    transfer = FakeFileTransfer();
    final bloc = ExportBloc(
      service: ExportService(source: _Source(data), labels: () => idLabels, now: () => DateTime(2026, 10, 22)),
      transfer: transfer,
    )..add(const ExportStarted());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: BlocProvider<ExportBloc>.value(
            value: bloc,
            child: const SingleChildScrollView(child: ExportSheet()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return bloc;
  }

  testWidgets('form: format xlsx terpilih, ringkasan, catatan cakupan, dan tombol Ekspor', (tester) async {
    await pump(tester, sampleExportData());

    expect(find.text(t.dataPortability.exportTitle), findsOneWidget);
    expect(find.text(t.dataPortability.xlsxHelp), findsOneWidget);
    expect(find.textContaining('3 transaksi'), findsOneWidget, reason: 'ringkasan jumlah dan rentang tanggal');
    expect(find.text(t.dataPortability.exportScope), findsOneWidget);
    expect(tester.widget<AppButton>(find.byKey(const ValueKey('export-go'))).onPressed, isNotNull);
  });

  testWidgets('semua transaksi di satu hari: satu tanggal saja, bukan rentang', (tester) async {
    await pump(
      tester,
      sampleExportData(
        transactions: [
          ExpenseTransaction(id: 'a', date: DateTime(2026, 10, 22, 9), amount: 100, note: '', walletId: 'bca'),
        ],
      ),
    );
    expect(find.textContaining('1 transaksi, 22'), findsOneWidget);
    expect(find.textContaining('–'), findsNothing);
  });

  testWidgets('memilih CSV mengganti keterangan format', (tester) async {
    await pump(tester, sampleExportData());
    await tester.tap(find.text(t.dataPortability.formatCsv));
    await tester.pump();
    expect(find.text(t.dataPortability.csvHelp), findsOneWidget);
    expect(find.text(t.dataPortability.xlsxHelp), findsNothing);
  });

  testWidgets('belum ada transaksi: pesan kosong, tanpa catatan cakupan, dan Ekspor nonaktif', (tester) async {
    await pump(tester, sampleExportData(transactions: const []));
    expect(find.text(t.dataPortability.exportEmpty), findsOneWidget);
    expect(find.text(t.dataPortability.exportScope), findsNothing);
    expect(tester.widget<AppButton>(find.byKey(const ValueKey('export-go'))).onPressed, isNull);
  });

  testWidgets('Ekspor → berkas siap → Simpan ke… menyimpan dan menutup lembar', (tester) async {
    final bloc = await pump(tester, sampleExportData());

    await tester.tap(find.byKey(const ValueKey('export-go')));
    await tester.pump();
    expect(find.text(t.dataPortability.exportBusy), findsOneWidget);
    expect(find.byKey(const ValueKey('export-cancel')), findsOneWidget);

    await untilReady(tester, bloc);
    expect(find.text(t.dataPortability.fileReady), findsOneWidget);
    expect(find.text('tanukonomy-ekspor-2026-10-22.xlsx'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('export-save')));
    await tester.pump();
    await tester.pump();
    expect(transfer.saved, ['tanukonomy-ekspor-2026-10-22.xlsx']);
    expect(bloc.state.finished, isTrue);
  });

  testWidgets('tombol Bagikan membagikan berkas', (tester) async {
    final bloc = await pump(tester, sampleExportData());
    await tester.tap(find.byKey(const ValueKey('export-go')));
    await tester.pump();
    await untilReady(tester, bloc);

    await tester.tap(find.byKey(const ValueKey('export-share')));
    await tester.pump();
    await tester.pump();
    expect(transfer.shared, hasLength(1));
  });

  testWidgets('lembar simpan ditutup tanpa menyimpan: catatan "belum disimpan" tampil dan lembar tetap terbuka', (
    tester,
  ) async {
    final bloc = await pump(tester, sampleExportData());
    await tester.tap(find.byKey(const ValueKey('export-go')));
    await tester.pump();
    await untilReady(tester, bloc);
    transfer.saveOutcome = TransferOutcome.cancelled;

    await tester.tap(find.byKey(const ValueKey('export-save')));
    await tester.pump();
    await tester.pump();
    expect(find.text(t.dataPortability.fileNotSaved), findsOneWidget);
    expect(find.byKey(const ValueKey('export-save')), findsOneWidget);
  });

  testWidgets('muat di 360dp dengan teks 200%: tidak ada overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final bloc = await pump(tester, sampleExportData());
    await tester.ensureVisible(find.byKey(const ValueKey('export-go')));
    await tester.tap(find.byKey(const ValueKey('export-go')));
    await tester.pump();
    await untilReady(tester, bloc);
    expect(tester.takeException(), isNull, reason: 'tidak ada overflow di 360dp dengan teks 200%');
  });
}
