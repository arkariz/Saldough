import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';

/// Menanyakan konfirmasi sebelum aksi yang tidak bisa dibatalkan.
///
/// Satu dialog bersama untuk seluruh aksi hapus di aplikasi (pos tujuan,
/// kartu, sumber pemasukan, pinjaman, langganan, bahan belanja, baris
/// pemasukan/anggaran, siklus) — dibuat supaya polanya tidak diulang manual
/// di tiap layar, sama seperti alasan `AppCard` dibuat sejak fase fondasi
/// (lihat `app_card.dart:7-10`). Lihat `docs/04-planning/UX_REVIEW_FIXES.md`
/// item UX-01.
///
/// Mengembalikan `true` hanya kalau pemilik menekan tombol hapus, `false`
/// (atau `null` kalau dialog ditutup dengan cara lain) untuk seluruh jalan
/// keluar lainnya.
Future<bool> showConfirmDelete(
  BuildContext context, {
  required String message,
  String? title,
  String? confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title ?? t.common.confirmDeleteTitle),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: dialogContext.appColors.expense),
          child: Text(confirmLabel ?? t.common.delete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
