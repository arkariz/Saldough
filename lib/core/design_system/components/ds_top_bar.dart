import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_opacity.dart';
import 'package:saldough/core/design_system/tokens/ds_spacing.dart';

/// Top bar: logo + logo kata di kiri, tindakan di kanan, latar kanvas
/// tembus pandang dengan blur dan garis rambut bawah. Tinggi 56.
///
/// [collapsedTitle] dan [collapse] dipakai `DsCollapsingTopBar`: saat
/// [collapse] naik ke 1, logo kata memudar dan [collapsedTitle] turun masuk.
class DsTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Membuat top bar.
  const DsTopBar({
    required this.wordmark,
    this.logo,
    this.badge,
    this.actions = const [],
    this.collapsedTitle,
    this.collapse = 0,
    this.elevated = false,
    super.key,
  });

  /// Gambar logo 28px.
  final Widget? logo;

  /// Logo kata ("tanukonomy"), huruf piksel kecil.
  final String wordmark;

  /// Lencana kecil di samping logo kata.
  final Widget? badge;

  /// Tindakan di kanan (`DsIconButton`, `DsAvatar`).
  final List<Widget> actions;

  /// Isi pengganti logo kata saat halaman digulir (mini saldo).
  final Widget? collapsedTitle;

  /// Kemajuan menyusut 0–1.
  final double collapse;

  /// Tampilkan bayangan tipis di bawah bar.
  final bool elevated;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (logo != null) ...[SizedBox.square(dimension: 28, child: logo), const SizedBox(width: 8)],
        Flexible(
          child: Semantics(
            header: true,
            child: Text(
              wordmark,
              style: ds.typography.pixelLabel.copyWith(fontSize: 13, color: c.actionPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (badge != null) ...[const SizedBox(width: 6), badge!],
      ],
    );
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: DsMotion.standard,
          decoration: BoxDecoration(
            color: c.surfaceCanvas.withValues(alpha: DsOpacity.chrome),
            border: Border(bottom: BorderSide(color: c.outlineSubtle)),
            boxShadow: elevated
                ? const [BoxShadow(color: Color(0x0F000000), offset: Offset(0, 4), blurRadius: 20)]
                : const [],
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Opacity(opacity: 1 - collapse, child: title),
                          if (collapsedTitle != null)
                            IgnorePointer(
                              ignoring: collapse < 0.5,
                              child: Opacity(
                                opacity: collapse,
                                child: Transform.translate(
                                  offset: Offset(0, -8 * (1 - collapse)),
                                  child: collapsedTitle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kepala halaman: sapaan besar + pil status di kanan, subjudul di bawah.
class DsPageHeader extends StatelessWidget {
  /// Membuat kepala halaman.
  const DsPageHeader({required this.title, this.subtitle, this.trailing, super.key});

  /// Sapaan atau judul.
  final String title;

  /// Subjudul.
  final String? subtitle;

  /// Pil status di kanan judul.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: ds.typography.headlineMd.copyWith(
                    fontSize: 22,
                    height: 30 / 22,
                    fontWeight: FontWeight.w700,
                    fontVariations: const [FontVariation.weight(700)],
                  ),
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), Flexible(child: trailing!)],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted)),
        ],
      ],
    );
  }
}

/// Catatan kaki dekoratif: teks piksel kapital pudar di tengah.
class DsFootnote extends StatelessWidget {
  /// Membuat catatan kaki.
  const DsFootnote({required this.text, this.leading, this.trailing, super.key});

  /// Teks.
  final String text;

  /// Hiasan di kiri (emoji).
  final String? leading;

  /// Hiasan di kanan (emoji).
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final style = ds.typography.pixelCaption.copyWith(color: ds.colors.textSecondary);
    return Opacity(
      opacity: DsOpacity.footnote,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[ExcludeSemantics(child: Text(leading!, style: style)), const SizedBox(width: 6)],
            Flexible(
              child: Text(text, style: style, textAlign: TextAlign.center),
            ),
            if (trailing != null) ...[const SizedBox(width: 6), ExcludeSemantics(child: Text(trailing!, style: style))],
          ],
        ),
      ),
    );
  }
}
