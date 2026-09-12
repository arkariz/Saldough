part of 'income_source_bloc.dart';

extension on IncomeSourceBloc {
  UiEffect _effectError(Failure failure) => ShowSnackBarEffect(
        message: failure.userMessage ?? t.common.genericErrorMessage,
        severity: .error,
      );

  UiEffect _effectOpenWorklog(String? sourceId) =>
      NavigatePushEffect(keyId: WorklogRouteKeys.page.id, input: WorklogSourceInput(sourceId: sourceId));
}
