part of 'cycle_bloc.dart';

extension on CycleBloc {
  UiEffect _effectError(Failure failure) => ShowSnackBarEffect(
        message: failure.userMessage ?? t.common.genericErrorMessage,
        severity: FeedbackSeverity.error,
      );

  UiEffect _effectCycleCreated(String cycleId) => ShowSnackBarEffect(
        message: cycleId,
        severity: FeedbackSeverity.success,
      );

  UiEffect _effectCycleClosed() => ShowSnackBarEffect(
        message: t.cycle.closedCannotEdit,
        severity: FeedbackSeverity.warning,
      );

  UiEffect _effectRollUpNotEditable() => ShowSnackBarEffect(
        message: t.cycle.rollUpNotEditable,
        severity: FeedbackSeverity.warning,
      );
}
