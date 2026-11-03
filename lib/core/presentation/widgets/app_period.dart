import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_button.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';

/// Nama periode keuangan yang sedang dilihat (komponen PeriodHeader, ADR-038,
/// FINANCIAL_PERIOD P-11): ubin kalender clay, nama bulan atau rentang, lalu
/// penanda periode peralihan bila [transitionDays] diisi. Dengan [onTap] ia
/// tombol yang membuka lembar Awal bulan keuangan (hanya di Rencana › Bulan
/// ini) dengan pil tonal "Atur"; tanpa [onTap] hanya teks (Beranda, Analisis).
class AppPeriodHeader extends StatelessWidget {
  /// Membuat [AppPeriodHeader].
  const AppPeriodHeader({required this.label, this.transitionDays, this.onTap, this.wrapTag, super.key});

  /// Nama periode, mis. "Oktober" atau "25 Sep – 24 Okt".
  final String label;

  /// Panjang periode peralihan, atau `null` bila periode biasa.
  final int? transitionDays;

  /// Membuka lembar Awal bulan keuangan; `null` = bukan tombol.
  final VoidCallback? onTap;

  /// Membungkus penanda peralihan, mis. dengan target tur di titik pemakaian.
  final Widget Function(Widget tag)? wrapTag;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final days = transitionDays;
    final semantics = [
      label,
      if (days != null) t.plan.transitionLabel(days: days),
      if (onTap != null) t.plan.financialMonthChange,
    ].join('. ');
    final tag = days == null ? null : (wrapTag?.call(AppPeriodTag(days: days)) ?? AppPeriodTag(days: days));
    final bar = Row(
      children: [
        DsIconTile.asset(asset: ClayIcons.dateCalendar, size: DsIconTileSize.sm),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ds.typography.titleMd.copyWith(
                  fontSize: 18,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              ?tag,
            ],
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 8),
          // Petunjuk dapat diketuk (FEATURE_DISCOVERY §6.1): pil tonal "Atur".
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.surfaceSunken,
              borderRadius: DsRadius.fullAll,
              border: Border.all(color: c.outlineSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.discovery.period.hint, style: ds.typography.labelMd.copyWith(color: c.textSecondary)),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: c.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ],
    );
    return Semantics(
      container: true,
      label: semantics,
      excludeSemantics: true,
      button: onTap != null,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: onTap == null
            ? bar
            : DsPressable(
                key: const ValueKey('period-header'),
                onPressed: onTap,
                pressedScale: 0.99,
                builder: (context, _) => bar,
              ),
      ),
    );
  }
}

/// Penanda netral "Periode peralihan · n hari" (PeriodHeader
/// `tk-period__tag`): teks sekunder dengan ikon kalender, tanpa latar dan
/// tanpa warna peringatan.
class AppPeriodTag extends StatelessWidget {
  /// Membuat [AppPeriodTag].
  const AppPeriodTag({required this.days, super.key});

