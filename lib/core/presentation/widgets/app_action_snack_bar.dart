import 'package:flutter/material.dart';

/// Lama snackbar ber-aksi (Urungkan, Tinjau) tampil sebelum hilang sendiri.
const actionSnackBarDuration = Duration(seconds: 7);

/// Snackbar dengan satu [action] yang **hilang sendiri** sesudah
/// [actionSnackBarDuration].
///
/// Flutter menahan snackbar ber-aksi sampai ditutup (`persist` bawaannya
/// `action != null`). Di sini hanya ditahan saat pembaca layar aktif
/// (`accessibleNavigation`), karena waktunya tidak cukup untuk mencapai
/// tombolnya. Selebihnya aksinya cuma jaring pengaman singkat: selalu ada
/// jalan lain (hapus dari rincian, buka lagi dari rincian rutin, kotak
/// masuk).
SnackBar actionSnackBar(
  BuildContext context, {
  required Widget content,
  required SnackBarAction action,
  Color? backgroundColor,
}) => SnackBar(
  content: content,
  backgroundColor: backgroundColor,
  duration: actionSnackBarDuration,
  persist: MediaQuery.maybeAccessibleNavigationOf(context) ?? false,
  action: action,
);
