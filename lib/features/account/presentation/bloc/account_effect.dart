part of 'account_bloc.dart';

extension on AccountBloc {
  UiEffect _effectError(Failure failure) =>
      ShowSnackBarEffect(message: accountFailureMessage(failure), severity: .error);

  UiEffect _effectSuccess(String message) => ShowSnackBarEffect(message: message, severity: .success);
}

/// Teks pengguna untuk galat auth, dipilih dari kode [AuthFailureCodes] —
/// lapisan data tidak membawa teks (ADR-024).
String accountFailureMessage(Failure failure) => switch (failure.code) {
  AuthFailureCodes.network => t.account.errors.network,
  AuthFailureCodes.wrongCredentials => t.account.errors.wrongCredentials,
  AuthFailureCodes.tooManyRequests => t.account.errors.tooManyRequests,
  AuthFailureCodes.userDisabled => t.account.errors.userDisabled,
  AuthFailureCodes.other => t.account.errors.other,
  _ => t.common.genericErrorMessage,
};
