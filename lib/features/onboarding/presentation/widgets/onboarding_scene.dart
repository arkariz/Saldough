import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Jumlah layar onboarding: OB-1..OB-4 dan layar akhir.
const onboardingSlideCount = 5;

/// Judul dan isi layar onboarding ke-[index] (ART_BRIEF §3).
(String, String) onboardingText(int index) => switch (index) {
  0 => (t.onboarding.page1Title, t.onboarding.page1Body),
  1 => (t.onboarding.page2Title, t.onboarding.page2Body),
  2 => (t.onboarding.page3Title, t.onboarding.page3Body),
  3 => (t.onboarding.page4Title, t.onboarding.page4Body),
  _ => (t.onboarding.finalTitle, t.onboarding.finalBody),
};

/// Adegan satu layar onboarding (v2): satu ikon clay besar di tengah dengan
/// cahaya lembut, dikelilingi tiga ikon clay yang membal masuk bergantian lalu
/// melayang pelan. Hanya adegan yang pernah [active] yang memutar kemunculan;
/// semuanya diam bila pengguna mengurangi gerak.
class OnboardingScene extends StatefulWidget {
  /// Membuat [OnboardingScene].
  const OnboardingScene({required this.index, required this.active, super.key});

  /// Urutan layar.
  final int index;

  /// True saat layar ini yang tampil.
  final bool active;

  @override
  State<OnboardingScene> createState() => _OnboardingSceneState();
}

class _OnboardingSceneState extends State<OnboardingScene> with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(OnboardingScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (DsMotion.reduced(context)) {
      _enter.value = 1;
      return;
    }
    if (widget.active && !_played) {
      _played = true;
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  /// Ikon utama dan tiga ikon pengiring tiap layar.
  static (String, List<String>) _art(int index) => switch (index) {
    0 => (ClayIcons.mascot, [ClayIcons.walletNav, ClayIcons.receipt, ClayIcons.dateCalendar]),
    1 => (ClayIcons.piggy, [ClayIcons.bank, ClayIcons.cash, ClayIcons.ewallet]),
    2 => (ClayIcons.note, [ClayIcons.incomeArrow, ClayIcons.expenseArrow, ClayIcons.transfer]),
    3 => (ClayIcons.chart, [ClayIcons.calendar, ClayIcons.shield, ClayIcons.report]),
    _ => (ClayIcons.mascot, [ClayIcons.trophy, ClayIcons.star, ClayIcons.gift]),
  };

  static const _spots = [Alignment(-0.88, -0.5), Alignment(0.9, -0.15), Alignment(-0.8, 0.62)];

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final (main, orbit) = _art(widget.index);
    Animation<double> slot(double from, double to) => CurvedAnimation(
      parent: _enter,
      curve: Interval(from, to, curve: Curves.elasticOut),
    );
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: FadeTransition(
              opacity: slot(0, 0.5),
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [c.actionPrimary.withValues(alpha: 0.16), c.actionPrimary.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: slot(0, 0.55),
              child: DsIdleMotion(
                kind: DsIdleKind.float,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: AspectRatio(aspectRatio: 1, child: SvgPicture.asset(main)),
                ),
              ),
            ),
          ),
          for (final (i, asset) in orbit.indexed)
            Align(
              alignment: _spots[i],
              child: ScaleTransition(
                scale: slot(0.25 + i * 0.15, 0.65 + i * 0.15),
                child: DsIdleMotion(
                  kind: i.isEven ? DsIdleKind.sway : DsIdleKind.float,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surfaceCard,
                      borderRadius: DsRadius.xlAll,
                      border: Border.all(color: c.outlineSubtle),
                      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SvgPicture.asset(asset, width: 44, height: 44),
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
