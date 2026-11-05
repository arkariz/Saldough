import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';

/// Lama snackbar ber-aksi (Urungkan, Tinjau) tampil sebelum hilang sendiri.
const Duration actionSnackBarDuration = dsSnackBarActionDuration;

/// Snackbar v2 dengan satu [action] yang **hilang sendiri** sesudah
/// [actionSnackBarDuration] (lihat [dsSnackBar]). Aksinya cuma jaring pengaman
/// singkat: selalu ada jalan lain (hapus dari rincian, buka lagi dari rincian
/// rutin, kotak masuk). [content] teks polos atau [DsSnackMessage]; warna dan
/// gaya mengikuti tema, jangan diberi warna sendiri.
SnackBar actionSnackBar(
  BuildContext context, {
  required Widget content,
  required SnackBarAction action,
  DsSnackTone tone = DsSnackTone.success,
}) => dsSnackBar(
  context.ds,
  content: content,
  tone: tone,
  action: action,
  persist: MediaQuery.maybeAccessibleNavigationOf(context) ?? false,
);
