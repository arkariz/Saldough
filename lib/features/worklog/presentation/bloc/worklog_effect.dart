part of 'worklog_bloc.dart';

extension on WorklogBloc {
  UiEffect _effectError(Failure failure) => ShowSnackBarEffect(
        message: failure.userMessage ?? t.common.genericErrorMessage,
        severity: .error,
      );

  UiEffect _effectBookClosed(NetPayBreakdown breakdown) => ShowSnackBarEffect(
        message: t.worklog.bookClosedMessage(netPay: AppMoneyFormatter.format(breakdown.netPay)),
        severity: .success,
      );

  UiEffect _effectInjected(String cycleId) => ShowSnackBarEffect(
        message: t.worklog.injectedMessage(cycleId: cycleId),
        severity: .success,
      );
}
