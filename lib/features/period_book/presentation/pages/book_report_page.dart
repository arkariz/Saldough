import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/core/presentation/widgets/tanuki_bubble.dart';
import 'package:saldough/core/presentation/widgets/tanuki_pose.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';
import 'package:saldough/features/period_book/domain/services/tanuki_lines.dart';
import 'package:saldough/features/period_book/presentation/category_clay.dart';
import 'package:saldough/features/period_book/presentation/period_book_read_access.dart';
import 'package:saldough/features/period_book/presentation/tanuki_sentences.dart';
import 'package:saldough/features/period_book/presentation/widgets/stagger_in.dart';

/// Rapor lima halaman (rupa D6, T-27.6): Arus, Ke mana uang pergi, Dibanding
/// biasanya, Rutin dan rencana, Kata Tanuki. Halaman dengan data kosong
/// dilewati dan titik halaman menyesuaikan. **Tanpa warna peringatan, tanpa
/// penilaian, tanpa perbandingan dengan pengguna lain** (BP-7). Angka dari
/// model baca yang sama dengan Beranda dan Analisis (BP-4); nominal ikut
/// Sembunyikan nominal lewat `AppMoneyFormatter`.
class BookReportPage extends StatefulWidget {
  /// Membuat [BookReportPage].
  const BookReportPage({
    required this.access,
    required this.periodId,
    super.key,
  });

  /// Pintu ke data.
  final PeriodBookReadAccess access;

  /// Id periode.
  final String periodId;

  @override
  State<BookReportPage> createState() => _BookReportPageState();
}

enum _ReportPage { flow, where, compare, plan, tanuki }

class _BookReportPageState extends State<BookReportPage> {
  BookLoad? _load;
  final _controller = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.access.open(widget.periodId).then((load) {
        if (mounted) setState(() => _load = load);
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_ReportPage> _pagesOf(PeriodBookContent c) => [
    _ReportPage.flow,
    if (c.spending != null) _ReportPage.where,
    if (c.compare != null && c.compare!.highlights.isNotEmpty) _ReportPage.compare,
    if (c.plan != null) _ReportPage.plan,
    _ReportPage.tanuki,
  ];

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final load = _load;
    final title = load is BookReady ? load.content.period.period.name : '';
    return Scaffold(
      appBar: AppBar(title: Text(title, style: ds.typography.headlineMd)),
      body: SafeArea(
        child: switch (load) {
          null => const Center(child: CircularProgressIndicator()),
          BookLocked() || BookFailed() => const SizedBox.shrink(),
          BookReady() => _body(context, load.content),
        },
      ),
    );
  }

  Widget _body(BuildContext context, PeriodBookContent content) {
    final pages = _pagesOf(content);
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: switch (pages[i]) {
                _ReportPage.flow => _FlowPage(
                  content: content,
                  showNote: content.spending == null,
                  onFix: () => widget.access.categorizeFirstUntagged(
                    context,
                    widget.periodId,
                  ),
                ),
                _ReportPage.where => _WherePage(
                  content: content,
                  onFix: () => widget.access.categorizeFirstUntagged(
                    context,
                    widget.periodId,
                  ),
                ),
                _ReportPage.compare => _ComparePage(compare: content.compare!),
                _ReportPage.plan => _PlanPage(plan: content.plan!),
                _ReportPage.tanuki => _TanukiPage(
                  content: content,
                  active: _index == i,
                ),
              },
            ),
          ),
        ),
        _Dots(count: pages.length, current: _index),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final reduced = DsMotion.reduced(context);
    return Semantics(
      label: t.book.page.label(current: current + 1, total: count),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: reduced ? Duration.zero : const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == current ? c.actionPrimary : c.outlineStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.asset});

  final String text;

  /// Ikon clay dekoratif di sisi kiri judul (rupa D6).
  final String? asset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        if (asset != null) ...[
          ExcludeSemantics(
            child: SvgPicture.asset(asset!, width: 30, height: 30),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Semantics(
            header: true,
            child: Text(text, style: context.ds.typography.headlineSm),
          ),
        ),
      ],
    ),
  );
}

/// Catatan netral bila ada transaksi tanpa kategori (rupa D6).
class _Note extends StatelessWidget {
  const _Note({required this.count, required this.onFix});

  final int count;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.book.report.noteUncategorized(n: count, count: count),
            style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted),
          ),
          DsButton.ghost(label: t.book.ritual.fix, onPressed: onFix),
        ],
      ),
    );
  }
}

class _FlowPage extends StatelessWidget {
  const _FlowPage({
    required this.content,
    required this.showNote,
    required this.onFix,
  });

