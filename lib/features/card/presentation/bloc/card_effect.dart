part of 'card_bloc.dart';

extension on CardBloc {
  UiEffect _effectError(Failure failure) => ShowSnackBarEffect(
        message: failure.userMessage ?? t.common.genericErrorMessage,
        severity: .error,
      );

  UiEffect _effectStatementClosed() => ShowSnackBarEffect(
        message: t.card.statementClosedMessage,
        severity: .success,
      );
}
