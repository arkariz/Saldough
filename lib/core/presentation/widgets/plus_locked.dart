import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';

/// Kartu terkunci di atas data yang diburamkan (komponen PlusLocked): untuk
/// batas Gratis yang berupa data, bukan baris. [preview] tetap tampil di
/// belakang, diburamkan dan tidak terbaca pembaca layar; kartu di atasnya
/// memuat lencana Plus, [title], satu kalimat [text] yang menyebut yang tetap
/// gratis, "Lihat Plus" ([onSee]), dan jalan gratis ([freeLabel], [onFree]).
///
/// Pesan sama dengan paywall untuk pemicu itu. Tidak ada data yang dihapus
/// atau disembunyikan permanen.
class PlusLocked extends StatelessWidget {
  /// Membuat [PlusLocked].
  const PlusLocked({
    required this.preview,
    required this.title,
    required this.text,
    required this.onSee,
    required this.freeLabel,
    required this.onFree,
    this.minHeight = 360,
    super.key,
  });

  /// Isi yang dikunci, diburamkan.
  final Widget preview;

  /// Judul yang menyebut batasnya.
  final String title;

  /// Satu kalimat yang menyebut yang tetap gratis.
  final String text;

  /// "Lihat Plus": membuka paywall.
  final VoidCallback onSee;

  /// Label tindakan jalan gratis ("Kembali ke periode terbaru").
  final String freeLabel;

  /// Jalan gratis.
  final VoidCallback onFree;

  /// Tinggi minimal area buram.
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Opacity(opacity: 0.7, child: preview),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Semantics(
              container: true,
              label: title,
              child: DecoratedBox(
                decoration: ds.elevation.card.decoration().copyWith(borderRadius: DsRadius.xlAll),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.actionPrimary.withValues(alpha: 0.10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(ClayIcons.tierCoin, width: 44, height: 44),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DsBadge(label: t.premium.plusBadge, tone: DsBadgeTone.income),
                      const SizedBox(height: 8),
                      Text(title, textAlign: TextAlign.center, style: ds.typography.titleMd.copyWith(fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(
                        text,
                        textAlign: TextAlign.center,
                        style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      DsButton(label: t.premium.seePlus, expand: true, onPressed: onSee),
                      const SizedBox(height: 8),
                      DsButton.secondary(label: freeLabel, expand: true, onPressed: onFree),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
