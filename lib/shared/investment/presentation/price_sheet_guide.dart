import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/core/presentation/widgets/full_screen_sheet.dart';

/// Lembar "Cara kerja harga otomatis" (ADR-051 §3.1, §3.6): apa yang diambil
/// otomatis (saham berkode, perkiraan emas) dan apa yang perlu dipastikan
/// pengguna supaya pengambilan tidak gagal. [actionLabel]/[onAction] menaruh
/// tombol utama di dasar lembar (mis. Hubungkan Google Sheet); tanpanya
/// tombolnya Mengerti.
Future<void> showPriceSheetGuide(BuildContext context, {String? actionLabel, VoidCallback? onAction}) =>
    showAppSheet<void>(
      context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _PriceSheetGuide(actionLabel: actionLabel, onAction: onAction),
    );

class _PriceSheetGuide extends StatelessWidget {
  const _PriceSheetGuide({this.actionLabel, this.onAction});

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final s = t.assets.invest.sheet;
    Widget scope(String asset, String text, {bool muted = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(opacity: muted ? 0.55 : 1, child: DsIconTile.asset(asset: asset, size: DsIconTileSize.sm)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: ds.typography.bodyMd.copyWith(color: muted ? c.textSecondary : c.textPrimary)),
          ),
        ],
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: SingleChildScrollView(
        key: const ValueKey('price-sheet-guide'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DsIconTile.asset(asset: ClayIcons.priceRefresh),
                const SizedBox(width: 12),
                Expanded(child: Text(s.guideTitle, style: ds.typography.headlineSm)),
              ],
            ),
            const SizedBox(height: 16),
            DsSectionHeader(title: s.guideAutoHeading),
            DsListCard(
              children: [
                scope(ClayIcons.stock, s.guideStock),
                scope(ClayIcons.gold, s.guideGold),
                scope(ClayIcons.fund, s.guideOther, muted: true),
              ],
            ),
            const SizedBox(height: 16),
            DsSectionHeader(title: s.guideCheckHeading),
            DsListCard(
              children: [
                for (final (i, check) in s.guideChecks.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.actionPrimary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: ds.typography.labelMd.copyWith(color: c.actionPrimary, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(check, style: ds.typography.bodyMd)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (onAction case final action?) ...[
              DsButton(
                key: const ValueKey('price-sheet-guide-action'),
                label: actionLabel ?? s.connect,
                icon: Symbols.add_link_rounded,
                expand: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  action();
                },
              ),
              const SizedBox(height: 8),
              DsButton.ghost(label: t.common.close, expand: true, onPressed: () => Navigator.of(context).pop()),
            ] else
              DsButton(
                label: s.guideDone,
                icon: Symbols.check_rounded,
                expand: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }
}
