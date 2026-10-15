import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/app_money_text.dart';
import 'package:saldough/core/theme/theme.dart';

/// Baris legenda diagram donat (komponen LegendRow): penanda warna, nama,
/// persen, dan nominal dalam satu baris. Mengetuknya memilih kategori di
/// donat; tidak pernah langsung berpindah layar.
///
/// [child] = baris anggota Lainnya (menjorok, tanpa penanda, nama lebih
/// kecil). [swatch] `null` untuk baris anak. [expanded] bukan `null` memberi
/// panah buka-tutup di belakang nama (baris Lainnya).
class AppLegendRow extends StatelessWidget {
  /// Membuat [AppLegendRow].
  const AppLegendRow({
    required this.name,
    required this.percent,
    required this.sen,
    required this.semanticsLabel,
    this.swatch,
    this.selected = false,
    this.child = false,
    this.expanded,
    this.showDivider = false,
    this.amountColor,
    this.onTap,
    super.key,
  });

  /// Nama kategori.
  final String name;

  /// Persen yang sudah diformat ("27%", "<1%").
  final String percent;

  /// Nominal dalam sen, ditampilkan penuh tanpa tanda.
  final int sen;

  /// Label pembaca layar, mis. "Makan, 11%, Rp1.245.000".
  final String semanticsLabel;

  /// Warna penanda; `null` untuk baris anak.
  final Color? swatch;

  /// Baris sedang terpilih.
  final bool selected;

  /// Baris anggota Lainnya.
  final bool child;

  /// `true` = terbuka, `false` = tertutup, `null` = bukan baris yang bisa dibuka.
  final bool? expanded;

  /// Pemisah `line` di atas baris, mulai sejajar nama.
  final bool showDivider;

  /// Warna nominal; bawaan `ink`, pemasukan `positive`.
  final Color? amountColor;

  /// Dipanggil saat diketuk.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final nameStyle = child
        ? textTheme.bodyMedium?.copyWith(color: colors.ink2)
        : textTheme.bodyLarge?.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500);
    final row = Padding(
      padding: EdgeInsets.fromLTRB(child ? 36 : AppSpacing.space4, AppSpacing.space2, AppSpacing.space4, AppSpacing.space2),
      // Nominal paling lebar 45% baris; yang lebih panjang (teks 200%) mengecil
      // supaya nama tetap punya ruang membungkus dan baris tidak melimpah.
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
        children: [
          if (swatch case final color?) ...[
            SizedBox.square(dimension: 10, child: ColoredBox(color: color)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text.rich(
              TextSpan(
                text: name,
                children: [
                  if (expanded case final open?)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.space1),
                        child: AppIcon(open ? IconKey.expandLess : IconKey.expandMore, size: 20, color: colors.ink2),
                      ),
                    ),
                ],
              ),
              style: nameStyle,
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44),
            child: Text(
              percent,
              textAlign: TextAlign.right,
              style: textTheme.labelLarge?.copyWith(color: colors.ink2, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 92, maxWidth: math.max(92, constraints.maxWidth * 0.45)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: AppMoneyText(sen, size: MoneySize.small, color: amountColor),
            ),
          ),
        ],
      ),
      ),
    );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDivider) Padding(padding: const EdgeInsets.only(left: 36), child: Divider(height: 1, thickness: 1, color: colors.line)),
          Material(
            color: selected ? colors.surface2 : Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(constraints: BoxConstraints(minHeight: child ? 44 : 48), child: row),
            ),
          ),
        ],
      ),
    );
  }
}
