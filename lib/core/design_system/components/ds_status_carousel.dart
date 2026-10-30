import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_button.dart';
import 'package:saldough/core/design_system/components/ds_carousel.dart';
import 'package:saldough/core/design_system/components/ds_icon_tile.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/components/ds_status_board.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Satu slide status ringkas (satu baris, kira-kira 64px): tile ikon, judul
/// dan keterangan, tombol kecil di kanan. Seluruh slide bisa diketuk. Yang
/// [DsStatusSlideData.attention] berlatar kuning.
class DsStatusSlide extends StatelessWidget {
  /// Membuat slide dari [data].
  const DsStatusSlide({required this.data, super.key});

  /// Isi slide.
  final DsStatusSlideData data;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final attention = data.attention;
    return DsPressable(
      onPressed: data.onAction,
      pressedScale: 0.99,
      dimWhenDisabled: false,
      semanticLabel: '${data.title}. ${data.subtitle}',
      builder: (context, _) => Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: attention ? c.warningContainer.withValues(alpha: 0.55) : c.surfaceCard,
          borderRadius: DsRadius.lgAll,
          border: Border.all(color: attention ? c.warning.withValues(alpha: 0.35) : c.outlineSubtle),
        ),
        child: Row(
          children: [
            DsIconTile(
              icon: data.icon,
              size: DsIconTileSize.sm,
              tone: attention ? DsIconTileTone.warning : DsIconTileTone.neutral,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.title,
                    style: ds.typography.bodyMd.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontVariations: const [FontVariation.weight(600)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data.subtitle,
                    style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (data.actionLabel != null) ...[
              const SizedBox(width: 8),
              ExcludeSemantics(
                child: IgnorePointer(
                  child: DsButton.compact(label: data.actionLabel!.toUpperCase(), onPressed: data.onAction ?? () {}),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Carousel status: slide dari [board] (yang perlu dicek
/// dulu) diikuti [extras] (mis. kartu anggaran). Satu slide tampil tanpa titik;
/// dua atau lebih menjadi carousel dengan titik indikator. Tinggi mengikuti
/// slide tertinggi (`DsCarousel`).
class DsStatusCarousel extends StatelessWidget {
  /// Membuat carousel status.
  const DsStatusCarousel({
    required this.board,
    required this.previousLabel,
    required this.nextLabel,
    required this.dotLabel,
    this.extras = const [],
    super.key,
  });

  /// Papan sumber slide.
  final DsStatusBoard board;

  /// Slide tambahan paling belakang (bukan data papan), mis. kartu anggaran.
  final List<Widget> extras;

  /// Label pembaca layar tombol sebelumnya.
  final String previousLabel;

  /// Label pembaca layar tombol berikutnya.
  final String nextLabel;

  /// Label pembaca layar titik ke-[index].
  final String Function(int index) dotLabel;

  /// Jumlah slide dari papan (tanpa [trailing]).
  static int boardCount(DsStatusBoard board) => board.slides.length;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: board,
      builder: (context, _) {
        final slides = board.slides;
        final children = <Widget>[
          for (final slide in slides) DsStatusSlide(key: ValueKey('status-slide-${slide.id}'), data: slide),
          ...extras,
        ];
        if (children.isEmpty) return const SizedBox.shrink();
        if (children.length == 1) return children.single;
        return DsCarousel(
          previousLabel: previousLabel,
          nextLabel: nextLabel,
          dotLabel: dotLabel,
          adaptiveHeight: true,
          children: [for (final child in children) Align(alignment: Alignment.topCenter, child: child)],
        );
      },
    );
  }
}
