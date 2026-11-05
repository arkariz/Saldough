import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';

/// Nada snackbar: menentukan ikon dan warna titik di kirinya.
enum DsSnackTone {
  /// Berhasil, tersimpan, diingat.
  success,

  /// Informasi atau tawaran.
  info,

  /// Perlu perhatian.
  warning,

  /// Gagal.
  error,
}

/// Lama snackbar ber-aksi tampil sebelum hilang sendiri.
const dsSnackBarActionDuration = Duration(seconds: 6);

/// Isi snackbar: titik bernada di kiri, lalu [child]. Titik membedakan pesan
/// dari sistem dengan teks lain di layar; maknanya tetap dibawa teks.
class DsSnackContent extends StatelessWidget {
  /// Membuat isi snackbar.
  const DsSnackContent({required this.child, this.tone = DsSnackTone.info, super.key});

  /// Teks atau [DsSnackMessage].
  final Widget child;

  /// Nada titik di kiri.
  final DsSnackTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final (icon, fill, onFill) = switch (tone) {
      DsSnackTone.success => (Icons.check_rounded, c.actionPrimary, c.onActionPrimary),
      DsSnackTone.info => (Icons.info_outline_rounded, c.info, c.onActionPrimary),
      DsSnackTone.warning => (Icons.priority_high_rounded, c.warning, c.onActionPrimary),
      DsSnackTone.error => (Icons.close_rounded, c.error, c.onError),
    };
    return Row(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: onFill),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

/// Teks snackbar dengan judul tebal opsional dan isi di bawahnya.
class DsSnackMessage extends StatelessWidget {
  /// Membuat teks snackbar.
  const DsSnackMessage({required this.message, this.title, super.key});

  /// Judul pendek (satu baris), atau `null`.
  final String? title;

  /// Isi pesan.
  final String message;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final onInverse = ds.colors.inverseOnSurface;
    if (title == null) return Text(message, style: ds.typography.bodyMd.copyWith(color: onInverse));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title!,
          style: ds.typography.bodyMd.copyWith(color: onInverse, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(message, style: ds.typography.bodySm.copyWith(color: onInverse.withValues(alpha: 0.82))),
      ],
    );
  }
}

/// Snackbar v2 dengan [content] bertitik [tone]. Dengan [action], snackbar
/// **hilang sendiri** sesudah [dsSnackBarActionDuration] (Flutter menahannya
/// sampai ditutup bila ber-aksi); hanya ditahan saat pembaca layar aktif,
/// karena waktunya tak cukup untuk mencapai tombolnya ([persist]). Menerima
/// token [ds] (bukan context) supaya aman dibuat sesudah rute pemanggilnya
/// tertutup (ADR-030 §3.3).
SnackBar dsSnackBar(
  DsTokens ds, {
  required Widget content,
  DsSnackTone tone = DsSnackTone.info,
  SnackBarAction? action,
  Duration? duration,
  bool persist = false,
}) {
  final colors = ds.colors;
  return SnackBar(
    content: DsSnackContent(tone: tone, child: content),
    duration: duration ?? (action == null ? const Duration(seconds: 4) : dsSnackBarActionDuration),
    persist: action == null ? null : persist,
    padding: EdgeInsets.fromLTRB(12, 12, action == null ? 16 : 4, 12),
    action: action == null
        ? null
        : SnackBarAction(
            key: action.key,
            label: action.label,
            textColor: colors.inversePrimary,
            onPressed: action.onPressed,
          ),
  );
}
