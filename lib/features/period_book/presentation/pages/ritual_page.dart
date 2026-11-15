import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/tanuki_pose.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/period_book/domain/entities/ritual_info.dart';
import 'package:saldough/features/period_book/presentation/period_book_ritual_access.dart';

/// Ritual Tutup buku (rupa D4, BP-5, BP-6): tiga langkah (tanpa kategori, rutin
/// menunggu, kilas balik) yang **semuanya boleh dilewati**. Tidak mengunci atau
/// mengubah data; menutup di tengah menyimpan langkah yang selesai.
///
/// Tombol penutup menandai buku dibuka lalu menutup layar (konfeti kecil, gerak
/// dikurangi mematikannya). Sampul dan stempel menyusul di T-27.6.
class RitualPage extends StatefulWidget {
  /// Membuat [RitualPage].
  const RitualPage({required this.access, required this.periodId, super.key});

  /// Pintu ke data dan tindakan.
  final PeriodBookRitualAccess access;

  /// Id periode yang ditutup.
  final String periodId;

  @override
  State<RitualPage> createState() => _RitualPageState();
}

class _RitualPageState extends State<RitualPage> {
  RitualLoad? _load;
  RitualInfo? _info;
  RitualStep _step = RitualStep.uncategorized;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_reload(first: true));
  }

  Future<void> _reload({bool first = false}) async {
    final load = await widget.access.load(widget.periodId);
    if (!mounted) return;
    setState(() {
      _load = load;
      if (load is RitualReady) {
        _info = load.info;
        if (first) _step = load.resume;
      }
    });
  }

  Future<void> _next({required bool done}) async {
    if (done) await widget.access.markStepDone(widget.periodId, _step);
    if (!mounted) return;
    setState(() => _step = RitualStep.values[_step.index + 1]);
  }

  Future<void> _finish() async {
    if (_closing) return;
    setState(() => _closing = true);
    await widget.access.markStepDone(widget.periodId, _step);
    await widget.access.finish(widget.periodId);
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      DsShapeConfetti.burst(context, origin: box.localToGlobal(box.size.center(Offset.zero)), count: 40);
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final info = _info;
    final title = info == null ? t.book.ritual.title(period: '') .trim() : t.book.ritual.title(period: info.period.period.name);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(false)),
        title: Text(title, style: ds.typography.headlineMd),
      ),
      body: SafeArea(
        child: switch (_load) {
          null => const Center(child: CircularProgressIndicator()),
          RitualLocked() || RitualFailed() => const SizedBox.shrink(),
          RitualReady() => _content(context, info!),
        },
      ),
    );
  }

  Widget _content(BuildContext context, RitualInfo info) {
    final ds = context.ds;
    final last = _step == RitualStep.review;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _StepBar(current: _step.index),
              const SizedBox(height: 16),
              Row(
                children: [
                  const TanukiPose(pose: TanukiPoseKind.writing, size: 72),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      info.period.period.name,
                      style: ds.typography.pixelLabel.copyWith(color: ds.colors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: DsMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    RitualStep.uncategorized => _Uncategorized(info: info, access: widget.access, onChanged: _reload),
                    RitualStep.routines => _Routines(info: info, access: widget.access),
                    RitualStep.review => _Review(info: info),
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: last
              ? DsButton(label: t.book.ritual.finish, onPressed: _closing ? null : () => unawaited(_finish()), expand: true)
              : Row(
                  children: [
                    Expanded(
                      child: DsButton.ghost(
                        label: t.book.ritual.skip,
                        onPressed: () => unawaited(_next(done: false)),
                        expand: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DsButton(label: t.book.ritual.next, onPressed: () => unawaited(_next(done: true)), expand: true),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return Semantics(
      label: t.book.ritual.step(current: current + 1, total: RitualStep.values.length),
      excludeSemantics: true,
      child: Row(
        children: [
          for (final step in RitualStep.values) ...[
            Expanded(
              child: AnimatedContainer(
                duration: DsMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 250),
                height: 6,
                decoration: BoxDecoration(
                  color: step.index <= current ? c.actionPrimary : c.outlineSubtle,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (step != RitualStep.values.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _Uncategorized extends StatelessWidget {
  const _Uncategorized({required this.info, required this.access, required this.onChanged});

  final RitualInfo info;
  final PeriodBookRitualAccess access;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    if (info.untagged.isEmpty) {
      return Row(
        children: [
          _Pop(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: c.actionPrimary, shape: BoxShape.circle),
              child: Icon(Icons.check, size: 18, color: c.onActionPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(t.book.ritual.uncategorized.none, style: ds.typography.headlineSm)),
        ],
      );
    }
    final count = info.untagged.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.book.ritual.uncategorized.some(n: count, count: count), style: ds.typography.headlineSm),
        const SizedBox(height: 12),
        // Wadah hangat, bukan merah: tidak ada yang salah, hanya belum lengkap (BP-6).
        Container(
          decoration: BoxDecoration(color: c.toneWarmContainer, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              for (final tx in info.untagged.take(2))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.note.isEmpty ? CycleMonthFormatter.formatDayMonth(tx.date) : tx.note,
                              style: ds.typography.bodyMd,
                            ),
                            if (tx.note.isNotEmpty)
                              Text(
                                CycleMonthFormatter.formatDayMonth(tx.date),
                                style: ds.typography.bodySm.copyWith(color: c.onToneWarmContainer),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        AppMoneyFormatter.format(tx.isIncome ? tx.amount : -tx.amount),
                        style: ds.typography.bodyMd.copyWith(color: c.onToneWarmContainer),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DsButton.secondary(
          label: t.book.ritual.fix,
          onPressed: () async {
            await access.categorize(context, info.untagged.first.transactionId);
            await onChanged();
          },
        ),
      ],
    );
  }
}

class _Routines extends StatelessWidget {
  const _Routines({required this.info, required this.access});

  final RitualInfo info;
  final PeriodBookRitualAccess access;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    if (info.openRoutines == 0) {
      return Text(t.book.ritual.recurring.none, style: ds.typography.headlineSm);
    }
    final count = info.openRoutines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.book.ritual.recurring.some(n: count, count: count), style: ds.typography.headlineSm),
        const SizedBox(height: 12),
        DsButton.secondary(label: t.book.ritual.seeRoutines, onPressed: () => access.showRecurring(context)),
      ],
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.info});

  final RitualInfo info;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    Widget tile(String label, int sen) => Expanded(
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: ds.typography.pixelLabel.copyWith(color: c.textMuted)),
            const SizedBox(height: 4),
            Text(AppMoneyFormatter.format(sen), style: ds.typography.headlineSm),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(info.hasReview ? t.book.ritual.review : t.book.ritual.noPlan, style: ds.typography.headlineSm),
        if (info.hasReview) ...[
          const SizedBox(height: 12),
          Row(
            children: [tile(t.book.ritual.planned, info.planned!), const SizedBox(width: 12), tile(t.book.ritual.spent, info.spent ?? 0)],
          ),
        ],
        const SizedBox(height: 16),
        DsInlineBanner(
          icon: Icons.info_outline,
          message: t.book.ritual.note,
        ),
      ],
    );
  }
}

/// Lingkaran centang muncul dengan pantulan kecil (rupa D4, `pop`).
class _Pop extends StatelessWidget {
  const _Pop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (DsMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: child,
    );
  }
}
