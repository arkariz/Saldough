part of 'worklog_bloc.dart';

extension on WorklogBloc {
  UiEffect _effectError(Failure failure) => ShowSnackBarEffect(
        message: failure.userMessage ?? t.common.genericErrorMessage,
        severity: .error,
      );

  UiEffect _effectInjected(String cycleId) => ShowSnackBarEffect(
        message: t.worklog.injectedMessage(cycleId: CycleMonthFormatter.format(cycleId)),
        severity: .success,
      );
}
