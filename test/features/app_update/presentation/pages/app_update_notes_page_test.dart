import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/navigation/app_update_route_keys.dart';

import '../../../../helpers/routes.dart';
import '../../../../helpers/update_harness.dart';

/// Layar "Apa yang baru" dengan tindakan pembaruan (APP_UPDATE F4, §7).
void main() {
  setUpAll(() => registerFallbackValue(AppUpdateMemory.empty));

  late UpdateHarness harness;
  late GetIt container;

  setUp(() => harness = UpdateHarness());
  tearDown(() async => harness.dispose());

  Future<void> open(WidgetTester tester) async {
    container = GetIt.asNewInstance()..registerSingleton<RouteRegistry>(appRouteRegistry());
    harness.register(container);
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          theme: PixelTheme.light,
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.pushRoute(AppUpdateRouteKeys.notes, const EmptyInput()),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    // Keadaan sudah dibaca (Akun memicunya sebelum layar ini terbuka).
    // Bloc dibuat malas di zona ini; baca sekali lalu buka layarnya.
    container<AppUpdateBloc>().add(const AppUpdateChecked(force: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  const downloaded = StoreUpdateInfo(stage: StoreUpdateStage.downloaded, availableBuild: 8);

  testWidgets('terbaru: hanya keadaan kosong catatan', (tester) async {
    await open(tester);
    expect(find.text(t.account.version.label), findsOneWidget);
    expect(find.text('0.6.0 (7)'), findsOneWidget);
    expect(find.text(t.account.version.statusLatest), findsOneWidget);
    expect(find.text(t.appUpdate.whatsNew.titlePatch), findsOneWidget);
    expect(find.text(t.appUpdate.whatsNew.empty), findsOneWidget);
    expect(find.text(t.appUpdate.action.update), findsNothing);
    expect(find.text(t.appUpdate.action.install), findsNothing);
  });

  testWidgets('tersedia: Perbarui memulai unduhan', (tester) async {
    harness.set(play: const StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 8));
    await open(tester);
    expect(find.text(t.account.version.statusAvailable), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('app-update-notes-update')));
    await tester.pumpAndSettle();
    verify(() => harness.store.startDownload()).called(1);
  });

  testWidgets('sesudah Nanti di Beranda, tombol Perbarui tetap tersedia di sini', (tester) async {
    harness.set(play: const StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 8));
    container = GetIt.asNewInstance()..registerSingleton<RouteRegistry>(appRouteRegistry());
    harness.register(container);
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          theme: PixelTheme.light,
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.pushRoute(AppUpdateRouteKeys.notes, const EmptyInput()),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    final bloc = container<AppUpdateBloc>()..add(const AppUpdateChecked(force: true));
    await tester.pumpAndSettle();
    bloc.add(const AppUpdateDeferred());
    await tester.pumpAndSettle();
    expect(bloc.state.announcement.name, 'none', reason: 'banner Beranda tertunda');

    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(find.text(t.appUpdate.action.update), findsOneWidget);
  });

  testWidgets('mengunduh: pesan tanpa tombol', (tester) async {
    harness.set(play: const StoreUpdateInfo(stage: StoreUpdateStage.downloading, availableBuild: 8));
    await open(tester);
    expect(find.text(t.account.version.statusDownloading), findsOneWidget);
    expect(find.text(t.appUpdate.action.update), findsNothing);
    expect(find.text(t.appUpdate.action.install), findsNothing);
  });

  testWidgets('sudah diunduh: Pasang sekarang hanya jalan saat diketuk (B-7)', (tester) async {
    harness.set(play: downloaded);
    await open(tester);
    verifyNever(() => harness.store.completeInstall());
    await tester.tap(find.byKey(const ValueKey('app-update-notes-install')));
    await tester.pumpAndSettle();
    verify(() => harness.store.completeInstall()).called(1);
  });

  testWidgets('pembaruan kecil siap: petunjuk buka ulang, tanpa tombol', (tester) async {
    harness.set(patchState: const PatchState(next: 1));
    await open(tester);
    expect(find.text(t.account.version.statusPatchReady), findsOneWidget);
    expect(find.text(t.appUpdate.action.ok), findsNothing);
  });
}
