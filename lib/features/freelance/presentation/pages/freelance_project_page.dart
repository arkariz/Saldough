import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_bloc.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';
import 'package:saldough/features/freelance/presentation/freelance_actions.dart';
import 'package:saldough/features/freelance/presentation/freelance_format.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_cards.dart';
import 'package:saldough/features/freelance/presentation/widgets/project_widgets.dart';
import 'package:state_management/state_management.dart';

/// Membuka rincian [project] di atas Ikhtisar Freelance, memakai
/// `FreelanceBloc` yang sama. Snackbar hasil aksinya tetap tampil lewat
/// `EffectListener` milik Ikhtisar Freelance di bawahnya.
///
/// [showPayments] membuka tab Pembayaran lebih dulu (dari tab Pembayaran di
/// Ikhtisar Freelance); bawaannya tab Worklog.
Future<void> openFreelanceProject(BuildContext context, FreelanceProject project, {bool showPayments = false}) {
  final bloc = context.read<FreelanceBloc>();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PixelTheme(
        child: BlocProvider.value(
          value: bloc,
          child: FreelanceProjectPage(projectId: project.id, showPayments: showPayments),
        ),
      ),
    ),
  );
}

/// Penyaring status entri di rincian proyek.
enum EntryFilter {
  /// Semua entri.
  all,

  /// Belum ditagih — bawaan, karena inilah yang paling sering diurus.
  unbilled,

  /// Masuk pembayaran yang belum diterima.
  pending,

  /// Pembayarannya sudah diterima.
  paid;

  /// Apakah entri berstatus [status] lolos penyaring ini.
  bool matches(EntryBillingStatus status) => switch (this) {
    EntryFilter.all => true,
    EntryFilter.unbilled => status == EntryBillingStatus.unbilled,
    EntryFilter.pending => status == EntryBillingStatus.pending,
    EntryFilter.paid => status == EntryBillingStatus.paid,
  };
}

/// Penyaring status pembayaran di rincian proyek.
enum PaymentFilter {
  /// Semua pembayaran.
  all,

  /// Tertunda — bawaan, karena inilah uang yang masih ditunggu.
  pending,

  /// Sudah diterima.
  paid;

  /// Apakah [payment] lolos penyaring ini.
  bool matches(FreelancePayment payment) => switch (this) {
    PaymentFilter.all => true,
    PaymentFilter.pending => !payment.isPaid,
    PaymentFilter.paid => payment.isPaid,
  };
}

/// Rincian satu proyek freelance: tarif dan potongan, angka proyek, lalu
/// entri worklognya sendiri — disaring per status dan dikelompokkan per
/// bulan dengan subtotal, dimuat bertahap supaya tetap ringan walau entrinya
/// ratusan. Bilah aksi di dasar layar: tambah worklog untuk proyek ini dan
/// tagih entri yang belum ditagih.
class FreelanceProjectPage extends StatefulWidget {
  /// Membuat [FreelanceProjectPage].
  const FreelanceProjectPage({required this.projectId, this.showPayments = false, super.key});

  /// Proyek yang ditampilkan; dibaca ulang dari state tiap kali berubah.
  final String projectId;

  /// Membuka tab Pembayaran lebih dulu.
  final bool showPayments;

  @override
  State<FreelanceProjectPage> createState() => _FreelanceProjectPageState();
}

class _FreelanceProjectPageState extends State<FreelanceProjectPage> {
  late EntryFilter _entryFilter;
  late PaymentFilter _paymentFilter;

