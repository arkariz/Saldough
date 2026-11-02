import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';
import 'package:saldough/features/data_portability/presentation/widgets/sheet_parts.dart';

/// Halaman "Data dipulihkan dari cadangan {tanggal}." sesudah aplikasi dimulai
/// ulang (`Pulihkan.dc.html`, keadaan selesai). Dibuka shell sekali.
///
/// Catatan izin hanya tampil bila cadangan memuat Catat dari notifikasi atau
/// pengingat DAN izin sistemnya memang belum ada di ponsel ini (dibaca dari
/// [statuses]); tanpa [statuses] catatan tidak tampil.
class RestoreDonePage extends StatefulWidget {
  /// Membuat [RestoreDonePage].
  const RestoreDonePage({required this.report, this.statuses, super.key});

  /// Keterangan pemulihan yang baru selesai.
  final RestoreReport report;

  /// Keadaan fitur di ponsel ini; `null` = tidak diperiksa.
  final FeatureStatuses? statuses;

  @override
  State<RestoreDonePage> createState() => _RestoreDonePageState();
}

class _RestoreDonePageState extends State<RestoreDonePage> with SingleTickerProviderStateMixin {
  bool _needsPermission = false;
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  final GlobalKey _mascotKey = GlobalKey();
  Timer? _burst;
  bool _started = false;

  RestoreReport get report => widget.report;

  @override
  void initState() {
    super.initState();
    if (report.mayNeedPermissions && widget.statuses != null) unawaited(_check(widget.statuses!));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (DsMotion.reduced(context)) {
      _intro.value = 1;
      return;
    }
    _intro.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _mascotKey.currentContext?.findRenderObject() as RenderBox?;
      if (!mounted || box == null || !box.hasSize) return;
      final origin = box.localToGlobal(box.size.center(Offset.zero));
      _burst = Timer(const Duration(milliseconds: 420), () {
        if (mounted) DsCelebration.burst(context, origin: origin, count: 30);
      });
    });
  }

  @override
  void dispose() {
    _burst?.cancel();
    _intro.dispose();
    super.dispose();
  }

  /// Animasi bertahap: nilai 0..1 pada jendela [begin]..[end] dari [_intro].
  Animation<double> _window(double begin, double end, [Curve curve = Curves.easeOutCubic]) => CurvedAnimation(
    parent: _intro,
    curve: Interval(begin, end, curve: curve),
  );

  Future<void> _check(FeatureStatuses statuses) async {
    final states = [
      for (final feature in DiscoveredFeature.values) (await statuses.read(feature)).state,
    ];
    if (mounted && states.contains(FeatureState.permissionNeeded)) setState(() => _needsPermission = true);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final reduced = DsMotion.reduced(context);
    final d = t.dataPortability;
    final date = report.backupCreatedAt;
    final title = report.kind == RestoreKind.undo || date == null
        ? d.undoDoneTitle
        : d.restoreDoneTitle(date: CycleMonthFormatter.formatDateShort(date));
    final kept = d.restoreDoneKept;
    const keptAssets = [ClayIcons.walletNav, ClayIcons.piggy, ClayIcons.palette];
    return PopScope(
      child: Scaffold(
        body: Stack(
          children: [
            if (!reduced) const Positioned.fill(child: IgnorePointer(child: DsAmbientLayer())),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 16),
                        _Hero(key: _mascotKey, intro: _intro, window: _window),
                        const SizedBox(height: 16),
                        _Reveal(
                          animation: _window(0.3, 0.55),
                          child: Text(title, textAlign: TextAlign.center, style: ds.typography.headlineMd),
                        ),
                        const SizedBox(height: 24),
                        _Reveal(
                          animation: _window(0.45, 0.65),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              d.restoreDoneKeptTitle.toUpperCase(),
                              style: ds.typography.pixelCaption.copyWith(color: c.textSecondary),
                            ),
                          ),
                        ),
                        for (final (i, label) in kept.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _Reveal(
                              animation: _window(0.5 + i * 0.1, 0.72 + i * 0.1),
                              child: DsCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    DsIconTile.asset(asset: keptAssets[i % keptAssets.length], size: DsIconTileSize.sm),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(label, style: ds.typography.titleMd.copyWith(fontSize: 15))),
                                    SvgPicture.asset(ClayIcons.done, width: 22, height: 22),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (_needsPermission) ...[
                          const SizedBox(height: 8),
                          _Reveal(
                            animation: _window(0.8, 1),
                            child: SheetNotice(message: d.restoreDoneNote),
                          ),
                        ],
                      ],
                    ),
                  ),
                  DsStickyBar(
                    child: DsButton(
                      key: const ValueKey('restore-home'),
                      label: d.goHome,
                      expand: true,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muncul pelan dari bawah (pudar + geser) mengikuti [animation].
class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(animation),
      child: child,
    ),
  );
}

/// Maskot clay di lingkaran cahaya yang berdenyut, dikelilingi tiga ikon
/// yang membal masuk bergantian lalu melayang.
class _Hero extends StatelessWidget {
  const _Hero({required this.intro, required this.window, super.key});

  final AnimationController intro;
  final Animation<double> Function(double begin, double end, [Curve curve]) window;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    const orbit = [
      (ClayIcons.backupBox, Alignment(-0.95, -0.55), 0.2),
      (ClayIcons.shield, Alignment(0.95, -0.35), 0.3),
      (ClayIcons.star, Alignment(0.7, 0.85), 0.4),
    ];
    return ExcludeSemantics(
      child: SizedBox(
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ScaleTransition(
              scale: window(0, 0.4, Curves.elasticOut),
              child: DsIdleMotion(
                kind: DsIdleKind.float,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [c.actionPrimary.withValues(alpha: 0.22), c.actionPrimary.withValues(alpha: 0.02)],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: SvgPicture.asset(ClayIcons.mascot, width: 120, height: 120),
                  ),
                ),
              ),
            ),
            for (final (asset, alignment, start) in orbit)
              Align(
                alignment: alignment,
                child: ScaleTransition(
                  scale: window(start, start + 0.3, Curves.elasticOut),
                  child: DsIdleMotion(
                    child: SvgPicture.asset(asset, width: 44, height: 44),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