  final PeriodBookContent content;
  final bool showNote;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final flow = content.flow;
    Widget tile(String label, int value) => Expanded(
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: ds.typography.pixelLabel.copyWith(
                color: ds.colors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            DsCountUp(
              value: value,
              builder: (_, v) => Text(
                AppMoneyFormatter.format(v),
                style: ds.typography.headlineSm,
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(
          flow.net >= 0 ? t.book.report.flowPositive : t.book.report.flowNegative,
          asset: ClayIcons.bookOpen,
        ),
        StaggerIn(
          index: 0,
          child: Row(
            children: [
              tile(t.book.report.income, flow.income),
              const SizedBox(width: 12),
              tile(t.book.report.expense, flow.expense),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StaggerIn(
          index: 2,
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.book.report.net.toUpperCase(),
                  style: ds.typography.pixelLabel.copyWith(
                    color: ds.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                // Selisih negatif tanpa warna peringatan (rupa D6): teks utama biasa.
                DsCountUp(
                  value: flow.net,
                  builder: (_, v) => Text(
                    AppMoneyFormatter.format(v),
                    style: ds.typography.headlineLg.copyWith(
                      fontSize: 32,
                      height: 38 / 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showNote) _Note(count: content.uncategorizedCount, onFix: onFix),
      ],
    );
  }
}

class _WherePage extends StatelessWidget {
  const _WherePage({required this.content, required this.onFix});

  final PeriodBookContent content;
  final VoidCallback onFix;

  String _name(BookSpendRow r) => switch (r.kind) {
    BookRowKind.category => r.categoryName ?? '',
    BookRowKind.freelance => t.book.report.freelance,
    BookRowKind.uncategorized => t.book.report.uncategorized,
    BookRowKind.others => t.book.report.others,
  };

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final spending = content.spending!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(t.book.page.where),
        for (final (i, row) in spending.rows.indexed)
          StaggerIn(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c.surfaceSunken,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: ExcludeSemantics(
                      child: SvgPicture.asset(
                        row.kind == BookRowKind.freelance
                            ? categoryClayAsset('freelance')
                            : categoryClayAsset(
                                row.kind == BookRowKind.category
                                    ? row.builtInKey
                                    : (row.kind == BookRowKind.others ? 'expenseOther' : 'tag_none'),
                              ),
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _name(row),
                                style: ds.typography.bodyMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              row.belowOne ? t.book.report.belowOne : '${row.percent}%',
                              style: ds.typography.pixelLabel.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          AppMoneyFormatter.format(row.amount),
                          style: ds.typography.bodySm.copyWith(
                            color: c.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _Bar(
                          fraction: spending.total == 0 ? 0 : (row.amount / spending.total).clamp(0.0, 1.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        _Note(count: content.uncategorizedCount, onFix: onFix),
      ],
    );
  }
}

/// Batang yang memanjang 900 ms `easeOutExpo` (rupa D6); langsung penuh bila
/// gerak dikurangi.
class _Bar extends StatelessWidget {
  const _Bar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return LayoutBuilder(
      builder: (context, box) => TweenAnimationBuilder<double>(
        tween: Tween(
          begin: DsMotion.reduced(context) ? fraction : 0,
          end: fraction,
        ),
        duration: const Duration(milliseconds: 900),
        curve: DsMotion.easeOutExpo,
        builder: (context, v, _) => Stack(
          children: [
            Container(
              height: 8,
              width: box.maxWidth,
              decoration: BoxDecoration(
                color: c.surfaceSunken,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 8,
              width: box.maxWidth * v,
              decoration: BoxDecoration(
                color: c.actionPrimary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparePage extends StatelessWidget {
  const _ComparePage({required this.compare});

  final BookCompare compare;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(t.book.page.compare),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            t.book.report.compareIntro(
              n: compare.months,
              count: compare.months,
            ),
            style: ds.typography.bodyMd.copyWith(color: c.textSecondary),
          ),
        ),
        for (final h in compare.highlights)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            // Ubin netral: tanpa warna peringatan, tanpa penilaian (BP-7).
            decoration: BoxDecoration(
              color: c.surfaceSunken,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.kind == BookRowKind.freelance ? t.book.report.freelance : (h.categoryName ?? ''),
                        style: ds.typography.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.book.report.usual} ${AppMoneyFormatter.format(h.average)} · ${t.book.report.thisPeriod} ${AppMoneyFormatter.format(h.amount)}',
                        style: ds.typography.bodySm.copyWith(
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${h.isHigher ? '+' : '−'}${h.percent}%',
                  style: ds.typography.pixelLabel.copyWith(
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanPage extends StatelessWidget {
  const _PlanPage({required this.plan});

  final BookPlan plan;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    Widget row(String label, int count) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DsCard(
        child: Row(
          children: [
            Expanded(child: Text(label, style: ds.typography.bodyMd)),
            Text(
              '$count',
              style: ds.typography.pixelLabel.copyWith(color: c.textPrimary),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(t.book.page.recurring),
        if (plan.hasRoutine) ...[
          row(t.book.report.routineRecorded, plan.recorded),
          row(t.book.report.routineSkipped, plan.skipped),
        ],
        if (plan.hasBudget) ...[
          const SizedBox(height: 8),
          Text(
            t.book.report.planVsReal,
            style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DsSegmentMeter(
                  value: plan.planned! == 0 ? 0 : ((plan.spent ?? 0) / plan.planned!).clamp(0.0, 1.0),
                  semanticLabel: t.book.report.planVsReal,
                ),
                const SizedBox(height: 8),
                Text(
                  '${t.book.ritual.planned} ${AppMoneyFormatter.format(plan.planned!)} · ${t.book.ritual.spent} ${AppMoneyFormatter.format(plan.spent ?? 0)}',
                  style: ds.typography.bodySm.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TanukiPage extends StatelessWidget {
  const _TanukiPage({required this.content, required this.active});

  final PeriodBookContent content;

  /// Halaman ini yang tampil: balon baru mulai mengetik (rupa D6).
  final bool active;

  @override
  Widget build(BuildContext context) {
    final sentences = tanukiSentences(tanukiLinesOf(content)).join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(t.book.page.tanuki),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TanukiPose(pose: content.flow.net >= 0 ? TanukiPoseKind.happy : TanukiPoseKind.calm, size: 96, cheer: active ? 1 : 0),
            const SizedBox(width: 10),
            Expanded(child: TanukiBubble(message: active ? sentences : '')),
          ],
        ),
      ],
    );
  }
}
