import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/tanuki_pose.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/period_book/domain/entities/ritual_info.dart';
import 'package:saldough/features/period_book/presentation/period_book_ritual_access.dart';
import 'package:saldough/features/period_book/presentation/widgets/book_visuals.dart';

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

  /// Langkah yang sudah selesai (ditandai Lanjut), untuk lencana di linimasa.
  final Set<RitualStep> _done = {};

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
        if (first) {
          _step = load.resume;
          _done.addAll(RitualStep.values.where((st) => st.index < load.resume.index));
        }
      }
    });
  }

  Future<void> _next({required bool done}) async {
    if (done) await widget.access.markStepDone(widget.periodId, _step);
    if (!mounted) return;
    setState(() {
      if (done) _done.add(_step);
      _step = RitualStep.values[_step.index + 1];
    });
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
    final last = _step == RitualStep.review;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _Hero(period: info.period.period.name),
              const SizedBox(height: 16),
              for (final step in RitualStep.values) ...[
                _StepCard(
                  step: step,
                  state: step == _step
                      ? _StepState.current
                      : (_done.contains(step) ? _StepState.done : (step.index < _step.index ? _StepState.passed : _StepState.next)),
                  info: info,
                  child: switch (step) {
                    RitualStep.uncategorized => _Uncategorized(info: info, access: widget.access, onChanged: _reload),
                    RitualStep.routines => _Routines(info: info, access: widget.access),
                    RitualStep.review => _Review(info: info),
                  },
                ),
                if (step != RitualStep.review) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: last
              ? DsSheen(
                  child: DsButton(label: t.book.ritual.finish, onPressed: _closing ? null : () => unawaited(_finish()), expand: true),
                )
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

/// Kepala ritual: adegan dengan Tanuki menulis dan kalimat pembuka.
class _Hero extends StatelessWidget {
  const _Hero({required this.period});

  final String period;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return BookScene(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            const TanukiPose(pose: TanukiPoseKind.writing, size: 104),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(period.toUpperCase(), style: ds.typography.pixelLabel.copyWith(color: ds.colors.actionPrimary)),
                  const SizedBox(height: 4),
                  Text(t.book.ritual.hero, style: ds.typography.headlineSm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _StepState { done, current, passed, next }

/// Satu kartu langkah di linimasa ritual: ikon clay dengan lencana, judul, dan
/// ringkasan; kartu langkah sekarang terbuka dan memuat isinya.
class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.state, required this.info, required this.child});

  final RitualStep step;
  final _StepState state;
  final RitualInfo info;
  final Widget child;

  String get _asset => switch (step) {
    RitualStep.uncategorized => 'assets/icons_clay/tag_category.svg',
    RitualStep.routines => 'assets/icons_clay/repeat_loop.svg',
    RitualStep.review => 'assets/icons_clay/report_bars.svg',
  };

  String get _title => switch (step) {
    RitualStep.uncategorized => t.book.ritual.stepTitle.uncategorized,
    RitualStep.routines => t.book.ritual.stepTitle.routines,
    RitualStep.review => t.book.ritual.stepTitle.review,
  };

  String get _summary => switch (step) {
    RitualStep.uncategorized =>
      info.untagged.isEmpty ? t.book.ritual.summaryTidy : t.book.ritual.uncategorized.some(n: info.untagged.length, count: info.untagged.length),
    RitualStep.routines =>
      info.openRoutines == 0 ? t.book.ritual.recurring.none : t.book.ritual.recurring.some(n: info.openRoutines, count: info.openRoutines),
    RitualStep.review => info.hasReview ? t.book.ritual.summaryReview : t.book.ritual.noPlan,
  };

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final current = state == _StepState.current;
    final done = state == _StepState.done;
    final status = switch (state) {
      _StepState.done => t.book.ritual.status.done,
      _StepState.current => t.book.ritual.status.current,
      _StepState.next => t.book.ritual.status.next,
      _StepState.passed => null,
    };
    return AnimatedContainer(
      duration: DsMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: current
            ? c.surfaceCard
            : (done ? Color.alphaBlend(c.actionPrimary.withValues(alpha: 0.07), c.surfaceCard) : c.surfaceSunken),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: current ? c.actionPrimary : c.outlineSubtle, width: current ? 1.6 : 1),
        boxShadow: current ? [BoxShadow(color: c.actionPrimary.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 6))] : null,
      ),
      child: _MaybeAnimatedSize(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: c.surfaceCard, shape: BoxShape.circle, border: Border.all(color: c.outlineSubtle)),
                      alignment: Alignment.center,
                      child: ExcludeSemantics(child: SvgPicture.asset(_asset, width: 28, height: 28)),
                    ),
                    if (done)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: _Pop(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(color: c.actionPrimary, shape: BoxShape.circle, border: Border.all(color: c.surfaceCard, width: 2)),
                            child: Icon(Icons.check, size: 12, color: c.onActionPrimary),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_title, style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w700)),
                      if (!current) Text(_summary, style: ds.typography.bodySm.copyWith(color: c.textMuted)),
                    ],
                  ),
                ),
                if (status != null) DsBadge(label: status.toUpperCase(), tone: current ? DsBadgeTone.income : DsBadgeTone.neutral),
              ],
            ),
            if (current) ...[const SizedBox(height: 14), child],
          ],
        ),
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

/// `AnimatedSize` bila gerak penuh; anak apa adanya bila dikurangi (durasi nol
/// melanggar pernyataan layout Flutter).
class _MaybeAnimatedSize extends StatelessWidget {
  const _MaybeAnimatedSize({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (DsMotion.reduced(context)) return child;
    return AnimatedSize(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic, alignment: Alignment.topCenter, child: child);
  }
}
