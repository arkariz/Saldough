import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Kepala lembar: tombol tutup di kiri, judul di tengah.
class SheetHeader extends StatelessWidget {
  /// Membuat [SheetHeader].
  const SheetHeader({required this.title, super.key});

  /// Judul lembar.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DsIconButton(icon: Icons.close, label: t.common.close, onPressed: () => Navigator.of(context).pop()),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: context.ds.typography.headlineMd.copyWith(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

/// Catatan satu baris dengan ikon info, dipakai lembar ekspor dan cadangkan.
class SheetNote extends StatelessWidget {
  /// Membuat [SheetNote].
  const SheetNote(this.text, {super.key});

  /// Teks catatan.
  final String text;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.info_outline, size: 16, color: ds.colors.textMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary)),
        ),
      ],
    );
  }
}

/// Peringatan berkotak (mis. cadangan lebih lama dari data sekarang): tile
/// ikon, pesan, dan nada peringatan.
class SheetNotice extends StatelessWidget {
  /// Membuat [SheetNotice].
  const SheetNotice({required this.message, super.key});

  /// Pesan peringatan.
  final String message;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DsCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsIconTile.asset(asset: ClayIcons.warning, tone: DsIconTileTone.warning, size: DsIconTileSize.sm),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(message, style: ds.typography.bodySm.copyWith(color: ds.colors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ubin ilustrasi besar yang membal masuk (diam bila gerak dikurangi).
class SheetHeroTile extends StatelessWidget {
  /// Membuat [SheetHeroTile].
  const SheetHeroTile({required this.asset, this.tone = DsIconTileTone.neutral, super.key});

  /// Ilustrasi clay.
  final String asset;

  /// Nada ubin.
  final DsIconTileTone tone;

  @override
  Widget build(BuildContext context) {
    final reduced = DsMotion.reduced(context);
    final tile = DsIconTile.asset(asset: asset, tone: tone, size: DsIconTileSize.lg);
    if (reduced) return Center(child: tile);
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.elasticOut,
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        child: tile,
      ),
    );
  }
}

/// Pemutar kecil di tengah, saat ringkasan dihitung.
class SheetLoading extends StatelessWidget {
  /// Membuat [SheetLoading].
  const SheetLoading({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(
      child: AppSpin(child: Icon(Icons.autorenew, color: context.ds.colors.textSecondary)),
    ),
  );
}

/// Tahap proses: ubin jam pasir, teks "Menyiapkan…", catatan opsional, dan
/// Batal.
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
    final ds = context.ds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: DsIconTile.asset(asset: ClayIcons.hourglass, size: DsIconTileSize.lg),
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSpin(child: Icon(Icons.autorenew, size: 20, color: ds.colors.actionPrimary)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(message, textAlign: TextAlign.center, style: ds.typography.titleMd),
              ),
            ],
          ),
        ),
        if (note != null) ...[const SizedBox(height: 12), SheetNote(note!)],
        const SizedBox(height: 16),
        DsButton.ghost(key: cancelKey, label: t.dataPortability.cancel, expand: true, onPressed: onCancel),
      ],
    );
  }
}

/// Tahap berkas siap: ubin centang yang membal, judul, kartu berkas, catatan
/// "belum tersimpan" bila lembar simpan ditutup, lalu Simpan ke… dan Bagikan.
class SheetFileReady extends StatelessWidget {
  /// Membuat [SheetFileReady].
  const SheetFileReady({
    required this.title,
    required this.fileName,
    required this.fileMeta,
    required this.fileAsset,
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

  /// Ilustrasi clay kartu berkas.
  final String fileAsset;

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
    final ds = context.ds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeroTile(asset: ClayIcons.done, tone: DsIconTileTone.income),
        const SizedBox(height: 8),
        Text(title, textAlign: TextAlign.center, style: ds.typography.headlineMd.copyWith(fontSize: 20)),
        const SizedBox(height: 16),
        DsCard(
          child: Row(
            children: [
              DsIconTile.asset(asset: fileAsset),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fileName, style: ds.typography.titleMd, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(fileMeta, style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showNotSaved) ...[
          const SizedBox(height: 12),
          Semantics(liveRegion: true, child: SheetNote(notSavedText)),
        ],
        const SizedBox(height: 16),
        DsButton(key: saveKey, label: t.dataPortability.saveTo, expand: true, onPressed: onSave),
        const SizedBox(height: 8),
        DsButton.secondary(key: shareKey, label: t.dataPortability.share, expand: true, onPressed: onShare),
      ],
    );
  }
}
