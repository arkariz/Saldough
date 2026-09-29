import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/account/presentation/bloc/account_state.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:state_management/state_management.dart';

part 'account_effect.dart';
part 'account_event.dart';

/// Bloc layar Akun (ADR-023). Identitas opsional — tidak ada layar
/// pencatatan inti yang bergantung pada bloc ini.
final class AccountBloc extends Bloc<AccountEvent, AccountState> {
  /// Membuat [AccountBloc].
  AccountBloc({required this._authRepository}) : super(AccountState.initial()) {
    on<AccountStarted>(_onStarted);
    on<AccountAuthChanged>(_onAuthChanged);
    on<AccountGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AccountEmailSignInRequested>(_onEmailSignInRequested);
    on<AccountSignOutRequested>(_onSignOutRequested);
    on<AccountDeletionRequested>(_onDeletionRequested);
  }

  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _authSubscription;

  void _onStarted(AccountStarted event, Emitter<AccountState> emit) {
    emit(state.copyWith(user: () => _authRepository.currentUser));
    unawaited(_authSubscription?.cancel());
    _authSubscription = _authRepository.authStateChanges().listen((user) => add(AccountAuthChanged(user)));
  }

  void _onAuthChanged(AccountAuthChanged event, Emitter<AccountState> emit) {
    emit(state.copyWith(user: () => event.user));
  }

  Future<void> _onGoogleSignInRequested(AccountGoogleSignInRequested event, Emitter<AccountState> emit) async {
    emit(state.copyWith(isBusy: true));
    switch (await _authRepository.signInWithGoogle()) {
      case Left(value: final failure):
        emit(state.copyWith(isBusy: false, effect: _effectError(failure)));
      case Right(value: final user):
        emit(state.copyWith(isBusy: false, user: () => user));
    }
  }

  Future<void> _onEmailSignInRequested(AccountEmailSignInRequested event, Emitter<AccountState> emit) async {
    emit(state.copyWith(isBusy: true));
    switch (await _authRepository.signInWithEmailAndPassword(email: event.email, password: event.password)) {
      case Left(value: final failure):
        emit(state.copyWith(isBusy: false, effect: _effectError(failure)));
      case Right(value: final user):
        emit(state.copyWith(isBusy: false, user: () => user));
    }
  }

  Future<void> _onSignOutRequested(AccountSignOutRequested event, Emitter<AccountState> emit) async {
    emit(state.copyWith(isBusy: true));
    switch (await _authRepository.signOut()) {
      case Left(value: final failure):
        emit(state.copyWith(isBusy: false, effect: _effectError(failure)));
      case Right():
        emit(state.copyWith(isBusy: false, user: () => null));
    }
  }

  Future<void> _onDeletionRequested(AccountDeletionRequested event, Emitter<AccountState> emit) async {
    emit(state.copyWith(isBusy: true));
    switch (await _authRepository.deleteAccount()) {
      case Left(value: final failure):
        emit(state.copyWith(isBusy: false, effect: _effectError(failure)));
      case Right():
        emit(state.copyWith(isBusy: false, user: () => null, effect: _effectDeleted()));
    }
  }

  @override
  Future<void> close() {
    unawaited(_authSubscription?.cancel());
    return super.close();
  }
}
