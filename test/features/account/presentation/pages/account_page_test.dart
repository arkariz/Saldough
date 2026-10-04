import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/features/account/presentation/navigation/account_route_keys.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/category/category.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/routes.dart';

void main() {
  late FakeAuthRepository repository;

  setUpAll(registerEffectHandlers);

  Future<void> pumpAccount(WidgetTester tester, {AppUser? signedIn}) async {
    repository = FakeAuthRepository(signedIn: signedIn);
    final container = GetIt.asNewInstance()
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
      ..registerSingleton<AuthRepository>(repository)
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
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
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
  }

  testWidgets('belum masuk: Google tampil, form email tersembunyi sampai tautannya diketuk', (tester) async {
    await pumpAccount(tester);

    expect(find.text(t.account.signedOutTitle), findsOneWidget);
    expect(find.text(t.account.googleSignInAction), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byKey(const ValueKey('account-email-toggle')));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('masuk Google menampilkan profil, data kamu, dan zona bahaya', (tester) async {
    await pumpAccount(tester);

    await tester.tap(find.text(t.account.googleSignInAction));
    await tester.pumpAndSettle();

    expect(find.text('Tanu Ki'), findsOneWidget);
    expect(find.text('tanu@example.com'), findsOneWidget);
    expect(find.text(t.account.methodGoogle), findsOneWidget);
    expect(find.text(t.account.dataTitle.toUpperCase()), findsOneWidget);
    expect(find.byKey(const ValueKey('account-delete')), findsOneWidget);
  });

  testWidgets('hapus akun email/sandi dengan sesi lama meminta sandi lalu menghapus', (tester) async {
    await pumpAccount(
      tester,
      signedIn: const AppUser(uid: 'rev', email: 'review@example.com', method: SignInMethod.password),
    );
    repository.nextDeletes.add(
      left(const AuthenticationFailure(code: AuthFailureCodes.passwordRequired, message: 'uji')),
    );

    await tester.ensureVisible(find.byKey(const ValueKey('account-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, t.account.deleteAction));
    await tester.pumpAndSettle();

    expect(find.text(t.account.deletePasswordTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'rahasia');
    await tester.tap(find.widgetWithText(TextButton, t.account.deleteAction));
    await tester.pumpAndSettle();

    expect(repository.deletePasswords, [null, 'rahasia']);
    expect(find.text(t.account.signedOutTitle), findsOneWidget);
  });

  testWidgets('ganti mata uang: pilih, lihat contoh tanpa konversi, konfirmasi', (tester) async {
    addTearDown(() => ActiveCurrency.notifier.value = AppCurrency.idr);
    await pumpAccount(tester);

    final setting = find.byKey(const ValueKey('currency-setting'));
    await tester.ensureVisible(setting);
    expect(find.text('IDR · ${t.currency.names.idr}'), findsOneWidget);

    await tester.tap(setting);
    await tester.pumpAndSettle();
    final usd = find.byKey(const ValueKey('currency-option-USD'));
    await tester.ensureVisible(usd);
    await tester.tap(usd);
    await tester.pumpAndSettle();

    expect(find.text(t.currency.changeBody(before: 'Rp50.000', after: r'$50.000,00')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('currency-change-confirm')));
    await tester.pumpAndSettle();

    expect(ActiveCurrency.value, AppCurrency.usd);
    expect(find.text('USD · ${t.currency.names.usd}'), findsOneWidget);
  });

  testWidgets('Kategori (ADR-026): tambah, ganti nama, arsipkan, lalu pulihkan', (tester) async {
    addTearDown(() => ActiveCategories.notifier.value = const []);
    await pumpAccount(tester);

    await tester.ensureVisible(find.byKey(const ValueKey('category-setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-setting')));
    await tester.pumpAndSettle();
    expect(find.text(t.category.emptyActive), findsOneWidget);

    await tester.tap(find.text(t.category.addAction));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Arisan');
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(find.text('Arisan'), findsOneWidget);

    await tester.tap(find.text('Arisan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Arisan RT');
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(find.text('Arisan RT'), findsOneWidget);

    await tester.tap(find.text(t.category.archiveAction));
    await tester.pumpAndSettle();
    expect(find.text(t.category.archivedSection.toUpperCase()), findsOneWidget);
    expect(ActiveCategories.notifier.value.single.isArchived, isTrue);

    await tester.tap(find.text(t.category.restoreAction));
    await tester.pumpAndSettle();
    expect(find.text(t.category.archivedSection.toUpperCase()), findsNothing);
    expect(ActiveCategories.notifier.value.single.isArchived, isFalse);
  });
}