  /// Panjang periode peralihan.
  final int days;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Row(
      key: const ValueKey('period-transition-tag'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_repeat, size: 14, color: c.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            t.plan.transitionLabel(days: days),
            style: ds.typography.bodySm.copyWith(
              color: c.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// Pemilih periode ‹ periode › (komponen PeriodStepper, Riwayat › Analisis):
/// melihat ke belakang satu periode sekali langkah. [onNext] `null` menonaktifkan
/// panah maju (periode berjalan: Analisis tidak punya masa depan). Judul
/// nama bulan atau rentang ([FinancialPeriod.name]); periode peralihan diberi
/// [AppPeriodTag] di bawah judul.
class AppPeriodStepper extends StatelessWidget {
  /// Membuat [AppPeriodStepper].
  const AppPeriodStepper({
    required this.title,
    required this.onPrevious,
    required this.onNext,
    this.transitionDays,
    super.key,
  });

  /// Nama periode.
  final String title;

  /// Panjang periode peralihan, atau `null` bila periode biasa.
  final int? transitionDays;

  /// Mundur satu periode; `null` bila tidak ada yang lebih lama.
  final VoidCallback? onPrevious;

  /// Maju satu periode; `null` di periode berjalan.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final days = transitionDays;
    return Row(
      children: [
        AppIconButton(
          key: const ValueKey('period-previous'),
          icon: IconKey.chevronLeft,
          label: t.analysis.previousPeriod,
          onPressed: onPrevious,
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                key: const ValueKey('period-title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (days != null) ...[
                const SizedBox(height: AppSpacing.space1),
                AppPeriodTag(days: days),
              ],
            ],
          ),
        ),
        AppIconButton(
          key: const ValueKey('period-next'),
          icon: IconKey.chevronRight,
          label: t.analysis.nextPeriod,
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// Kisi tanggal mulai bulan keuangan (DayPicker `tk-daygrid`): tujuh kolom
/// 1–28, lalu "Hari terakhir bulan" selebar baris. Tiap sel 48px tinggi;
/// kotak yang terlihat lebih kecil supaya kisi tetap lega.
class AppDayGrid extends StatelessWidget {
  /// Membuat [AppDayGrid].
  const AppDayGrid({required this.selected, required this.onSelected, super.key});

  /// Tanggal terpilih.
  final FinancialMonthStart selected;

  /// Dipanggil saat tanggal diketuk.
  final ValueChanged<FinancialMonthStart> onSelected;

  @override
  Widget build(BuildContext context) {
    const perRow = 7;
    final days = [
      for (var d = FinancialMonthStart.minDay; d <= FinancialMonthStart.maxDay; d++) FinancialMonthStart.day(d),
    ];
    return Column(
      children: [
        for (var row = 0; row < days.length / perRow; row++)
          Row(
            children: [
              for (final day in days.skip(row * perRow).take(perRow))
                Expanded(
                  child: _DayCell(
                    key: ValueKey('day-${day.day}'),
                    label: '${day.day}',
                    semanticsLabel: t.plan.financialMonthDay(day: day.day!),
                    selected: day == selected,
                    onTap: () => onSelected(day),
                  ),
                ),
            ],
          ),
        _DayCell(
          key: const ValueKey('day-last'),
          label: t.plan.financialMonthLastDay,
          semanticsLabel: t.plan.financialMonthLastDay,
          selected: selected.isLastDay,
          wide: true,
          onTap: () => onSelected(FinancialMonthStart.lastDay),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.onTap,
    this.wide = false,
    super.key,
  });

  final String label;
  final String semanticsLabel;
  final bool selected;
  final bool wide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final reduced = DsMotion.reduced(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: DsPressable(
        onPressed: onTap,
        pressedScale: 0.94,
        dimWhenDisabled: false,
        builder: (context, _) => SizedBox(
          height: AppSize.touch,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            child: AnimatedContainer(
              duration: reduced ? Duration.zero : DsMotion.standard,
              decoration: BoxDecoration(
                color: selected ? c.actionPrimary : c.surfaceSunken,
                borderRadius: DsRadius.mdAll,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: c.actionPrimary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: ds.typography.labelMd.copyWith(
                    fontSize: wide ? 13 : 14,
                    color: selected ? c.onActionPrimary : c.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Garis waktu periode (DayPicker `tk-ptl`): tiga ruas selebar jumlah
/// harinya — periode sebelumnya dan berikutnya `line-strong`, periode yang
/// berubah `ink` — dan dua tanggal batas di bawahnya. Hanya menggambarkan
/// kalimat di atasnya, jadi tersembunyi dari pembaca layar.
class AppPeriodTimeline extends StatelessWidget {
  /// Membuat [AppPeriodTimeline].
  const AppPeriodTimeline({
    required this.previousDays,
    required this.currentDays,
    required this.nextDays,
    required this.startLabel,
    required this.endLabel,
    super.key,
  });

  /// Panjang periode sebelumnya.
  final int previousDays;

  /// Panjang periode yang berubah.
  final int currentDays;

  /// Panjang periode berikutnya.
  final int nextDays;

  /// Tanggal awal periode yang berubah.
  final String startLabel;

  /// Tanggal awal periode berikutnya.
  final String endLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final total = previousDays + currentDays + nextDays;
    final tickStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.ink2,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget segment(int days, Color color) => Expanded(
      flex: days,
      child: CustomPaint(painter: _DashPainter(color), child: const SizedBox(height: 8)),
    );
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              segment(previousDays, colors.lineStrong),
              const SizedBox(width: AppSpacing.space1),
              segment(currentDays, colors.ink),
              const SizedBox(width: AppSpacing.space1),
              segment(nextDays, colors.lineStrong),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          SizedBox(
            height: 16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                Widget tick(double fraction, String label) => Positioned(
                  left: constraints.maxWidth * fraction,
                  top: 0,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: Text(label, style: tickStyle, maxLines: 1),
                  ),
                );
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    tick(previousDays / total, startLabel),
                    tick((previousDays + currentDays) / total, endLabel),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Ruas bergaris putus kotak 6px berjarak 2px.
class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawRect(Rect.fromLTWH(x, 0, (size.width - x).clamp(0, 6), size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}

/// Baris Checkbox (komponen Checkbox): kotak 24px bersudut piksel di awal
/// baris, judul nama butir, subjudul akibatnya yang boleh membungkus.
/// Seluruh baris target sentuh, minimal 56px.
class AppCheckRow extends StatelessWidget {
  /// Membuat [AppCheckRow].
  const AppCheckRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  /// Nama butir.
  final String title;

  /// Akibatnya dalam keadaan sekarang.
  final String? subtitle;

  /// Tercentang.
  final bool value;

  /// Dipanggil dengan nilai baru.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      checked: value,
      label: title,
      hint: subtitle,
      excludeSemantics: true,
      onTap: () => onChanged(!value),
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SizedBox.square(
                    dimension: 24,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: value ? colors.brand : colors.surface,
                        shape: PixelCornerBorder.small(
                          side: value ? BorderSide.none : BorderSide(color: colors.lineStrong, width: 2),
                        ),
                      ),
                      child: value ? AppIcon(IconKey.check, size: AppSize.iconSm, color: colors.onBrand) : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      if (subtitle case final subtitle?)
                        Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
