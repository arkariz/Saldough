part of 'cycle_bloc.dart';

extension on CycleBloc {
  UiEffect _effectError(Failure failure) => ShowSnackBarEffect(
    message: failure.userMessage ?? t.common.genericErrorMessage,
    severity: .error,
  );

  UiEffect _effectCycleCreated(String cycleId) => ShowSnackBarEffect(
    message: cycleId,
    severity: .success,
  );

  UiEffect _effectCycleClosed() => ShowSnackBarEffect(
    message: t.cycle.closedCannotEdit,
    severity: .warning,
  );

  UiEffect _effectRollUpNotEditable() => ShowSnackBarEffect(
    message: t.cycle.rollUpNotEditable,
    severity: .warning,
  );
}
