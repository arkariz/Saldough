import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/core/presentation/widgets/stamp_visuals.dart';
import 'package:saldough/core/presentation/widgets/tanuki_bubble.dart';
import 'package:saldough/core/presentation/widgets/tanuki_pose.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';
import 'package:saldough/features/period_book/domain/services/tanuki_lines.dart';
import 'package:saldough/features/period_book/presentation/category_clay.dart';
import 'package:saldough/features/period_book/presentation/period_book_read_access.dart';
import 'package:saldough/features/period_book/presentation/tanuki_sentences.dart';
import 'package:saldough/features/period_book/presentation/widgets/book_visuals.dart';
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
          BookReady() => _body(context, load.content, load.stamps),
        },
      ),
    );
  }

  Widget _body(BuildContext context, PeriodBookContent content, List<String> stamps) {
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
                _ReportPage.tanuki => _TanukiPage(content: content, stamps: stamps, active: _index == i),
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
  const _FlowPage({required this.content, required this.showNote, required this.onFix});

  final PeriodBookContent content;
  final bool showNote;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final flow = content.flow;
    Widget tile(String asset, String label, int value) => Expanded(
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(child: SvgPicture.asset(asset, width: 26, height: 26)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label.toUpperCase(), style: ds.typography.pixelLabel.copyWith(color: c.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DsCountUp(
              value: value,
              builder: (_, v) => Text(AppMoneyFormatter.format(v), style: ds.typography.headlineSm),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(flow.net >= 0 ? t.book.report.flowPositive : t.book.report.flowNegative, asset: ClayIcons.bookOpen),
        StaggerIn(
          index: 0,
          // Selisih negatif tanpa warna peringatan (rupa D6): hero hijau yang sama.
          child: BookHero(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.book.report.net.toUpperCase(),
                        style: ds.typography.pixelLabel.copyWith(color: c.onHeroMuted),
                      ),
                    ),
                    ExcludeSemantics(child: SvgPicture.asset(ClayIcons.mascotHappy, width: 44, height: 44)),
                  ],
                ),
                DsCountUp(
                  value: flow.net,
                  builder: (_, v) => Text(
                    AppMoneyFormatter.format(v),
                    style: ds.typography.headlineLg.copyWith(
                      fontSize: 34,
                      height: 40 / 34,
                      fontWeight: FontWeight.w800,
                      color: c.onHero,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PairBars(
                  onDark: true,
                  labelA: t.book.report.income,
                  valueA: flow.income,
                  textA: AppMoneyFormatter.format(flow.income),
                  labelB: t.book.report.expense,
                  valueB: flow.expense,
                  textB: AppMoneyFormatter.format(flow.expense),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        StaggerIn(
          index: 2,
          child: Row(
            children: [
              tile('assets/icons_clay/income_arrow.svg', t.book.report.income, flow.income),
              const SizedBox(width: 12),
              tile('assets/icons_clay/expense_arrow.svg', t.book.report.expense, flow.expense),
            ],
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

  String _asset(BookSpendRow r) => switch (r.kind) {
    BookRowKind.freelance => categoryClayAsset('freelance'),
    BookRowKind.category => categoryClayAsset(r.builtInKey),
    BookRowKind.others => categoryClayAsset('expenseOther'),
    BookRowKind.uncategorized => 'assets/icons_clay/hourglass_pending.svg',
  };

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final spending = content.spending!;
    final palette = bookPalette(context);
    final total = spending.total == 0 ? 1 : spending.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(t.book.page.where, asset: 'assets/icons_clay/chart_investment.svg'),
        StaggerIn(
          index: 0,
          child: DsCard(
            child: Center(
              child: DonutChart(
                size: 210,
                fractions: [for (final r in spending.rows) r.amount / total],
                colors: [for (var i = 0; i < spending.rows.length; i++) palette[i % palette.length]],
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.book.report.expense.toUpperCase(),
                      style: ds.typography.pixelCaption.copyWith(color: c.textMuted),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppMoneyFormatter.format(spending.total),
                        style: ds.typography.headlineSm.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final (i, row) in spending.rows.indexed)
          StaggerIn(
            index: i + 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette[i % palette.length].withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(color: palette[i % palette.length], width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: ExcludeSemantics(child: SvgPicture.asset(_asset(row), width: 26, height: 26)),
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
                                style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              row.belowOne ? t.book.report.belowOne : '${row.percent}%',
                              style: ds.typography.pixelLabel.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                        Text(
                          AppMoneyFormatter.format(row.amount),
                          style: ds.typography.bodySm.copyWith(color: c.textMuted),
                        ),
                        const SizedBox(height: 6),
                        _Bar(
                          fraction: spending.total == 0 ? 0 : (row.amount / spending.total).clamp(0.0, 1.0),
                          color: palette[i % palette.length],
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
  const _Bar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return LayoutBuilder(
      builder: (context, box) => TweenAnimationBuilder<double>(
        tween: Tween(begin: DsMotion.reduced(context) ? fraction : 0, end: fraction),
        duration: const Duration(milliseconds: 900),
        curve: DsMotion.easeOutExpo,
        builder: (context, v, _) => Stack(
          children: [
            Container(
              height: 8,
              width: box.maxWidth,
              decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(4)),
            ),
            Container(
              height: 8,
              width: box.maxWidth * v,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
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
        _Heading(t.book.page.compare, asset: 'assets/icons_clay/report_bars.svg'),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            t.book.report.compareIntro(n: compare.months, count: compare.months),
            style: ds.typography.bodyMd.copyWith(color: c.textSecondary),
          ),
        ),
        for (final (i, h) in compare.highlights.indexed)
          StaggerIn(
            index: i,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              // Kartu netral: tanpa warna peringatan, tanpa penilaian (BP-7).
              decoration: BoxDecoration(
                color: c.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.outlineSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: c.surfaceSunken, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: ExcludeSemantics(
                          child: SvgPicture.asset(
                            h.kind == BookRowKind.freelance
                                ? categoryClayAsset('freelance')
                                : categoryClayAsset(h.builtInKey),
                            width: 26,
                            height: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          h.kind == BookRowKind.freelance ? t.book.report.freelance : (h.categoryName ?? ''),
                          style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          '${h.isHigher ? '+' : '−'}${h.percent}%',
                          style: ds.typography.pixelLabel.copyWith(color: c.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PairBars(
                    labelA: t.book.report.usual,
                    valueA: h.average,
                    textA: AppMoneyFormatter.format(h.average),
                    labelB: t.book.report.thisPeriod,
                    valueB: h.amount,
                    textB: AppMoneyFormatter.format(h.amount),
                    colorA: c.outlineStrong,
                    colorB: c.actionPrimary,
                  ),
                ],
              ),
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
    Widget stat(String asset, String label, int count) => Expanded(
      child: DsCard(
        child: Column(
          children: [
            ExcludeSemantics(child: SvgPicture.asset(asset, width: 40, height: 40)),
            const SizedBox(height: 8),
            DsCountUp(
              value: count,
              builder: (_, v) => Text('$v', style: ds.typography.headlineLg.copyWith(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: ds.typography.bodySm.copyWith(color: c.textMuted),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(t.book.page.recurring, asset: ClayIcons.shelfBooks),
        if (plan.hasRoutine)
          StaggerIn(
            index: 0,
            child: Row(
              children: [
                stat('assets/icons_clay/repeat_loop.svg', t.book.report.routineRecorded, plan.recorded),
                const SizedBox(width: 12),
                stat('assets/icons_clay/check_completed.svg', t.book.report.routineSkipped, plan.skipped),
              ],
            ),
          ),
        if (plan.hasBudget) ...[
          const SizedBox(height: 16),
          StaggerIn(
            index: 2,
            child: BookHero(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: SvgPicture.asset('assets/icons_clay/coins_currency.svg', width: 34, height: 34),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.book.report.planVsReal.toUpperCase(),
                          style: ds.typography.pixelLabel.copyWith(color: c.onHeroMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PairBars(
                    onDark: true,
                    labelA: t.book.ritual.planned,
                    valueA: plan.planned!,
                    textA: AppMoneyFormatter.format(plan.planned!),
                    labelB: t.book.ritual.spent,
                    valueB: plan.spent ?? 0,
                    textB: AppMoneyFormatter.format(plan.spent ?? 0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TanukiPage extends StatelessWidget {
  const _TanukiPage({required this.content, required this.stamps, required this.active});

  final PeriodBookContent content;
  final List<String> stamps;

  /// Halaman ini yang tampil: balon baru mulai mengetik (rupa D6).
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final sentences = tanukiSentences(tanukiLinesOf(content)).join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(t.book.page.tanuki),
        StaggerIn(
          index: 0,
          child: BookScene(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(
                children: [
                  TanukiPose(
                    pose: content.flow.net >= 0 ? TanukiPoseKind.happy : TanukiPoseKind.calm,
                    size: 150,
                    cheer: active ? 1 : 0,
                  ),
                  const SizedBox(height: 12),
                  TanukiBubble(message: active ? sentences : ''),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        StaggerIn(
          index: 2,
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ExcludeSemantics(child: SvgPicture.asset(ClayIcons.stampBook, width: 30, height: 30)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.book.report.stampsTitle,
                        style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (stamps.isEmpty)
                  Text(t.book.report.stampsNone, style: ds.typography.bodySm.copyWith(color: c.textMuted))
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final id in stamps)
                        Column(
                          children: [
                            DsStampSeal(
                              asset: stampAsset(id),
                              semanticLabel: stampName(id),
                              rotation: stampRotation(id),
                            ),
                            const SizedBox(height: 4),
                            Text(stampName(id), style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        StaggerIn(
          index: 3,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color.alphaBlend(c.actionPrimary.withValues(alpha: 0.08), c.surfaceCard),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ExcludeSemantics(child: SvgPicture.asset(ClayIcons.shelfBooks, width: 34, height: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t.book.report.closing, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
