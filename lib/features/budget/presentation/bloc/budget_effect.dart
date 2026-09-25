part of 'budget_bloc.dart';

extension on BudgetBloc {
  UiEffect _effectError(Failure failure) =>
      ShowSnackBarEffect(message: failure.userMessage ?? t.common.genericErrorMessage, severity: .error);

  UiEffect _effectSaved(String message) => ShowSnackBarEffect(message: message, severity: .success);
}
