part of 'home_bloc.dart';

extension on HomeBloc {
  UiEffect _effectError(Failure failure) =>
      ShowSnackBarEffect(message: failure.userMessage ?? t.common.genericErrorMessage, severity: .error);
}
