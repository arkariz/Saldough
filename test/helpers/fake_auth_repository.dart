import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/auth/auth.dart';

/// [AuthRepository] palsu dalam memori. Hasil tiap metode bisa diatur lewat
/// field `next*`; tanpa pengaturan, masuk berhasil sebagai [user].
class FakeAuthRepository implements AuthRepository {
  /// Membuat [FakeAuthRepository], opsional sudah masuk sebagai [signedIn].
  FakeAuthRepository({AppUser? signedIn}) : _current = signedIn;

  /// Pengguna yang dikembalikan saat masuk berhasil.
  static const user = AppUser(
    uid: 'u1',
    displayName: 'Tanu Ki',
    email: 'tanu@example.com',
    method: SignInMethod.google,
  );

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  /// Hasil `signInWithGoogle` berikutnya, kalau diatur.
  Either<Failure, AppUser>? nextGoogle;

  /// Hasil `signInWithEmailAndPassword` berikutnya, kalau diatur.
  Either<Failure, AppUser>? nextEmail;

  /// Hasil `signOut` berikutnya, kalau diatur.
  Either<Failure, Unit>? nextSignOut;

  /// Hasil `deleteAccount` berurutan; kosong berarti berhasil.
  final List<Either<Failure, Unit>> nextDeletes = [];

  /// Argumen `password` tiap panggilan `deleteAccount`.
  final List<String?> deletePasswords = [];

  void _set(AppUser? user) {
    _current = user;
    _controller.add(user);
  }

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  AppUser? get currentUser => _current;

  Either<Failure, AppUser> _signIn(Either<Failure, AppUser>? next) {
    final result = next ?? right(user);
    if (result case Right(value: final signedIn)) _set(signedIn);
    return result;
  }

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() async => _signIn(nextGoogle);

  @override
  Future<Either<Failure, AppUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => _signIn(nextEmail);

  @override
  Future<Either<Failure, Unit>> signOut() async {
    final result = nextSignOut ?? right(unit);
    if (result.isRight()) _set(null);
    return result;
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount({String? password}) async {
    deletePasswords.add(password);
    final result = nextDeletes.isEmpty ? right<Failure, Unit>(unit) : nextDeletes.removeAt(0);
    if (result.isRight()) _set(null);
    return result;
  }
}
