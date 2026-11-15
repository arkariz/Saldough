import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/core/presentation/widgets/stamp_visuals.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_catalog.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_def.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';
import 'package:saldough/features/milestone/presentation/stamp_book_access.dart';
import 'package:saldough/features/milestone/presentation/widgets/stamp_detail_sheet.dart';
import 'package:saldough/features/milestone/presentation/widgets/stamp_scene.dart';

/// Buku Stempel (rupa buku-stempel §4.5, T-28.5): stempel per kelompok, yang
/// diraih berwarna dan yang belum samar dengan satu baris cara mendapatkannya.
/// **Tanpa "n dari N", bilah progres, peringkat, atau gembok** (KT-G1).
/// Tonggak tersembunyi (`revealOnUse`) tampil hanya sesudah diraih (KT-G3;
/// pendekatan: tidak ada pelacak "fitur sudah dipakai" terpisah).
///
/// Membuka layar ini menandai semua stempel dilihat begitu layar ditutup,
/// supaya titik "baru" masih terlihat selama kunjungan.
class StampBookPage extends StatefulWidget {
  /// Membuat [StampBookPage].
  const StampBookPage({required this.access, this.source = 'account', super.key});

  /// Pintu ke keadaan stempel.
  final MilestoneBookAccess access;

  /// Asal pembukaan (`StampBookSource.name`), untuk analitik.
  final String source;

  @override
  State<StampBookPage> createState() => _StampBookPageState();
}

class _StampBookPageState extends State<StampBookPage> with SingleTickerProviderStateMixin {
  int _cheer = 0;

  @override
  void initState() {
    super.initState();
    AppAnalytics.log(MilestoneEvents.bookViewed(widget.source));
  }
  String? _message;
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _shake.dispose();
    unawaited(widget.access.markAllSeen());
    super.dispose();
  }

  /// Ketuk stempel: Tanuki melompat dan berkomentar, lalu lembar detail terbuka.
  void _onStampTap(String id, {required bool earned, required bool isNew, required String body}) {
    final name = stampName(id);
    setState(() {
      _cheer++;
      _message = earned ? t.stamps.kaya.tapEarned(name: name) : t.stamps.kaya.tapLocked(name: name);
    });
    unawaited(
      showStampDetailSheet(
        context,
        id: id,
        earned: earned,
        isNew: isNew,
        body: body,
        onCelebrate: () {
          if (!DsMotion.reduced(context)) _shake.forward(from: 0);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Scaffold(
      appBar: AppBar(title: Text(t.stamps.screen.title, style: ds.typography.headlineMd)),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _shake,
          // Getar layar 420 ms (±5 dp), hanya saat stempel baru dibuka (rupa §9).
          builder: (context, child) => Transform.translate(
            offset: Offset(math.sin(_shake.value * math.pi * 6) * 5 * (1 - _shake.value), 0),
            child: child,
          ),
          child: ValueListenableBuilder<MilestoneLedger>(
            valueListenable: widget.access.ledger,
            builder: (context, ledger, _) => _Body(
              ledger: ledger,
              cheer: _cheer,
              message: _message ?? t.stamps.kaya.idle,
              onTap: _onStampTap,
            ),
          ),
        ),
      ),
    );
  }
}

typedef _TapHandler = void Function(String id, {required bool earned, required bool isNew, required String body});

class _Body extends StatelessWidget {
  const _Body({required this.ledger, required this.cheer, required this.message, required this.onTap});

  final MilestoneLedger ledger;
  final int cheer;
  final String message;
  final _TapHandler onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final visible = [for (final def in milestoneCatalog) if (!def.revealOnUse || ledger.has(def.id)) def];
    final allEarned = milestoneCatalog.every((d) => ledger.has(d.id));
    var index = 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (ledger.earned.isEmpty)
          DsCard(
            child: Row(
              children: [
                SvgPicture.asset(ClayIcons.mascotSleeping, width: 60, height: 60),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t.stamps.intro, style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary)),
                ),
              ],
            ),
          )
        else ...[
          StampScene(message: message, cheer: cheer),
          const SizedBox(height: 12),
          Text(
            t.stamps.intro,
            style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted),
          ),
        ],
        if (ledger.earned.isEmpty)
          _Empty()
        else ...[
          for (final group in MilestoneGroup.values)
            if (visible.any((d) => d.group == group)) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 3,
                      decoration: BoxDecoration(color: ds.colors.stampGoldDeep, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _groupName(group).toUpperCase(),
                      style: ds.typography.pixelLabel.copyWith(color: ds.colors.textMuted),
                    ),
                  ],
                ),
              ),
              DsListCard(
                children: [
                  for (final def in visible.where((d) => d.group == group))
                    _StampTile(def: def, earned: ledger.earned[def.id], order: index++, onTap: onTap),
                ],
              ),
            ],
          if (allEarned) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color.alphaBlend(ds.colors.actionPrimary.withValues(alpha: 0.08), ds.colors.surfaceCard),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                t.stamps.allDone,
                textAlign: TextAlign.center,
                style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

