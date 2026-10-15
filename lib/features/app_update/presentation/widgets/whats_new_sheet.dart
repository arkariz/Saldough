import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/presentation/widgets/release_notes_view.dart';

/// Lembar "Apa yang baru" (APP_UPDATE F3, §7, rupa v3): tile 🚀 dengan chip
/// versi dan judul di tengah, tombol × di pojok kanan atas, butir
/// **dikelompokkan per kategori** dalam kartu (bergulir, maksimal 330px), dan
/// satu tombol **Oke**. Tanpa kalimat terima kasih dan tanpa maskot
/// (keputusan pemilik 15 Okt 2026). Satu catatan = judul bernomor versi
/// (pembaruan kecil: "Apa yang baru"); beberapa = judul versi terbaru dan
/// kelompok per versi.
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
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space8,
            AppSpacing.space4,
            AppSpacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                key: const ValueKey('whats-new-header'),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: ShapeDecoration(color: colors.surface, shape: const PixelCornerBorder.small()),
                        child: const ExcludeSemantics(child: Text('🚀', style: TextStyle(fontSize: 32, height: 1))),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: ShapeDecoration(color: colors.brandSoft, shape: const PixelCornerBorder.small()),
                        child: Text(
                          releaseNoteVersion(notes.first),
                          style: textTheme.labelSmall?.copyWith(color: colors.brandInk),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Semantics(
                    header: true,
                    child: Text(
                      titleFor(notes),
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
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
                        ReleaseNoteGroups(groups: note.groups, framed: true),
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
        ),
        Positioned(
          top: AppSpacing.space3,
          right: AppSpacing.space3,
          child: Semantics(
            button: true,
            label: t.appUpdate.whatsNew.close,
            excludeSemantics: true,
            onTap: onClose,
            child: GestureDetector(
              key: const ValueKey('whats-new-close'),
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: Container(
                width: AppSize.touch,
                height: AppSize.touch,
                decoration: BoxDecoration(color: colors.surface2, shape: BoxShape.circle),
                child: Center(child: AppIcon(IconKey.close, size: 20, color: colors.ink)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
