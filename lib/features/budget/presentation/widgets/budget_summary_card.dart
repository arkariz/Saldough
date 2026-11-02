import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';

/// Kartu utama segmen Anggaran (FR-BUD-004): sisa lintas seluruh anggaran
/// AKTIF sebagai angka utama yang berhitung naik, bilah terpakai yang
/// tumbuh, lalu rencana dan terpakai. Latar hero gelap berkilau dengan koin
/// celengan yang melayang.
class BudgetSummaryCard extends StatelessWidget {
  /// Membuat [BudgetSummaryCard].
  const BudgetSummaryCard({required this.planned, required this.spent, required this.activeCount, super.key});

  /// Total rencana anggaran aktif, sen.
  final int planned;

  /// Total terpakai anggaran aktif, sen.
  final int spent;

  /// Jumlah anggaran aktif.
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final remaining = planned - spent;
    final over = remaining < 0;
    final ratio = planned <= 0 ? 0.0 : (spent / planned).clamp(0.0, 1.0);
    final base = c.heroSurface;
    final barEnd = over ? c.errorContainer : c.surfaceTint;
    final reduced = DsMotion.reduced(context);

    Widget glass(String label, String amount) => Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: DsRadius.mdAll,
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ds.typography.bodySm.copyWith(color: c.onHeroMuted)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(amount, style: ds.typography.amount.copyWith(color: c.onHero)),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: '${t.budget.remainingLabel} ${AppMoneyFormatter.format(remaining)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: DsRadius.xlAll,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(base, Colors.white, 0.08)!,
              Color.lerp(base, Colors.black, 0.22)!,
              Color.lerp(base, Colors.black, 0.5)!,
            ],
            stops: const [0, 0.45, 1],
          ),
          border: Border.all(color: c.primaryFixed.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: base.withValues(alpha: 0.35),
              offset: const Offset(0, 14),
              blurRadius: 28,
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: DsRadius.xlAll,
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [c.primaryFixed.withValues(alpha: 0.28), c.primaryFixed.withValues(alpha: 0)],
                      ),
                    ),
                    child: const SizedBox.square(dimension: 190),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 14,
                child: ExcludeSemantics(
                  child: DsIdleMotion(
                    kind: DsIdleKind.float,
                    child: SvgPicture.asset(ClayIcons.piggy, width: 52, height: 52),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          t.budget.remainingLabel.toUpperCase(),
                          style: ds.typography.pixelCaption.copyWith(color: c.onHeroMuted),
                        ),
                        const SizedBox(width: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: DsRadius.fullAll,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            child: Text(
                              t.budget.activeBadge(count: activeCount),
                              style: ds.typography.labelMd.copyWith(fontSize: 11, color: c.onHero),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: DsCountUp(
                        value: remaining,
                        builder: (context, current) => Text(
                          AppMoneyFormatter.format(current),
                          style: ds.typography.numericalDisplay.copyWith(color: over ? c.errorContainer : c.onHero),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Bilah terpakai: tumbuh dari kiri saat pertama tampil.
                    ClipRRect(
                      borderRadius: DsRadius.fullAll,
                      child: SizedBox(
                        height: 8,
                        child: Stack(
                          children: [
                            Positioned.fill(child: ColoredBox(color: Colors.white.withValues(alpha: 0.18))),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: reduced ? ratio : 0, end: ratio),
                              duration: const Duration(milliseconds: 1100),
                              curve: DsMotion.easeOutExpo,
                              builder: (context, value, _) => FractionallySizedBox(
                                alignment: AlignmentDirectional.centerStart,
                                widthFactor: value,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [c.primaryFixed, barEnd],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      spacing: 10,
                      children: [
                        glass(t.budget.plannedLabel, AppMoneyFormatter.format(planned)),
                        glass(t.budget.spentLabel, AppMoneyFormatter.format(spent)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
