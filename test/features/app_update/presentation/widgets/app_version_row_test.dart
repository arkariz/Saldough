import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/account/presentation/navigation/account_route_keys.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/category/category.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/routes.dart';
import '../../../../helpers/update_harness.dart';

/// Baris Versi aplikasi di Akun (APP_UPDATE F4, B-5; ADR-039).
void main() {
  setUpAll(() async {
    registerEffectHandlers();
    await (FontLoader('PlusJakartaSans')..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'))).load();
    registerFallbackValue(AppUpdateMemory.empty);
  });

  late UpdateHarness harness;

  setUp(() => harness = UpdateHarness());

  tearDown(() async {
    await harness.dispose();
    LocaleSettings.setLocaleSync(AppLocale.id);
  });

  GetIt rootContainer({bool withUpdate = true}) {
    final container = GetIt.asNewInstance()
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
      ..registerSingleton<AuthRepository>(FakeAuthRepository())
      ..registerSingleton<CurrencyPreferenceRepository>(
        CurrencyPreferenceRepositoryImpl(storage: InMemoryKeyValueStorage()),
      )
      ..registerSingleton<CategoryRepository>(CategoryRepositoryImpl(storage: InMemoryKeyValueStorage()))
      ..registerSingleton<FinancialMonthPreferenceRepository>(
        FinancialMonthPreferenceRepositoryImpl(storage: InMemoryKeyValueStorage()),
      )
      ..registerSingleton<ChangeAppLanguage>(
        ChangeAppLanguage(repository: LanguagePreferenceRepositoryImpl(storage: InMemoryKeyValueStorage())),
      );
    if (withUpdate) harness.register(container);
    return container;
  }

  /// Membuka layar Akun seperti aplikasi: lewat kunci rute, di lebar 360dp.
  Future<void> openAccount(WidgetTester tester, {bool withUpdate = true}) async {
    tester.view
      ..physicalSize = const Size(360, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScopeProvider(
        container: rootContainer(withUpdate: withUpdate),
        child: MaterialApp(
          theme: PixelTheme.light,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.pushRoute(AccountRouteKeys.page, const EmptyInput()),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(t.account.appSection), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  Finder row() => find.byKey(const ValueKey('app-version-row'));

  testWidgets('terpasang 0.6.0 (7) tanpa tambalan: nilai dan "Terbaru", di grup Aplikasi paling bawah', (tester) async {
    await openAccount(tester);
    expect(find.text(t.account.appSection), findsOneWidget);
    expect(find.text(t.account.version.label), findsOneWidget);
    expect(find.text('0.6.0 (7)'), findsOneWidget);
    expect(find.text(t.account.version.statusLatest), findsOneWidget);
  });

  testWidgets('membuka Akun memicu pengecekan Play (B-5)', (tester) async {
    await openAccount(tester);
    verify(() => harness.store.check()).called(1);
  });

  testWidgets('dengan tambalan berjalan: "0.6.0 (7), pembaruan 1"', (tester) async {
    harness.set(patchState: const PatchState(current: 1));
    await openAccount(tester);
    expect(find.textContaining('0.6.0 (7), pembaruan 1'), findsOneWidget);
  });

  group('keterangan keadaan', () {
    const cases = {
      'tersedia': (
        StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 8),
        PatchState.none,
        'statusAvailable',
      ),
      'mengunduh': (
        StoreUpdateInfo(stage: StoreUpdateStage.downloading, availableBuild: 8),
        PatchState.none,
        'statusDownloading',
      ),
      'sudah diunduh': (
        StoreUpdateInfo(stage: StoreUpdateStage.downloaded, availableBuild: 8),
        PatchState.none,
        'statusDownloaded',
      ),
      'pembaruan kecil siap': (StoreUpdateInfo(stage: StoreUpdateStage.none), PatchState(next: 1), 'statusPatchReady'),
    };
    for (final MapEntry(key: name, value: (play, patchState, status)) in cases.entries) {
      for (final locale in [AppLocale.id, AppLocale.en]) {
        testWidgets('$name (${locale.languageCode}) muat di 360dp', (tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(locale));
          harness.set(play: play, patchState: patchState);
          await openAccount(tester);
          final expected = switch (status) {
            'statusAvailable' => t.account.version.statusAvailable,
            'statusDownloading' => t.account.version.statusDownloading,
            'statusDownloaded' => t.account.version.statusDownloaded,
            _ => t.account.version.statusPatchReady,
          };
          expect(find.textContaining(expected), findsOneWidget);
          expect(tester.takeException(), isNull);
          expect(tester.getRect(row()).right, lessThanOrEqualTo(360));
        });
      }
    }
  });

  testWidgets('Play tidak bisa dicek: hanya versi, tanpa keterangan dan tanpa galat', (tester) async {
    harness.set(play: StoreUpdateInfo.unknown);
    await openAccount(tester);
    expect(find.text('0.6.0 (7)'), findsOneWidget);
    expect(find.textContaining(t.account.version.statusLatest), findsNothing);
  });

  testWidgets('bloc tidak terdaftar: grup Aplikasi tetap tampil tanpa baris (tidak ada yang gagal)', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScopeProvider(
        container: rootContainer(withUpdate: false),
        child: MaterialApp(
          theme: PixelTheme.light,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.pushRoute(AccountRouteKeys.page, const EmptyInput()),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(row(), findsNothing);
  });

  testWidgets('ketuk baris membuka "Apa yang baru"', (tester) async {
    await openAccount(tester);
    await tester.tap(row());
    await tester.pumpAndSettle();
    expect(find.text(t.appUpdate.whatsNew.titlePatch), findsOneWidget);
    expect(find.text(t.appUpdate.whatsNew.empty), findsOneWidget);
  });
}
