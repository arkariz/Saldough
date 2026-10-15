import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
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

/// "0.6.0 (7)" atau "0.6.0 (7), pembaruan 1" untuk sebuah catatan.
String releaseNoteVersion(ReleaseNote note) => note.patch > 0
    ? t.account.version.valuePatched(version: note.version, build: note.build, patch: note.patch)
    : t.account.version.value(version: note.version, build: note.build);

/// Kelompok butir satu rilis, **dikelompokkan per kategori**: label (emoji +
/// nama) sekali, butirnya di bawahnya (keputusan pemilik 15 Okt 2026).
/// Emoji tidak dibaca pembaca layar; labelnya yang menyampaikan arti.
class ReleaseNoteGroups extends StatelessWidget {
  /// Membuat [ReleaseNoteGroups].
  const ReleaseNoteGroups({required this.groups, super.key});

  /// Kelompok yang ditampilkan, urutan tampil.
  final List<NoteGroup> groups;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final english = LocaleSettings.currentLocale == AppLocale.en;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, group) in groups.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.space4),
          if (categoryLabel(group.category) case final label?) ...[
            Row(
              children: [
                ExcludeSemantics(
                  child: Text(categoryEmoji(group.category)!, style: const TextStyle(fontSize: 18, height: 1)),
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(label, style: textTheme.labelLarge?.copyWith(color: colors.brandInk)),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
          for (final note in group.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
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
      ],
    );
  }
}