String _groupName(MilestoneGroup g) => switch (g) {
  MilestoneGroup.start => t.stamps.groups.start,
  MilestoneGroup.tidy => t.stamps.groups.tidy,
  MilestoneGroup.safe => t.stamps.groups.safe,
  MilestoneGroup.plan => t.stamps.groups.plan,
};

String _howTo(String id) {
  final how = t.stamps.how;
  return switch (id) {
    'wallet_first' => how.wallet_first,
    'record_first' => how.record_first,
    'period_tidy' => how.period_tidy,
    'recurring_clear' => how.recurring_clear,
    'inbox_clear' => how.inbox_clear,
    'backup_first' => how.backup_first,
    'budget_first' => how.budget_first,
    'freelance_paid' => how.freelance_paid,
    _ => '',
  };
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
      child: Column(
        children: [
          SvgPicture.asset(ClayIcons.mascotSleeping, width: 110, height: 110),
          const SizedBox(height: 10),
          Text(t.stamps.empty.title, style: ds.typography.titleMd),
          const SizedBox(height: 6),
          Text(
            t.stamps.empty.body,
            textAlign: TextAlign.center,
            style: ds.typography.bodyMd.copyWith(color: ds.colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StampTile extends StatelessWidget {
  const _StampTile({required this.def, required this.earned, required this.order, required this.onTap});

  final MilestoneDef def;
  final EarnedMilestone? earned;
  final int order;
  final _TapHandler onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final name = stampName(def.id);
    final isEarned = earned != null;
    final isNew = isEarned && !earned!.seen;
    final subtitle = isEarned
        ? t.stamps.earnedOn(date: CycleMonthFormatter.formatDayMonth(earned!.earnedAt))
        : _howTo(def.id);
    final label = isEarned
        ? t.stamps.semantic.earned(name: name, date: CycleMonthFormatter.formatDayMonth(earned!.earnedAt))
        : t.stamps.semantic.locked(name: name);
    final seal = DsStampSeal(
      asset: stampAsset(def.id),
      semanticLabel: label,
      earned: isEarned,
      isNew: isNew,
      rotation: stampRotation(def.id),
      shine: true,
      shineDelay: Duration(milliseconds: 300 + order * 450),
    );
    return InkWell(
      onTap: () => onTap(def.id, earned: isEarned, isNew: isNew, body: _detailBody()),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 66),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (def.revealOnUse && isNew)
                _FlipIn(child: seal)
              else
                _CapIn(order: order, enabled: isEarned, child: seal),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: ds.typography.titleMd.copyWith(
                        color: isEarned ? c.textPrimary : c.textSecondary,
                        fontWeight: isEarned ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    Text(subtitle, style: ds.typography.bodySm.copyWith(color: c.textMuted)),
                  ],
                ),
              ),
              if (isNew)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: c.actionPrimary, shape: BoxShape.circle),
                )
              else
                Icon(Icons.chevron_right, size: 18, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  String _detailBody() {
    final entry = earned;
    return entry != null
        ? t.stamps.detail.earned(date: CycleMonthFormatter.formatDayMonth(entry.earnedAt), how: _howTo(def.id))
        : t.stamps.detail.locked(how: _howTo(def.id));
  }
}

/// Segel diraih "dicap" masuk berurutan saat layar tampil (rupa Kaya §9, hanya
/// di dalam Buku Stempel): skala turun dari besar dan berputar, jeda 90 ms per
/// baris. Mati bila gerak dikurangi.
class _CapIn extends StatelessWidget {
  const _CapIn({required this.order, required this.enabled, required this.child});

  final int order;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled || DsMotion.reduced(context)) return child;
    final delay = (order * 90).clamp(0, 900);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      curve: Interval(delay / (600 + delay), 1, curve: Curves.easeOutBack),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: 2.2 - 1.2 * t, child: child),
      ),
      child: child,
    );
  }
}

/// Tonggak tersembunyi yang baru terbuka "membalik" masuk (rupa Kaya §9,
/// `flipin` 800 ms): berputar dari tegak ke datar pada sumbu X. Mati bila gerak
/// dikurangi.
class _FlipIn extends StatelessWidget {
  const _FlipIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (DsMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0025)
            ..rotateX(-math.pi / 2 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
