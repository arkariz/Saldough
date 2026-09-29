import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:saldough/core/foundation/repository_guard.dart';
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

  static AppUser? _toAppUser(fb.User? user) =>
      user == null ? null : AppUser(uid: user.uid, displayName: user.displayName, email: user.email, photoUrl: user.photoURL);

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() => guard(() async {
        final account = await _googleSignIn.authenticate();
        final credential = fb.GoogleAuthProvider.credential(idToken: account.authentication.idToken);
        final result = await _auth.signInWithCredential(credential);
        final user = _toAppUser(result.user);
        if (user == null) {
          throw StateError('Firebase tidak mengembalikan pengguna sesudah masuk.');
        }
        return user;
      });

  @override
  Future<Either<Failure, AppUser>> signInWithEmailAndPassword({required String email, required String password}) =>
      guard(() async {
        final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
        final user = _toAppUser(result.user);
        if (user == null) {
          throw StateError('Firebase tidak mengembalikan pengguna sesudah masuk.');
        }
        return user;
      });

  @override
  Future<Either<Failure, Unit>> signOut() => guardVoid(() async {
        await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      });

  @override
  Future<Either<Failure, Unit>> deleteAccount() => guardVoid(() async {
        final user = _auth.currentUser;
        if (user == null) return;
        try {
          await user.delete();
        } on fb.FirebaseAuthException catch (e) {
          if (e.code != 'requires-recent-login') rethrow;
          // Sesi masuk terlalu lama untuk operasi sensitif ini -- Firebase
          // menolaknya sampai pengguna membuktikan lagi identitasnya. Minta
          // sekali lagi lewat Google, lalu ulangi penghapusan.
          final account = await _googleSignIn.authenticate();
          final credential = fb.GoogleAuthProvider.credential(idToken: account.authentication.idToken);
          await user.reauthenticateWithCredential(credential);
          await user.delete();
        }
        await _googleSignIn.signOut();
      });

  @override
  Failure? mapCustomError(Object error) {
    if (error is gsi.GoogleSignInException) {
      if (error.code == gsi.GoogleSignInExceptionCode.canceled) {
        return AuthenticationFailure(
          code: const FailureCode('GOOGLE_SIGN_IN_CANCELED'),
          message: error.toString(),
          userMessage: 'Dibatalkan.',
        );
      }
      return NetworkFailure(
        code: const FailureCode('GOOGLE_SIGN_IN_FAILED'),
        message: error.toString(),
        userMessage: 'Tidak bisa terhubung ke Google. Periksa koneksi internetmu, lalu coba lagi.',
      );
    }
    if (error is fb.FirebaseAuthException) {
      final wrongCredentials = {'user-not-found', 'wrong-password', 'invalid-credential', 'invalid-email'};
      return AuthenticationFailure(
        code: FailureCode(error.code),
        message: error.message ?? error.code,
        userMessage:
            wrongCredentials.contains(error.code) ? 'Email atau kata sandi salah.' : 'Sesi masuk bermasalah. Coba masuk lagi.',
      );
    }
    return null;
  }
}
