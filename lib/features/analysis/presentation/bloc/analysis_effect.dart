part of 'analysis_bloc.dart';

extension on AnalysisBloc {
  UiEffect _effectError(Failure failure) => ShowSnackBarEffect(
    message: failure.userMessage ?? t.common.genericErrorMessage,
    severity: .error,
  );
}
