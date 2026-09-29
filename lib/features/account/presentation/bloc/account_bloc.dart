import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/account/presentation/bloc/account_state.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:state_management/state_management.dart';

part 'account_effect.dart';
part 'account_event.dart';

/// Bloc layar Akun (ADR-023, ADR-024). Identitas opsional — tidak ada layar
/// pencatatan inti yang bergantung pada bloc ini. Juga menyimpan pilihan
/// mata uang dari bagian "Pengaturan" layar yang sama (ADR-025 §3.6).
final class AccountBloc extends Bloc<AccountEvent, AccountState> {
  /// Membuat [AccountBloc].
  AccountBloc({required this._authRepository, required this._currencyRepository}) : super(AccountState.initial()) {
    on<AccountStarted>(_onStarted);
    on<AccountAuthChanged>(_onAuthChanged);
    on<AccountGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AccountEmailSignInRequested>(_onEmailSignInRequested);
    on<AccountSignOutRequested>(_onSignOutRequested);
    on<AccountDeletionRequested>(_onDeletionRequested);
    on<AccountCurrencyChangeRequested>(_onCurrencyChangeRequested);
  }

  final AuthRepository _authRepository;
  final CurrencyPreferenceRepository _currencyRepository;
  StreamSubscription<AppUser?>? _authSubscription;

  void _onStarted(AccountStarted event, Emitter<AccountState> emit) {
    emit(state.copyWith(user: () => _authRepository.currentUser));
    unawaited(_authSubscription?.cancel());
    _authSubscription = _authRepository.authStateChanges().listen((user) => add(AccountAuthChanged(user)));
  }

  void _onAuthChanged(AccountAuthChanged event, Emitter<AccountState> emit) {
    emit(state.copyWith(user: () => event.user));
  }

  Future<void> _signIn(
    Emitter<AccountState> emit,
    AccountAction action,
    Future<Either<Failure, AppUser>> Function() run,
  ) async {
    emit(state.copyWith(pending: () => action));
    switch (await run()) {
      // Pengguna menutup dialog Google sendiri — bukan galat, diam saja.
      case Left(value: final failure) when failure.code == AuthFailureCodes.canceled:
        emit(state.copyWith(pending: () => null));
      case Left(value: final failure):
        emit(state.copyWith(pending: () => null, effect: _effectError(failure)));
      case Right(value: final user):
        emit(
          state.copyWith(pending: () => null, user: () => user, effect: _effectSuccess(t.account.signedInMessage)),
        );
    }
  }

  Future<void> _onGoogleSignInRequested(AccountGoogleSignInRequested event, Emitter<AccountState> emit) =>
      _signIn(emit, AccountAction.googleSignIn, _authRepository.signInWithGoogle);

  Future<void> _onEmailSignInRequested(AccountEmailSignInRequested event, Emitter<AccountState> emit) async {
    if (event.email.isEmpty || event.password.isEmpty) {
      emit(state.copyWith(effect: ShowSnackBarEffect(message: t.account.emailRequired, severity: .warning)));
      return;
    }
    await _signIn(
      emit,
      AccountAction.emailSignIn,
      () => _authRepository.signInWithEmailAndPassword(email: event.email, password: event.password),
    );
  }

  Future<void> _onSignOutRequested(AccountSignOutRequested event, Emitter<AccountState> emit) async {
    emit(state.copyWith(pending: () => AccountAction.signOut));
    switch (await _authRepository.signOut()) {
      case Left(value: final failure):
        emit(state.copyWith(pending: () => null, effect: _effectError(failure)));
      case Right():
        emit(
          state.copyWith(pending: () => null, user: () => null, effect: _effectSuccess(t.account.signedOutMessage)),
        );
    }
  }

  Future<void> _onDeletionRequested(AccountDeletionRequested event, Emitter<AccountState> emit) async {
    emit(state.copyWith(pending: () => AccountAction.delete, needsPassword: false));
    switch (await _authRepository.deleteAccount(password: event.password)) {
      case Left(value: final failure) when failure.code == AuthFailureCodes.passwordRequired:
        emit(state.copyWith(pending: () => null, needsPassword: true));
      case Left(value: final failure) when failure.code == AuthFailureCodes.canceled:
        emit(state.copyWith(pending: () => null));
      case Left(value: final failure):
        emit(state.copyWith(pending: () => null, effect: _effectError(failure)));
      case Right():
        emit(state.copyWith(pending: () => null, user: () => null, effect: _effectSuccess(t.account.deletedMessage)));
    }
  }

  Future<void> _onCurrencyChangeRequested(AccountCurrencyChangeRequested event, Emitter<AccountState> emit) async {
    if (event.currency == ActiveCurrency.value) return;
    switch (await _currencyRepository.save(event.currency)) {
      case Left():
        emit(state.copyWith(effect: ShowSnackBarEffect(message: t.common.genericErrorMessage, severity: .error)));
      case Right():
        // Dipasang hanya sesudah tersimpan, supaya layar tidak menampilkan
        // mata uang yang hilang lagi saat aplikasi dibuka ulang.
        ActiveCurrency.notifier.value = event.currency;
        emit(state.copyWith(effect: _effectSuccess(t.currency.changedMessage(code: event.currency.code))));
    }
  }

  @override
  Future<void> close() {
    unawaited(_authSubscription?.cancel());
    return super.close();
  }
}
