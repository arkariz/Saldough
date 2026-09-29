import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:mocktail/mocktail.dart';
import 'package:saldough/shared/auth/auth.dart';

class _MockAuth extends Mock implements fb.FirebaseAuth {}

class _MockUser extends Mock implements fb.User {}

class _MockUserInfo extends Mock implements fb.UserInfo {}

class _MockCredential extends Mock implements fb.UserCredential {}

class _MockGoogleSignIn extends Mock implements gsi.GoogleSignIn {}

class _MockGoogleAccount extends Mock implements gsi.GoogleSignInAccount {}

fb.FirebaseAuthException _fbError(String code) => fb.FirebaseAuthException(code: code);

void main() {
  late _MockAuth auth;
  late _MockGoogleSignIn google;
  late _MockUser user;
  late FirebaseAuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(fb.EmailAuthProvider.credential(email: 'x', password: 'y'));
  });

  void givenProvider(String providerId) {
    final info = _MockUserInfo();
    when(() => info.providerId).thenReturn(providerId);
    when(() => user.providerData).thenReturn([info]);
  }

  setUp(() {
    auth = _MockAuth();
    google = _MockGoogleSignIn();
    user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => user.displayName).thenReturn('Tanu');
    when(() => user.email).thenReturn('tanu@example.com');
    when(() => user.photoURL).thenReturn(null);
    when(() => auth.currentUser).thenReturn(user);
    when(() => google.signOut()).thenAnswer((_) async {});
    when(() => user.reauthenticateWithCredential(any())).thenAnswer((_) async => _MockCredential());
    repository = FirebaseAuthRepositoryImpl(firebaseAuth: auth, googleSignIn: google);
  });

  void givenGoogleAccount() {
    final account = _MockGoogleAccount();
    when(() => account.authentication).thenReturn(const gsi.GoogleSignInAuthentication(idToken: 'id-token'));
    when(() => google.authenticate()).thenAnswer((_) async => account);
  }

  FailureCode? codeOf(Either<Failure, Object?> result) => result.fold((f) => f.code, (_) => null);

  group('currentUser', () {
    test('memetakan penyedia Google ke SignInMethod.google', () {
      givenProvider('google.com');
      expect(repository.currentUser?.method, SignInMethod.google);
      expect(repository.currentUser?.email, 'tanu@example.com');
    });

    test('memetakan penyedia password ke SignInMethod.password', () {
      givenProvider('password');
      expect(repository.currentUser?.method, SignInMethod.password);
    });
  });

  group('deleteAccount', () {
    test('sesi masih baru: langsung menghapus tanpa re-autentikasi', () async {
      givenProvider('google.com');
      when(() => user.delete()).thenAnswer((_) async {});

      final result = await repository.deleteAccount();

      expect(result.isRight(), isTrue);
      verifyNever(() => user.reauthenticateWithCredential(any()));
      verify(() => google.signOut()).called(1);
    });

    test('akun Google dengan sesi lama: re-autentikasi lewat Google lalu menghapus', () async {
      givenProvider('google.com');
      givenGoogleAccount();
      var calls = 0;
      when(() => user.delete()).thenAnswer((_) async {
        if (calls++ == 0) throw _fbError('requires-recent-login');
      });

      final result = await repository.deleteAccount();

      expect(result.isRight(), isTrue);
      verify(() => google.authenticate()).called(1);
      final credential = verify(() => user.reauthenticateWithCredential(captureAny())).captured.single;
      expect((credential as fb.AuthCredential).providerId, 'google.com');
      verify(() => user.delete()).called(2);
    });

    test('akun email/sandi dengan sesi lama tanpa sandi: minta sandi, tidak menyentuh Google', () async {
      givenProvider('password');
      when(() => user.delete()).thenThrow(_fbError('requires-recent-login'));

      final result = await repository.deleteAccount();

      expect(codeOf(result), AuthFailureCodes.passwordRequired);
      verifyNever(() => google.authenticate());
      verifyNever(() => user.reauthenticateWithCredential(any()));
    });

    test('akun email/sandi dengan sesi lama dan sandi: re-autentikasi email lalu menghapus', () async {
      givenProvider('password');
      var calls = 0;
      when(() => user.delete()).thenAnswer((_) async {
        if (calls++ == 0) throw _fbError('requires-recent-login');
      });

      final result = await repository.deleteAccount(password: 'rahasia');

      expect(result.isRight(), isTrue);
      final credential = verify(() => user.reauthenticateWithCredential(captureAny())).captured.single;
      expect((credential as fb.AuthCredential).providerId, 'password');
      verifyNever(() => google.authenticate());
      verifyNever(() => google.signOut());
    });

    test('sandi salah saat re-autentikasi: galat kredensial salah', () async {
      givenProvider('password');
      when(() => user.delete()).thenThrow(_fbError('requires-recent-login'));
      when(() => user.reauthenticateWithCredential(any())).thenThrow(_fbError('invalid-credential'));

      final result = await repository.deleteAccount(password: 'keliru');

      expect(codeOf(result), AuthFailureCodes.wrongCredentials);
    });
  });

  group('pemetaan galat', () {
    Future<FailureCode?> emailSignInFailingWith(Object error) async {
      when(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(error);
      return codeOf(await repository.signInWithEmailAndPassword(email: 'a@b.c', password: 'x'));
    }

    test('kode Firebase dipetakan ke AuthFailureCodes', () async {
      expect(await emailSignInFailingWith(_fbError('wrong-password')), AuthFailureCodes.wrongCredentials);
      expect(await emailSignInFailingWith(_fbError('invalid-credential')), AuthFailureCodes.wrongCredentials);
      expect(await emailSignInFailingWith(_fbError('network-request-failed')), AuthFailureCodes.network);
      expect(await emailSignInFailingWith(_fbError('too-many-requests')), AuthFailureCodes.tooManyRequests);
      expect(await emailSignInFailingWith(_fbError('user-disabled')), AuthFailureCodes.userDisabled);
      expect(await emailSignInFailingWith(_fbError('operation-not-allowed')), AuthFailureCodes.other);
    });

    test('Google dibatalkan dipetakan ke canceled, galat lain ke network', () async {
      when(
        () => google.authenticate(),
      ).thenThrow(const gsi.GoogleSignInException(code: gsi.GoogleSignInExceptionCode.canceled));
      expect(codeOf(await repository.signInWithGoogle()), AuthFailureCodes.canceled);

      when(
        () => google.authenticate(),
      ).thenThrow(const gsi.GoogleSignInException(code: gsi.GoogleSignInExceptionCode.unknownError));
      expect(codeOf(await repository.signInWithGoogle()), AuthFailureCodes.network);
    });

    test('canceled dari Android dibedakan: pembatalan diam, galat konfigurasi jadi other', () async {
      Future<FailureCode?> canceledWith(String description) async {
        when(() => google.authenticate()).thenThrow(
          gsi.GoogleSignInException(code: gsi.GoogleSignInExceptionCode.canceled, description: description),
        );
        return codeOf(await repository.signInWithGoogle());
      }

      expect(await canceledWith('[16] Cancelled by user.'), AuthFailureCodes.canceled);
      expect(await canceledWith('[16] Account reauth failed.'), AuthFailureCodes.other);
    });
  });
}