  @override
  void initState() {
    super.initState();
    final state = context.read<FreelanceBloc>().state;
    // Bawaan "belum ditagih" dan "tertunda", kecuali proyek ini tidak punya
    // yang seperti itu — jangan membuka daftar kosong padahal ada isinya.
    final stats = state.statsOf(widget.projectId);
    _entryFilter = stats.unbilledCount == 0 && stats.entryCount > 0 ? EntryFilter.all : EntryFilter.unbilled;
    final payments = state.paymentStatsOf(widget.projectId);
    _paymentFilter = payments.pendingCount == 0 && payments.paidCount > 0 ? PaymentFilter.all : PaymentFilter.pending;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FreelanceBloc, FreelanceState>(
      builder: (context, state) {
        final project = state.projectOf(widget.projectId);
        if (project == null) {
          // Proyek baru saja dihapus dari formulirnya.
          return const Scaffold(body: SizedBox.shrink());
        }
        final stats = state.statsOf(project.id);
        final entries = state.entriesOfProject(project.id);
        final payments = state.paymentsOfProject(project.id);
        return DefaultTabController(
          length: 2,
          initialIndex: widget.showPayments ? 1 : 0,
          child: Scaffold(
            appBar: AppBar(
              title: Text(project.name),
              actions: [
                IconButton(
                  tooltip: t.freelance.projectEditTitle,
                  icon: const AppIcon(IconKey.edit),
                  onPressed: () async {
                    final deleted = await editProject(context, project);
                    if (deleted && context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: t.freelance.worklogTab(count: entries.length)),
                  Tab(text: t.freelance.paymentsTab(count: payments.length)),
                ],
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: [
                        _worklogList(state, project, stats, entries),
                        _paymentList(state, project, stats, payments),
                      ],
                    ),
                  ),
                  FreelanceBottomBar(
                    children: [
                      AppButton(
                        label: t.freelance.entryAddShortAction,
                        onPressed: () => addEntry(context, projectId: project.id),
                      ),
                      AppButton(
                        label: t.freelance.billAction(count: stats.unbilledCount),
                        color: context.appColors.pending,
                        onPressed: stats.unbilledCount == 0
                            ? null
                            : () => createPayment(context, projectId: project.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _worklogList(FreelanceState state, FreelanceProject project, ProjectStats stats, List<WorklogEntry> entries) {
    final counts = {
      for (final filter in EntryFilter.values) filter: entries.where((e) => filter.matches(state.statusOf(e))).length,
    };
    final rows = _entryRows(entries.where((e) => _entryFilter.matches(state.statusOf(e))).toList());
    String label(EntryFilter filter) => switch (filter) {
      EntryFilter.all => t.freelance.filterAll,
      EntryFilter.unbilled => t.freelance.statusUnbilled,
      EntryFilter.pending => t.freelance.statusPending,
      EntryFilter.paid => t.freelance.statusPaid,
    };
    return _SectionList(
      header: _ProjectHeader(project: project, stats: stats),
      filters: _FilterRow<EntryFilter>(
        options: [for (final filter in EntryFilter.values) (filter, '${label(filter)} (${counts[filter]})')],
        selected: _entryFilter,
        onChanged: (filter) => setState(() => _entryFilter = filter),
      ),
      rows: rows,
      empty: entries.isEmpty
          ? FreelanceEmptyState(
              badge: t.freelance.entriesEmptyBadge,
              title: t.freelance.entriesEmptyTitle,
              body: t.freelance.entriesEmptyBody,
              icons: const [IconKey.worklog, IconKey.calendar, IconKey.workCompleted],
            )
          : _FilteredEmpty(t.freelance.entriesFilteredEmpty),
      buildRow: (context, row) => switch (row) {
        _MonthRow(:final month, :final hours, :final amount) => WorklogMonthHeader(
          month: month,
          hours: hours,
          amount: amount,
        ),
        _EntryRow(:final entry) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: WorklogEntryCard(
            entry: entry,
            payment: state.paymentOf(entry),
            walletName: switch (state.paymentOf(entry)?.walletId) {
              final walletId? => state.walletOf(walletId)?.name,
              null => null,
            },
            onTap: state.paymentOf(entry) == null ? () => editEntry(context, entry) : null,
          ),
        ),
        _PaymentRow() => const SizedBox.shrink(),
      },
    );
  }

  Widget _paymentList(
    FreelanceState state,
    FreelanceProject project,
    ProjectStats stats,
    List<FreelancePayment> payments,
  ) {
    final counts = {for (final filter in PaymentFilter.values) filter: payments.where(filter.matches).length};
    final rows = _paymentRows(state, payments.where(_paymentFilter.matches).toList());
    String label(PaymentFilter filter) => switch (filter) {
      PaymentFilter.all => t.freelance.filterAll,
      PaymentFilter.pending => t.freelance.statusPending,
      PaymentFilter.paid => t.freelance.statusPaid,
    };
    return _SectionList(
      header: _ProjectHeader(project: project, stats: stats),
      filters: _FilterRow<PaymentFilter>(
        options: [for (final filter in PaymentFilter.values) (filter, '${label(filter)} (${counts[filter]})')],
        selected: _paymentFilter,
        onChanged: (filter) => setState(() => _paymentFilter = filter),
      ),
      rows: rows,
      empty: payments.isEmpty
          ? FreelanceEmptyState(
              badge: t.freelance.paymentsEmptyBadge,
              title: t.freelance.paymentsEmptyTitle,
              body: t.freelance.paymentsEmptyBody,
              icons: const [IconKey.invoice, IconKey.pending, IconKey.paid],
            )
          : _FilteredEmpty(t.freelance.paymentsFilteredEmpty),
      buildRow: (context, row) => switch (row) {
        _MonthRow(:final month, :final hours, :final amount) => WorklogMonthHeader(
          month: month,
          hours: hours,
          amount: amount,
        ),
        _PaymentRow(:final payment) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _PaymentCard(state: state, payment: payment),
        ),
        _EntryRow() => const SizedBox.shrink(),
      },
    );
  }

  /// Entri yang terlihat, disisipi judul bulan dengan subtotalnya.
  static List<_Row> _entryRows(List<WorklogEntry> entries) =>
      _grouped([for (final entry in entries) (entry.date, entry.hours, entry.earnedAmount, _EntryRow(entry))]);

  /// Pembayaran yang terlihat per bulan tanggalnya (diterima, atau
  /// perkiraan), dengan subtotal jam dan gaji bersih.
  static List<_Row> _paymentRows(FreelanceState state, List<FreelancePayment> payments) => _grouped([
    for (final payment in payments)
      (
        state.paymentDateOf(payment),
        state.entriesOf(payment).fold(0, (sum, e) => sum + e.hours),
        state.breakdownOf(payment).netPay,
        _PaymentRow(payment),
      ),
  ]);

  static List<_Row> _grouped(List<(DateTime, int, int, _Row)> items) {
    final rows = <_Row>[];
    DateTime? month;
    var headerIndex = -1;
    for (final (date, hours, amount, row) in items) {
      final itemMonth = DateTime(date.year, date.month);
      if (itemMonth != month) {
        month = itemMonth;
        headerIndex = rows.length;
        rows.add(_MonthRow(itemMonth, 0, 0));
      }
      final header = rows[headerIndex] as _MonthRow;
      rows[headerIndex] = _MonthRow(itemMonth, header.hours + hours, header.amount + amount);
      rows.add(row);
    }
    return rows;
  }
}

/// Kartu satu pembayaran di rincian proyek, berjudul rentang tanggal kerja
/// yang ditagihnya, beserta aksinya.
class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.state, required this.payment});

  final FreelanceState state;
  final FreelancePayment payment;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final entries = state.entriesOf(payment);
    final range = switch (entries) {
      [] => '',
      [final first, ..., final last] when !DateUtils.isSameDay(first.date, last.date) =>
        '${CycleMonthFormatter.formatDateShort(first.date)} – ${CycleMonthFormatter.formatDateShort(last.date)}',
      [final first, ...] => CycleMonthFormatter.formatDateShort(first.date),
    };
    return FreelancePaymentCard(
      payment: payment,
      title: t.freelance.paymentWorkRange(range: range),
      breakdown: state.breakdownOf(payment),
      entryCount: entries.length,
      hours: entries.fold(0, (sum, e) => sum + e.hours),
      walletName: switch (payment.walletId) {
        final walletId? => state.walletOf(walletId)?.name,
        null => null,
      },
      actions: payment.isPaid
          ? [TextButton(onPressed: () => cancelReceipt(context, payment), child: Text(t.freelance.receiptCancelAction))]
          : [
              AppButton(
                label: t.freelance.receiveAction,
                color: colors.income,
                onPressed: () => receivePayment(context, payment),
              ),
              TextButton(
                onPressed: () => changePaymentDate(context, payment),
                child: Text(t.freelance.paymentChangeDateAction),
              ),
              TextButton(
                onPressed: () => deletePayment(context, payment),
                child: Text(t.freelance.paymentDeleteAction, style: TextStyle(color: colors.expense)),
              ),
            ],
    );
  }
}

/// Satu tab rincian proyek: kop, penyaring, lalu baris-barisnya yang dimuat
/// bertahap, atau [empty] kalau tidak ada baris.
class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.header,
    required this.filters,
    required this.rows,
    required this.empty,
    required this.buildRow,
  });

  final Widget header;
  final Widget filters;
  final List<_Row> rows;
  final Widget empty;
  final Widget Function(BuildContext, _Row) buildRow;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
      itemCount: 2 + (rows.isEmpty ? 1 : rows.length),
      itemBuilder: (context, index) => switch (index) {
        0 => header,
        1 => filters,
        _ when rows.isEmpty => empty,
        _ => buildRow(context, rows[index - 2]),
      },
    );
  }
}

