part of 'transaction_bloc.dart';

extension on TransactionBloc {
  UiEffect _effectError(Failure failure) =>
      ShowSnackBarEffect(message: failure.userMessage ?? t.common.genericErrorMessage, severity: .error);

  UiEffect _effectSaved(String message) => ShowSnackBarEffect(message: message, severity: .success);

  /// UX-8: menghapus transaksi TANPA dialog konfirmasi, diganti snackbar
  /// "Urungkan" yang menyimpan ulang [transaction] (id sama, saldo dihitung
  /// ulang) kalau ditekan.
  ///
  /// `CallbackEffect` (framework `state_management`, sudah terdaftar global
  /// di `app_effect_registry.dart`) dipakai langsung, bukan
  /// `ShowSnackBarEffect.actionLabel`/`actionIntentId` -- catatan di
  /// `snackbar_effect_handler.dart` menyebut keduanya memang belum
  /// disambungkan ke bloc mana pun, dan `CallbackEffect` sudah menyediakan
  /// jalan langsung ke `BuildContext` tanpa mekanisme baru.
  ///
  /// Urungkan memanggil `RecordTransaction` langsung, bukan bloc ini: saat
  /// diketuk, rute rincian pemilik bloc ini biasanya sudah tertutup
  /// (ADR-030 §3.3). `LedgerChanges` memuat ulang layar yang tampil, dan
  /// hasilnya ditampilkan dengan palet yang diambil sekarang.
  UiEffect _effectDeletedWithUndo(Transaction transaction) => CallbackEffect(
    callback: (context) {
      final colors = context.appColors;
      final messenger = ScaffoldMessenger.of(context);
      final restore = _recordTransaction;
      messenger.showSnackBar(
        actionSnackBar(
          context,
          content: Text(t.transaction.deletedMessage, style: TextStyle(color: colors.background)),
          backgroundColor: colors.textPrimary,
          action: SnackBarAction(
            label: t.transaction.undoDeleteAction,
            textColor: colors.accent,
            onPressed: () async {
              final result = await restore(transaction);
              messenger.showSnackBar(
                feedbackSnackBar(colors, switch (result) {
                  Left(value: final failure) => ShowSnackBarEffect(
                    message: failure.userMessage ?? t.common.genericErrorMessage,
                    severity: .error,
                  ),
                  Right() => ShowSnackBarEffect(message: t.transaction.restoredMessage, severity: .success),
                }),
              );
            },
          ),
        ),
      );
    },
  );
}
