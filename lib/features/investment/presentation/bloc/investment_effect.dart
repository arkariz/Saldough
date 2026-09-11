part of 'investment_bloc.dart';

extension on InvestmentBloc {
  UiEffect _effectError(Failure failure) => ShowSnackBarEffect(
        message: failure.userMessage ?? t.common.genericErrorMessage,
        severity: .error,
      );

  UiEffect _effectInvalidTotal() => ShowSnackBarEffect(
        message: t.investment.invalidTotalMessage,
        severity: .error,
      );

  UiEffect _effectAllocationSaved() => ShowSnackBarEffect(
        message: t.investment.allocationSavedMessage,
        severity: .success,
      );

  UiEffect _effectLoanSaved() => ShowSnackBarEffect(
        message: t.investment.loanSavedMessage,
        severity: .success,
      );
}