class _FilteredEmpty extends StatelessWidget {
  const _FilteredEmpty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appColors.textMuted),
      ),
    );
  }
}

sealed class _Row {
  const _Row();
}

final class _MonthRow extends _Row {
  const _MonthRow(this.month, this.hours, this.amount);

  final DateTime month;
  final int hours;
  final int amount;
}

final class _EntryRow extends _Row {
  const _EntryRow(this.entry);

  final WorklogEntry entry;
}

final class _PaymentRow extends _Row {
  const _PaymentRow(this.payment);

  final FreelancePayment payment;
}

/// Kop rincian proyek: ikon, tarif, potongan, tiga angka status, dan bilah
/// porsinya.
class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project, required this.stats});

  final FreelanceProject project;
  final ProjectStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return TransactionSlab(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const FreelanceIconBox(IconKey.freelance, size: 56),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppIcon(IconKey.hourlyRate, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${AppMoneyFormatter.format(project.hourlyRate)}/${t.freelance.hourShort}',
                          style: PixelTypography.tabularMono(context, fontSize: 16, color: colors.textPrimary),
                        ),
                      ],
                    ),
                    Text(
                      project.deductionRules.isEmpty
                          ? t.freelance.noDeductions
                          : project.deductionRules.map(describeDeduction).join(' · '),
                      style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                    Text(
                      t.freelance.projectTotals(
                        hours: stats.totalHours,
                        amount: AppMoneyFormatter.format(stats.earned),
                      ),
                      style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    icon: IconKey.worklog,
                    label: t.freelance.statusUnbilled,
                    amount: stats.unbilledAmount,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _StatTile(
                    icon: IconKey.pending,
                    label: t.freelance.statusPending,
                    amount: stats.pendingAmount,
                    color: colors.pending,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _StatTile(
                    icon: IconKey.paid,
                    label: t.freelance.statusPaid,
                    amount: stats.paidAmount,
                    color: colors.income,
                  ),
                ),
              ],
            ),
          ),
          if (stats.earned > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            FreelanceShareBar(
              parts: [
                (stats.paidAmount, colors.income),
                (stats.pendingAmount, colors.pending),
                (stats.unbilledAmount, colors.textMuted.withValues(alpha: 0.35)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.amount, required this.color});

  final IconKey icon;
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(color: colors.tinted(color, 0.12), borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label.toUpperCase(), style: transactionLabelStyle(context, size: 9, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FitStart(
            child: Text(
              AppMoneyFormatter.format(amount),
              style: PixelTypography.tabularMono(context, fontSize: 13, color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip penyaring beserta jumlahnya.
class _FilterRow<T> extends StatelessWidget {
  const _FilterRow({required this.options, required this.selected, required this.onChanged});

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (value, label) in options) ...[
              AppChip(label: label, selected: value == selected, color: colors.accent, onTap: () => onChanged(value)),
              const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}
