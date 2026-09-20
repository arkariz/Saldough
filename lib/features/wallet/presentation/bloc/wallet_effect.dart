part of 'wallet_bloc.dart';

extension on WalletBloc {
  UiEffect _effectError(Failure failure) =>
      ShowSnackBarEffect(message: failure.userMessage ?? t.common.genericErrorMessage, severity: .error);

  UiEffect _effectSaved(String message) => ShowSnackBarEffect(message: message, severity: .success);

  UiEffect _effectMessage(String message) => ShowSnackBarEffect(message: message, severity: .error);
}
