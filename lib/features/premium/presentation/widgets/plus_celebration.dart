import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/premium/presentation/widgets/plus_tile.dart';

/// Hero perayaan Plus (layar "Plus aktif" dan "Sudah berlangganan"): kartu
/// gradasi dengan koin clay yang membal masuk lalu melayang pelan, cahaya
/// yang mekar, judul dan kalimat yang menyusul, serta pil keterangan. Dengan
/// [celebrate] konfeti daun dan koin meledak dari koin sekali saat tampil.
///
/// Semua gerak mati bila pengguna mengurangi animasi (`DsMotion.reduced`).
class PlusCelebrationHero extends StatefulWidget {
  /// Membuat [PlusCelebrationHero].
  const PlusCelebrationHero({
    required this.title,
    required this.body,
    this.chips = const [],
    this.celebrate = false,
    super.key,
  });

  /// Judul ("Plus aktif").
  final String title;

  /// Kalimat di bawah judul.
  final String body;

  /// Pil keterangan di bawah kalimat (nama paket, "Plus").
  final List<String> chips;

  /// Ledakan konfeti sekali saat tampil.
  final bool celebrate;

  @override
  State<PlusCelebrationHero> createState() => _PlusCelebrationHeroState();
}

class _PlusCelebrationHeroState extends State<PlusCelebrationHero> with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  final GlobalKey _coinKey = GlobalKey();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (DsMotion.reduced(context)) {
      _in.value = 1;
      return;
    }
    _in.forward();
    if (widget.celebrate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final box = _coinKey.currentContext?.findRenderObject() as RenderBox?;
        if (!mounted || box == null || !box.hasSize) return;
        final origin = box.localToGlobal(box.size.center(Offset.zero));
        // Ledakan menyusul sesudah koin mendarat.
        Future<void>.delayed(const Duration(milliseconds: 420), () {
          if (mounted) DsCelebration.burst(context, origin: origin, count: 36);
        });
      });
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  Animation<double> _slot(double from, double to, [Curve curve = Curves.easeOutCubic]) => CurvedAnimation(
    parent: _in,
    curve: Interval(from, to, curve: curve),
  );

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final base = c.heroSurface;
    final coin = _slot(0, 0.55, Curves.elasticOut);
    final glow = _slot(0.05, 0.7);
    final text = _slot(0.35, 0.8);
    final chips = _slot(0.5, 0.95);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(base, Colors.white, 0.1)!, Color.lerp(base, Colors.black, 0.4)!],
        ),
        borderRadius: DsRadius.xlAll,
        border: Border.all(color: c.heroBorder),
        boxShadow: [BoxShadow(color: c.heroGlow.withValues(alpha: 0.4), blurRadius: 28, offset: const Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        child: Column(
          children: [
            SizedBox(
              width: 150,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ScaleTransition(
                    scale: glow,
                    child: FadeTransition(
                      opacity: glow,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [c.heroAccent.withValues(alpha: 0.55), c.heroAccent.withValues(alpha: 0)],
                          ),
                        ),
                        child: const SizedBox(width: 150, height: 150),
                      ),
                    ),
                  ),
                  ScaleTransition(
                    scale: coin,
                    child: DsIdleMotion(
                      kind: DsIdleKind.float,
                      child: DecoratedBox(
                        key: _coinKey,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.onHero.withValues(alpha: 0.14),
                          border: Border.all(color: c.onHero.withValues(alpha: 0.28)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: SvgPicture.asset(ClayIcons.tierCoin, width: 64, height: 64),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: text,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(text),
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: ds.typography.headlineMd.copyWith(fontSize: 24, color: c.onHero),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.body,
                      textAlign: TextAlign.center,
                      style: ds.typography.bodyMd.copyWith(color: c.onHeroMuted),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.chips.isNotEmpty) ...[
              const SizedBox(height: 16),
              FadeTransition(
                opacity: chips,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final chip in widget.chips)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.onHero.withValues(alpha: 0.16),
                          borderRadius: DsRadius.fullAll,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          child: Text(chip, style: ds.typography.labelMd.copyWith(color: c.onHero)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Daftar "Yang sekarang terbuka": tiga manfaat Plus yang muncul satu per
/// satu (memudar sambil naik) sesudah hero tampil. Tanpa animasi bila gerak
/// dikurangi.
class PlusUnlockedList extends StatefulWidget {
  /// Membuat [PlusUnlockedList].
  const PlusUnlockedList({super.key});

  @override
  State<PlusUnlockedList> createState() => _PlusUnlockedListState();
}

class _PlusUnlockedListState extends State<PlusUnlockedList> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (DsMotion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _reveal(int index, Widget child) {
    // Mulai sesudah hero (≈0,35) lalu bergantian tiap 0,18.
    final start = 0.3 + index * 0.18;
    final a = CurvedAnimation(
      parent: _c,
      curve: Interval(start, (start + 0.35).clamp(0, 1), curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.paywall;
    Widget row(IconKey icon, String title) => DsSettingRow(
      leading: PlusTile(icon, size: 40),
      title: title,
      trailing: Icon(Icons.check_circle, size: 22, color: context.ds.colors.income),
    );
    final rows = [
      row(IconKey.photoCamera, texts.benefits.photo),
      row(IconKey.notificationsActive, texts.benefits.warn),
      row(IconKey.chatBubble, texts.benefits.ask),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _reveal(0, DsSectionHeader(title: texts.unlockedTitle)),
        const SizedBox(height: 8),
        DsListCard(children: [for (final (i, r) in rows.indexed) _reveal(i + 1, r)]),
      ],
    );
  }
}
