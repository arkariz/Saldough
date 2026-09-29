part of 'account_bloc.dart';

extension on AccountBloc {
  UiEffect _effectError(Failure failure) =>
      ShowSnackBarEffect(message: failure.userMessage ?? t.common.genericErrorMessage, severity: .error);

  UiEffect _effectDeleted() => ShowSnackBarEffect(message: t.account.deletedMessage, severity: .success);
}
