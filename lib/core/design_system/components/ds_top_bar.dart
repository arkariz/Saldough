import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_opacity.dart';
import 'package:saldough/core/design_system/tokens/ds_spacing.dart';

/// Top bar: logo + logo kata di kiri, tindakan di kanan, latar kanvas
/// tembus pandang dengan blur dan garis rambut bawah. Tinggi 56.
class DsTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Membuat top bar.
  const DsTopBar({required this.wordmark, this.logo, this.badge, this.actions = const [], super.key});

  /// Gambar logo 28px.
  final Widget? logo;

  /// Logo kata ("tanukonomy"), huruf piksel kecil.
  final String wordmark;

  /// Lencana kecil di samping logo kata.
  final Widget? badge;

  /// Tindakan di kanan (`DsIconButton`, `DsAvatar`).
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: c.surfaceCanvas.withValues(alpha: DsOpacity.chrome),
            border: Border(bottom: BorderSide(color: c.outlineSubtle)),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
                child: Row(
                  children: [
                    if (logo != null) ...[SizedBox.square(dimension: 28, child: logo), const SizedBox(width: 8)],
                    Semantics(
                      header: true,
                      child: Text(
                        wordmark,
                        style: ds.typography.pixelLabel.copyWith(fontSize: 13, color: c.actionPrimary),
                      ),
                    ),
                    if (badge != null) ...[const SizedBox(width: 6), badge!],
                    const Spacer(),
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
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
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
            Flexible(child: Text(text, style: style, textAlign: TextAlign.center)),
            if (trailing != null) ...[const SizedBox(width: 6), ExcludeSemantics(child: Text(trailing!, style: style))],
          ],
        ),
      ),
    );
  }
}
