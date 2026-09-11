part of 'grocery_bloc.dart';

extension on GroceryBloc {
  UiEffect _effectError(Failure failure) => ShowSnackBarEffect(
        message: failure.userMessage ?? t.common.genericErrorMessage,
        severity: .error,
      );

  UiEffect _effectOpenCard() => NavigatePushEffect(keyId: CardRouteKeys.page.id, input: const EmptyInput());
}
