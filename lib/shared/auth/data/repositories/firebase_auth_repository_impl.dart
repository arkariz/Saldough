import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/auth/domain/auth_failure_codes.dart';
import 'package:saldough/shared/auth/domain/entities/app_user.dart';
import 'package:saldough/shared/auth/domain/repositories/auth_repository.dart';

/// Implementasi [AuthRepository] di atas Firebase Auth + Google Sign-In
/// (ADR-023). `GoogleSignIn.instance.initialize(...)` harus sudah dipanggil
/// sekali di `main.dart` sebelum konstruktor ini dipakai — lihat
/// `AppBootstrap.initializeFirebase`.
final class FirebaseAuthRepositoryImpl with RepositoryGuard implements AuthRepository {
  /// Membuat [FirebaseAuthRepositoryImpl]. Parameter opsional untuk
  /// pengujian; bawaannya memakai singleton masing-masing paket.
  FirebaseAuthRepositoryImpl({fb.FirebaseAuth? firebaseAuth, gsi.GoogleSignIn? googleSignIn})
      : _auth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? gsi.GoogleSignIn.instance;

  final fb.FirebaseAuth _auth;
  final gsi.GoogleSignIn _googleSignIn;

  static SignInMethod? _methodOf(fb.User user) {
    final providers = user.providerData.map((p) => p.providerId).toSet();
    if (providers.contains(fb.GoogleAuthProvider.PROVIDER_ID)) return SignInMethod.google;
    if (providers.contains(fb.EmailAuthProvider.PROVIDER_ID)) return SignInMethod.password;
    return null;
  }

  static AppUser? _toAppUser(fb.User? user) => user == null
      ? null
      : AppUser(
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
          photoUrl: user.photoURL,
          method: _methodOf(user),
        );

  static AppUser _requireUser(fb.UserCredential result) {
    final user = _toAppUser(result.user);
    if (user == null) {
      throw StateError('Firebase tidak mengembalikan pengguna sesudah masuk.');
    }
    return user;
  }

  Future<fb.AuthCredential> _googleCredential() async {
    final account = await _googleSignIn.authenticate();
    return fb.GoogleAuthProvider.credential(idToken: account.authentication.idToken);
  }

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() =>
      guard(() async => _requireUser(await _auth.signInWithCredential(await _googleCredential())));

  @override
  Future<Either<Failure, AppUser>> signInWithEmailAndPassword({required String email, required String password}) =>
      guard(() async => _requireUser(await _auth.signInWithEmailAndPassword(email: email, password: password)));

  @override
  Future<Either<Failure, Unit>> signOut() => guardVoid(() async {
        await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      });

  @override
  Future<Either<Failure, Unit>> deleteAccount({String? password}) => guardVoid(() async {
        final user = _auth.currentUser;
        if (user == null) return;
        final method = _methodOf(user);
        try {
          await user.delete();
        } on fb.FirebaseAuthException catch (e) {
          if (e.code != 'requires-recent-login') rethrow;
          // Firebase menolak operasi sensitif ini sampai pengguna membuktikan
          // lagi identitasnya — lewat penyedia yang sama dengan saat masuk.
          await user.reauthenticateWithCredential(await _reauthCredential(user, method, password));
          await user.delete();
        }
        if (method == SignInMethod.google) await _googleSignIn.signOut();
      });

  Future<fb.AuthCredential> _reauthCredential(fb.User user, SignInMethod? method, String? password) async {
    if (method != SignInMethod.password) return _googleCredential();
    final email = user.email;
    if (password == null || password.isEmpty || email == null) throw const _PasswordRequired();
    return fb.EmailAuthProvider.credential(email: email, password: password);
  }

  static bool _isUserCancel(String? description) =>
      description == null || description.toLowerCase().contains('cancel');

  static const _wrongCredentialCodes = {'user-not-found', 'wrong-password', 'invalid-credential', 'invalid-email'};

  @override
  Failure? mapCustomError(Object error) {
    if (error is _PasswordRequired) {
      return const AuthenticationFailure(
        code: AuthFailureCodes.passwordRequired,
        message: 'requires-recent-login pada akun email/sandi; sandi belum diberikan.',
      );
    }
    if (error is gsi.GoogleSignInException) {
      return switch (error.code) {
        // Android melaporkan juga galat konfigurasi (mis. SHA-1 belum
        // terdaftar: "[16] Account reauth failed.") sebagai `canceled`. Hanya
        // yang deskripsinya memang pembatalan yang didiamkan; sisanya galat.
        gsi.GoogleSignInExceptionCode.canceled when _isUserCancel(error.description) =>
          AuthenticationFailure(code: AuthFailureCodes.canceled, message: error.toString()),
        gsi.GoogleSignInExceptionCode.canceled =>
          AuthenticationFailure(code: AuthFailureCodes.other, message: error.toString()),
        gsi.GoogleSignInExceptionCode.clientConfigurationError ||
        gsi.GoogleSignInExceptionCode.providerConfigurationError =>
          AuthenticationFailure(code: AuthFailureCodes.other, message: error.toString()),
        _ => NetworkFailure(code: AuthFailureCodes.network, message: error.toString()),
      };
    }
    if (error is fb.FirebaseAuthException) {
      final message = '${error.code}: ${error.message}';
      return switch (error.code) {
        'network-request-failed' => NetworkFailure(code: AuthFailureCodes.network, message: message),
        'too-many-requests' => AuthenticationFailure(code: AuthFailureCodes.tooManyRequests, message: message),
        'user-disabled' => AuthenticationFailure(code: AuthFailureCodes.userDisabled, message: message),
        final code when _wrongCredentialCodes.contains(code) =>
          AuthenticationFailure(code: AuthFailureCodes.wrongCredentials, message: message),
        _ => AuthenticationFailure(code: AuthFailureCodes.other, message: message),
      };
    }
    return null;
  }
}

final class _PasswordRequired implements Exception {
  const _PasswordRequired();
}
