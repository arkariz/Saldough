import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Catatan satu baris dengan ikon info (`tk-dsheet__note`), dipakai lembar
/// ekspor dan cadangkan.
class SheetNote extends StatelessWidget {
  /// Membuat [SheetNote].
  const SheetNote(this.text, {super.key});

  /// Teks catatan.
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(IconKey.info, color: colors.ink2, size: 18),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink2)),
        ),
      ],
    );
  }
}

/// Spinner kecil di tengah, saat ringkasan dihitung.
class SheetLoading extends StatelessWidget {
  /// Membuat [SheetLoading].
  const SheetLoading({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
    child: Center(
      child: AppSpin(child: AppIcon(IconKey.progressActivity, color: context.appColors.ink2)),
    ),
  );
}

/// Tahap proses: pemutar, teks "Menyiapkan…", catatan opsional, dan Batal.
class SheetBusy extends StatelessWidget {
  /// Membuat [SheetBusy].
  const SheetBusy({required this.message, required this.onCancel, this.note, this.cancelKey, super.key});

  /// Teks proses.
  final String message;

  /// Catatan di bawahnya (mis. "Ini bisa memakan waktu…"), atau `null`.
  final String? note;

  /// Tombol Batal.
  final VoidCallback onCancel;

  /// Kunci tombol Batal untuk uji.
  final Key? cancelKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              AppSpin(child: AppIcon(IconKey.progressActivity, color: context.appColors.brand)),
              const SizedBox(width: AppSpacing.space3),
              Expanded(child: Text(message, style: Theme.of(context).textTheme.titleMedium)),
            ],
          ),
        ),
        if (note != null) ...[const SizedBox(height: AppSpacing.space3), SheetNote(note!)],
        const SizedBox(height: AppSpacing.space4),
        AppButton.text(key: cancelKey, label: t.dataPortability.cancel, expand: true, onPressed: onCancel),
      ],
    );
  }
}

/// Tahap berkas siap: tanda centang, judul, kartu berkas, catatan "belum
/// tersimpan" bila lembar simpan ditutup, lalu Simpan ke… dan Bagikan.
class SheetFileReady extends StatelessWidget {
  /// Membuat [SheetFileReady].
  const SheetFileReady({
    required this.title,
    required this.fileName,
    required this.fileMeta,
    required this.notSavedText,
    required this.showNotSaved,
    required this.onSave,
    required this.onShare,
    this.saveKey,
    this.shareKey,
    super.key,
  });

  /// "Berkas siap" atau "Cadangan siap".
  final String title;

  /// Nama berkas.
  final String fileName;

  /// "Excel · 142 transaksi".
  final String fileMeta;

  /// Catatan bila lembar simpan ditutup tanpa menyimpan.
  final String notSavedText;

  /// Tampilkan [notSavedText].
  final bool showNotSaved;

  /// Simpan ke….
  final VoidCallback onSave;

  /// Bagikan.
  final VoidCallback onShare;

  /// Kunci tombol Simpan ke… untuk uji.
  final Key? saveKey;

  /// Kunci tombol Bagikan untuk uji.
  final Key? shareKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.brandSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: AppIcon(IconKey.checkCircle, color: colors.brandInk, size: 32),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.space4),
        AppCard(
          child: Row(
            children: [
              const AppIconTile(IconKey.description),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fileName, style: textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(fileMeta, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showNotSaved) ...[
          const SizedBox(height: AppSpacing.space3),
          Semantics(liveRegion: true, child: SheetNote(notSavedText)),
        ],
        const SizedBox(height: AppSpacing.space4),
        AppButton(key: saveKey, label: t.dataPortability.saveTo, expand: true, onPressed: onSave),
        const SizedBox(height: AppSpacing.space2),
        AppButton.secondary(key: shareKey, label: t.dataPortability.share, expand: true, onPressed: onShare),
      ],
    );
  }
}
