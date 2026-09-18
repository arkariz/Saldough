part of 'record_bloc.dart';

extension on RecordBloc {
  UiEffect _effectError(Failure failure) =>
      ShowSnackBarEffect(message: failure.userMessage ?? t.common.genericErrorMessage, severity: .error);

  /// [message] sudah final (mis. "Pemasukan tercatat.") — ditentukan
  /// pemanggil per jenis transaksi, bukan di sini, supaya kosakatanya
  /// jelas menyatakan jenis apa yang baru dicatat.
  UiEffect _effectSaved(String message) => ShowSnackBarEffect(message: message, severity: .success);
}
