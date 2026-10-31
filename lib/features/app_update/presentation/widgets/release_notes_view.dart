import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';

/// Ikon kategori (tile kecil di label kategori, APP_UPDATE §7); kategori
/// yang tidak dikenal memakai ikon catatan netral.
IconData categoryIcon(NoteCategory? category) => switch (category) {
  NoteCategory.newFeature => Icons.auto_awesome,
  NoteCategory.faster => Icons.bolt,
  NoteCategory.fixed => Icons.build_outlined,
  NoteCategory.security => Icons.lock_outline,
  null => Icons.notes,
};

/// Nama kategori di bahasa aktif; `null` untuk kategori yang tidak dikenal.
String? categoryLabel(NoteCategory? category) => switch (category) {
  NoteCategory.newFeature => t.appUpdate.category.kNew,
  NoteCategory.faster => t.appUpdate.category.faster,
  NoteCategory.fixed => t.appUpdate.category.fixed,
  NoteCategory.security => t.appUpdate.category.security,
  null => null,
};

/// Pasangan warna kategori dari token kategori v2: Baru oranye, Lebih cepat
/// kuning tua, Perbaikan biru, Keamanan hijau; kategori yang tak dikenal
/// abu-abu.
DsColorPair categoryColors(DsColorScheme colors, NoteCategory? category) => switch (category) {
  NoteCategory.newFeature => colors.categories.orange,
  NoteCategory.faster => colors.categories.amber,
  NoteCategory.fixed => colors.categories.blue,
  NoteCategory.security => colors.categories.green,
  null => colors.categories.slate,
};

/// "0.6.0 (7)" atau "0.6.0 (7), pembaruan 1" untuk sebuah catatan.
String releaseNoteVersion(ReleaseNote note) => note.patch > 0
    ? t.account.version.valuePatched(version: note.version, build: note.build, patch: note.patch)
    : t.account.version.value(version: note.version, build: note.build);

/// Kelompok butir satu rilis, **dikelompokkan per kategori**: label (ikon +
/// nama) sekali, butirnya di bawahnya (keputusan pemilik 15 Okt 2026). Ikon
/// dekoratif tidak dibaca pembaca layar; labelnya yang menyampaikan arti.
class ReleaseNoteGroups extends StatelessWidget {
  /// Membuat [ReleaseNoteGroups]; [framed] membingkai tiap kelompok dalam
  /// kartu `surfaceSunken` (lembar), tanpa bingkai di dalam kartu versi
  /// (halaman).
  const ReleaseNoteGroups({required this.groups, this.framed = false, super.key});

  /// Kelompok yang ditampilkan, urutan tampil.
  final List<NoteGroup> groups;

  /// Tiap kelompok dalam kartu.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final english = LocaleSettings.currentLocale == AppLocale.en;
    Widget groupView(NoteGroup group) {
      final label = categoryLabel(group.category);
      final pair = categoryColors(c, group.category);
      final body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Row(
              children: [
                ExcludeSemantics(
                  child: DsIconTile.category(
                    icon: categoryIcon(group.category),
                    category: pair,
                    size: DsIconTileSize.xs,
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: pair.container, borderRadius: DsRadius.badgeAll),
                    child: Text(label, style: ds.typography.pixelCaption.copyWith(color: pair.color)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.sm + 4),
          ],
          for (final (index, note) in group.notes.indexed)
            Padding(
              padding: EdgeInsets.only(bottom: index == group.notes.length - 1 ? 0 : DsSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 12),
                    child: ExcludeSemantics(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: c.textMuted, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                  Expanded(child: Text(note.text(english: english), style: ds.typography.bodyMd)),
                ],
              ),
            ),
        ],
      );
      if (!framed) return body;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
        child: body,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, group) in groups.indexed) ...[
          if (index > 0) SizedBox(height: framed ? 12 : DsSpacing.md),
          groupView(group),
        ],
      ],
    );
  }
}
