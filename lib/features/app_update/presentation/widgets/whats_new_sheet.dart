import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/presentation/widgets/release_notes_view.dart';

/// Lembar "Apa yang baru" (APP_UPDATE F3, §7; ADR-043): tile roket dengan
/// badge versi dan judul di tengah, tombol × di pojok kanan atas, butir
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
    final ds = context.ds;
    final c = ds.colors;
    final combined = notes.length > 1;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(DsSpacing.md, DsSpacing.lg + DsSpacing.sm, DsSpacing.md, DsSpacing.md),
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
                      const ExcludeSemantics(
                        child: DsIconTile(
                          icon: Icons.rocket_launch_outlined,
                          tone: DsIconTileTone.solid,
                          size: DsIconTileSize.lg,
                        ),
                      ),
                      const SizedBox(width: DsSpacing.sm),
                      Flexible(
                        child: DsBadge(label: releaseNoteVersion(notes.first), tone: DsBadgeTone.income),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    header: true,
                    child: Text(
                      titleFor(notes),
                      textAlign: TextAlign.center,
                      style: ds.typography.headlineSm.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 330),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, note) in notes.indexed) ...[
                        if (index > 0) const SizedBox(height: DsSpacing.lg - 4),
                        if (combined) ...[
                          Semantics(
                            header: true,
                            child: Text(
                              releaseNoteVersion(note),
                              style: ds.typography.labelMd.copyWith(color: c.textSecondary),
                            ),
                          ),
                          const SizedBox(height: DsSpacing.sm),
                        ],
                        ReleaseNoteGroups(groups: note.groups, framed: true),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.md),
              DsButton(
                key: const ValueKey('whats-new-ok'),
                label: t.appUpdate.action.ok,
                expand: true,
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Positioned(
          top: DsSpacing.sm,
          right: DsSpacing.sm,
          child: DsIconButton(
            key: const ValueKey('whats-new-close'),
            icon: Icons.close,
            label: t.appUpdate.whatsNew.close,
            onPressed: onClose,
          ),
        ),
      ],
    );
  }
}
