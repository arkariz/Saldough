import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/core/presentation/widgets/stamp_visuals.dart';
import 'package:saldough/core/presentation/widgets/tanuki_pose.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';
import 'package:saldough/features/period_book/presentation/navigation/period_book_route_keys.dart';
import 'package:saldough/features/period_book/presentation/period_book_read_access.dart';
import 'package:saldough/features/period_book/presentation/widgets/book_cover.dart';
import 'package:saldough/features/period_book/presentation/widgets/book_sparkles.dart';
import 'package:saldough/features/period_book/presentation/widgets/book_visuals.dart';

/// Sampul buku (rupa D5, T-27.6): buku melayang, stempel periode dicap satu per
/// satu (permainan, dipicu pengguna membuka buku sehingga boleh ramai, BP-13
/// revisi), lalu **Buka rapor**. Membuka layar ini menandai buku dibuka dan
/// mencetak stempel ke sampul secara permanen (di `access.open`). Tanpa
/// peringkat, skor, atau perbandingan dengan pengguna lain.
class BookCoverPage extends StatefulWidget {
  /// Membuat [BookCoverPage].
  const BookCoverPage({required this.access, required this.periodId, super.key});

  /// Pintu ke data.
  final PeriodBookReadAccess access;

  /// Id periode.
  final String periodId;

  @override
  State<BookCoverPage> createState() => _BookCoverPageState();
}

class _BookCoverPageState extends State<BookCoverPage> with SingleTickerProviderStateMixin {
  BookLoad? _load;
  int _printed = 0;
  int _shake = 0;
  Timer? _timer;
  final GlobalKey _bookKey = GlobalKey();

  /// 0 = buku melayang, 1 = terbuka menghadap lurus sebelum rapor (rupa D5).
  late final AnimationController _opening = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    final load = await widget.access.open(widget.periodId);
    if (!mounted) return;
    setState(() => _load = load);
    if (load is! BookReady || load.stamps.isEmpty) return;
    if (DsMotion.reduced(context)) {
      setState(() => _printed = load.stamps.length);
      return;
    }
    // Dicap satu per satu: mulai 500 ms, selang 900 ms (rupa D5).
    _timer = Timer(const Duration(milliseconds: 500), () => _printNext(load.stamps.length));
  }

  void _printNext(int total) {
    if (!mounted) return;
    setState(() {
      _printed++;
      _shake++;
    });
    final box = _bookKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      DsShapeConfetti.burst(context, origin: box.localToGlobal(Offset(box.size.width * 0.5, box.size.height * 0.85)), count: 22);
    }
    if (_printed < total) _timer = Timer(const Duration(milliseconds: 900), () => _printNext(total));
  }

  Future<void> _openReport() async {
    if (!DsMotion.reduced(context)) await _opening.forward();
    if (!mounted) return;
    await context.pushRoute(PeriodBookRouteKeys.report, BookInput(periodId: widget.periodId));
    if (mounted) await _opening.reverse();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _opening.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final load = _load;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())),
      body: SafeArea(
        child: switch (load) {
          null => const Center(child: CircularProgressIndicator()),
          BookLocked() || BookFailed() => const SizedBox.shrink(),
          BookReady() => DsShake(
            trigger: _shake,
            child: Column(
              children: [
                _CoverHeader(content: load.content),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: BookScene(
                      child: Stack(
                        children: [
                          const Positioned.fill(child: BookSparkles()),
                          // Bayangan lantai di bawah buku.
                          Align(
                            alignment: const Alignment(0, 0.78),
                            child: Container(
                              width: 190,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 22, spreadRadius: 2)],
                              ),
                            ),
                          ),
                          Center(
                            child: _Entrance(
                              child: AnimatedBuilder(
                                animation: _opening,
                                builder: (context, child) => FloatingBook(open: Curves.easeOutCubic.transform(_opening.value), child: child!),
                                child: KeyedSubtree(
                                  key: _bookKey,
                                  child: BookCover(
                                    eyebrow: t.book.cover.eyebrow,
                                    title: load.content.period.period.name,
                                    subtitle: _subtitle(load.content),
                                    semanticLabel: [
                                      t.book.cover.semantic(period: load.content.period.period.name),
                                      for (final id in load.stamps.take(_printed)) stampName(id),
                                    ].join('. '),
                                    mascot: (size) => TanukiPose(
                                      pose: _printed > 0 ? TanukiPoseKind.happy : TanukiPoseKind.neutral,
                                      size: size,
                                      cheer: _shake,
                                    ),
                                    seals: [
                                      for (final (i, id) in load.stamps.indexed)
                                        if (i < _printed)
                                          _StampIn(
                                            child: DsStampSeal(asset: stampAsset(id), semanticLabel: stampName(id), rotation: stampRotation(id)),
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _CoverChips(content: load.content),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: DsSheen(
                    child: DsButton(label: t.book.cover.openReport, expand: true, onPressed: () => unawaited(_openReport())),
                  ),
                ),
              ],
            ),
          ),
        },
      ),
      backgroundColor: ds.colors.surfaceCanvas,
    );
  }

  String _subtitle(PeriodBookContent content) {
    final period = content.period.period;
    return period.isTransition
        ? t.book.cover.transition(days: period.days)
        : '${period.start.year}';
  }
}

/// Buku jatuh masuk dari atas dengan pantulan kecil saat layar dibuka (rupa D5).
class _Entrance extends StatelessWidget {
  const _Entrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (DsMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, -70 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

/// Segel "dicap": turun besar lalu mengetuk (skala 3,2 -> .88 -> 1,06 -> 1 dan
/// putar -40 deg -> -12 deg, 600 ms; rupa D5).
class _StampIn extends StatelessWidget {
  const _StampIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (DsMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, t, child) {
        final scale = dsKeyframes(t, [(0, 3.2), (0.55, 0.88), (0.8, 1.06), (1, 1)]);
        final turn = dsKeyframes(t, [(0, -40), (0.55, -8), (1, 0)]) * 3.14159265 / 180;
        return Opacity(opacity: (t * 4).clamp(0.0, 1.0), child: Transform.rotate(angle: turn, child: Transform.scale(scale: scale, child: child)));
      },
      child: child,
    );
  }
}

/// Kepala sampul: kalimat pembuka dan rentang periode (rupa D5, layar tidak kosong).
class _CoverHeader extends StatelessWidget {
  const _CoverHeader({required this.content});

  final PeriodBookContent content;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          Text(t.book.cover.caption, style: ds.typography.headlineSm, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            content.period.period.rangeLabel.toUpperCase(),
            style: ds.typography.pixelLabel.copyWith(color: ds.colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Chip ringkas di bawah buku: jumlah catatan, hari, dan rutin beres. Hanya
/// fakta yang sudah ada di buku, tanpa nominal dan tanpa penilaian.
class _CoverChips extends StatelessWidget {
  const _CoverChips({required this.content});

  final PeriodBookContent content;

  @override
  Widget build(BuildContext context) {
    final records = content.period.transactionCount;
    final days = content.period.period.days;
    final plan = content.plan;
    final routines = plan == null ? 0 : plan.recorded + plan.skipped;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          BookChip(asset: ClayIcons.bookOpen, label: t.book.cover.records(n: records, count: records)),
          BookChip(asset: 'assets/icons_clay/calendar_date.svg', label: t.book.cover.days(n: days, count: days)),
          if (routines > 0 && plan!.open == 0)
            BookChip(asset: 'assets/icons_clay/repeat_loop.svg', label: t.book.cover.routines(count: routines)),
        ],
      ),
    );
  }
}
