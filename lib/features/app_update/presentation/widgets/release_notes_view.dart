import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';

/// Emoji dekoratif kategori (hanya di label kategori dan kepala lembar,
/// APP_UPDATE §7); kategori yang tidak dikenal tidak punya emoji.
String? categoryEmoji(NoteCategory? category) => switch (category) {
  NoteCategory.newFeature => '✨',
  NoteCategory.faster => '⚡',
  NoteCategory.fixed => '🛠️',
  NoteCategory.security => '🔒',
  null => null,
};

/// Nama kategori di bahasa aktif; `null` untuk kategori yang tidak dikenal.
String? categoryLabel(NoteCategory? category) => switch (category) {
  NoteCategory.newFeature => t.appUpdate.category.kNew,
  NoteCategory.faster => t.appUpdate.category.faster,
  NoteCategory.fixed => t.appUpdate.category.fixed,
  NoteCategory.security => t.appUpdate.category.security,
  null => null,
};

/// Warna kategori (latar, isi) dari token `cat*` (rupa v3): Baru oranye,
/// Lebih cepat kuning tua, Perbaikan biru, Keamanan hijau; kategori yang tak
/// dikenal netral.
(Color, Color) categoryColors(AppColors colors, NoteCategory? category) => switch (category) {
  NoteCategory.newFeature => (colors.catOrangeBg, colors.catOrange),
  NoteCategory.faster => (colors.catAmberBg, colors.catAmber),
  NoteCategory.fixed => (colors.catBlueBg, colors.catBlue),
  NoteCategory.security => (colors.catGreenBg, colors.catGreen),
  null => (colors.catSlateBg, colors.catSlate),
};

/// "0.6.0 (7)" atau "0.6.0 (7), pembaruan 1" untuk sebuah catatan.
String releaseNoteVersion(ReleaseNote note) => note.patch > 0
    ? t.account.version.valuePatched(version: note.version, build: note.build, patch: note.patch)
    : t.account.version.value(version: note.version, build: note.build);

/// Kelompok butir satu rilis, **dikelompokkan per kategori**: label (emoji +
/// nama) sekali, butirnya di bawahnya (keputusan pemilik 15 Okt 2026).
/// Emoji tidak dibaca pembaca layar; labelnya yang menyampaikan arti.
class ReleaseNoteGroups extends StatelessWidget {
  /// Membuat [ReleaseNoteGroups]; [framed] membingkai tiap kelompok dalam
  /// kartu `surface2` (lembar), tanpa bingkai di dalam kartu versi (halaman).
  const ReleaseNoteGroups({required this.groups, this.framed = false, super.key});

  /// Kelompok yang ditampilkan, urutan tampil.
  final List<NoteGroup> groups;

  /// Tiap kelompok dalam kartu.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final english = LocaleSettings.currentLocale == AppLocale.en;
    Widget groupView(NoteGroup group) {
      final label = categoryLabel(group.category);
      final (background, ink) = categoryColors(colors, group.category);
      final body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(color: background, shape: const PixelCornerBorder.small()),
                  child: ExcludeSemantics(
                    child: Text(categoryEmoji(group.category)!, style: const TextStyle(fontSize: 18, height: 1)),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2, vertical: 1),
                  decoration: ShapeDecoration(color: background, shape: const PixelCornerBorder.small()),
                  child: Text(label, style: textTheme.labelSmall?.copyWith(color: ink)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
          ],
          for (final (index, note) in group.notes.indexed)
            Padding(
              padding: EdgeInsets.only(bottom: index == group.notes.length - 1 ? 0 : AppSpacing.space2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: AppSpacing.space3),
                    child: ExcludeSemantics(
                      child: SizedBox.square(dimension: 6, child: ColoredBox(color: colors.ink2)),
                    ),
                  ),
                  Expanded(
                    child: Text(note.text(english: english), style: textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      );
      if (!framed) return body;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: ShapeDecoration(color: colors.surface2, shape: const PixelCornerBorder.small()),
        child: body,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, group) in groups.indexed) ...[
          if (index > 0) SizedBox(height: framed ? AppSpacing.space3 : AppSpacing.space4),
          groupView(group),
        ],
      ],
    );
  }
}
