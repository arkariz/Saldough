import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';

/// Menanyakan konfirmasi sebelum aksi yang tidak bisa dibatalkan.
///
/// Satu dialog bersama untuk seluruh aksi hapus di aplikasi (pos tujuan,
/// kartu, sumber pemasukan, pinjaman, langganan, bahan belanja, baris
/// pemasukan/anggaran, siklus) — dibuat supaya polanya tidak diulang manual
/// di tiap layar, sama seperti alasan `AppCard` dibuat sejak fase fondasi
/// (lihat `app_card.dart:7-10`). Lihat `docs/04-planning/done/UX_REVIEW_FIXES.md`
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
      title: Text(
        title ?? t.common.confirmDeleteTitle,
        style: dialogContext.ds.typography.headlineMd.copyWith(fontSize: 20),
      ),
      content: Text(
        message,
        style: dialogContext.ds.typography.bodyMd.copyWith(color: dialogContext.ds.colors.textSecondary),
      ),
      // Design system Dialog: "Batal" teks di kiri, tindakan permanen
      // bernada danger di kanan.
      actions: [
        DsButton.ghost(label: t.common.cancel, onPressed: () => Navigator.of(dialogContext).pop(false)),
        DsButton.danger(
          label: confirmLabel ?? t.common.delete,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
