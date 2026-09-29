import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/account/presentation/pages/account_page.dart';
import 'package:saldough/shared/auth/auth.dart';

import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  setUpAll(registerEffectHandlers);

  Future<void> pumpAccount(WidgetTester tester, {AppUser? signedIn}) async {
    repository = FakeAuthRepository(signedIn: signedIn);
    final container = GetIt.asNewInstance()..registerSingleton<AuthRepository>(repository);
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(onPressed: () => openAccountPage(context), child: const Text('buka')),
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
}
