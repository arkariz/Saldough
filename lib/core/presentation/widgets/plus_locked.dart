import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_badge.dart';
import 'package:saldough/core/presentation/widgets/app_button.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';

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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
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
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Semantics(
              container: true,
              label: title,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: ShapeDecoration(color: colors.surface, shape: const PixelCornerBorder()),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBadge(t.premium.plusBadge, tone: AppTone.brand, icon: IconKey.plus),
                    const SizedBox(height: AppSpacing.space2),
                    Text(title, textAlign: TextAlign.center, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    AppButton(label: t.premium.seePlus, expand: true, onPressed: onSee),
                    const SizedBox(height: AppSpacing.space2),
                    AppButton.secondary(label: freeLabel, expand: true, onPressed: onFree),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
