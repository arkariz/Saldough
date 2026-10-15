import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/presentation/widgets/release_notes_view.dart';

/// Lembar "Apa yang baru" (APP_UPDATE F3, §7): kepala dengan judul dan nomor
/// versi, butir dikelompokkan per kategori (bergulir, maksimal 330px), dan
/// satu tombol **Oke**. Tanpa tombol tutup bergambar dan tanpa penutup
/// (keputusan pemilik 15 Okt 2026). Satu catatan = judul bernomor versi
/// (pembaruan kecil: "Apa yang baru"); beberapa = judul versi terbaru dan
/// kelompok per versi.
///
/// Rupa kelompok per kategori sementara: menunggu digambar ulang
/// ui-ux-designer (prototipe lama memakai label per butir).
class WhatsNewSheet extends StatelessWidget {
  /// Membuat [WhatsNewSheet].
  const WhatsNewSheet({required this.notes, required this.onClose, super.key});

  /// Catatan yang ditampilkan, terbaru di atas; tidak kosong.
  final List<ReleaseNote> notes;

  /// Dipanggil oleh tombol Oke.
  final VoidCallback onClose;

  /// Judul lembar menurut isinya.
  static String titleFor(List<ReleaseNote> notes) {
    final newest = notes.first;
    return notes.length == 1 && newest.patch > 0
        ? t.appUpdate.whatsNew.titlePatch
        : t.appUpdate.whatsNew.title(version: newest.version);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final combined = notes.length > 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space3, AppSpacing.space4, AppSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const ValueKey('whats-new-header'),
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: ShapeDecoration(color: colors.brandSoft, shape: const PixelCornerBorder()),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(color: colors.surface, shape: const PixelCornerBorder.small()),
                  child: const ExcludeSemantics(child: Text('🚀', style: TextStyle(fontSize: 28, height: 1))),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(header: true, child: Text(titleFor(notes), style: textTheme.titleLarge)),
                      Text(
                        releaseNoteVersion(notes.first),
                        style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 330),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, note) in notes.indexed) ...[
                    if (index > 0) const SizedBox(height: AppSpacing.space5),
                    if (combined) ...[
                      Semantics(
                        header: true,
                        child: Text(
                          releaseNoteVersion(note),
                          style: textTheme.labelMedium?.copyWith(color: colors.ink2),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                    ],
                    ReleaseNoteGroups(groups: note.groups),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          AppButton(
            key: const ValueKey('whats-new-ok'),
            label: t.appUpdate.action.ok,
            expand: true,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
