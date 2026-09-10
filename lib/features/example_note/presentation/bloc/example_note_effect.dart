part of 'example_note_bloc.dart';

extension on ExampleNoteBloc {
  UiEffect _effectError(Failure failure) => ShowSnackBarEffect(
        message: failure.userMessage ?? t.common.genericErrorMessage,
        severity: FeedbackSeverity.error,
      );

  UiEffect _effectNoteAdded() => ShowSnackBarEffect(
        message: t.common.save,
        severity: FeedbackSeverity.success,
      );
}
