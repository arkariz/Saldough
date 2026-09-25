import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
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
Future<void> openFreelanceProject(BuildContext context, FreelanceProject project) {
  final bloc = context.read<FreelanceBloc>();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PixelTheme(
        child: BlocProvider.value(
          value: bloc,
          child: FreelanceProjectPage(projectId: project.id),
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

  bool _matches(EntryBillingStatus status) => switch (this) {
    EntryFilter.all => true,
    EntryFilter.unbilled => status == EntryBillingStatus.unbilled,
    EntryFilter.pending => status == EntryBillingStatus.pending,
    EntryFilter.paid => status == EntryBillingStatus.paid,
  };
}

/// Rincian satu proyek freelance: tarif dan potongan, angka proyek, lalu
/// entri worklognya sendiri — disaring per status dan dikelompokkan per
/// bulan dengan subtotal, dimuat bertahap supaya tetap ringan walau entrinya
/// ratusan. Bilah aksi di dasar layar: tambah worklog untuk proyek ini dan
/// tagih entri yang belum ditagih.
class FreelanceProjectPage extends StatefulWidget {
  /// Membuat [FreelanceProjectPage].
  const FreelanceProjectPage({required this.projectId, super.key});

  /// Proyek yang ditampilkan; dibaca ulang dari state tiap kali berubah.
  final String projectId;

  @override
  State<FreelanceProjectPage> createState() => _FreelanceProjectPageState();
}

class _FreelanceProjectPageState extends State<FreelanceProjectPage> {
  late EntryFilter _filter;

  @override
  void initState() {
    super.initState();
    // Bawaan "belum ditagih", kecuali proyek ini tidak punya entri seperti
    // itu — jangan membuka layar dengan daftar kosong padahal ada entri.
    final stats = context.read<FreelanceBloc>().state.statsOf(widget.projectId);
    _filter = stats.unbilledCount == 0 && stats.entryCount > 0 ? EntryFilter.all : EntryFilter.unbilled;
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
        final counts = {
          for (final filter in EntryFilter.values)
            filter: entries.where((e) => filter._matches(state.statusOf(e))).length,
        };
        final visible = entries.where((e) => _filter._matches(state.statusOf(e))).toList();
        final rows = _rowsFor(visible);
        return Scaffold(
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
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
                    itemCount: 2 + (rows.isEmpty ? 1 : rows.length),
                    itemBuilder: (context, index) => switch (index) {
                      0 => _ProjectHeader(project: project, stats: stats),
                      1 => _FilterRow(
                        selected: _filter,
                        counts: counts,
                        onChanged: (filter) => setState(() => _filter = filter),
                      ),
                      _ when rows.isEmpty =>
                        entries.isEmpty
                            ? FreelanceEmptyState(
                                badge: t.freelance.entriesEmptyBadge,
                                title: t.freelance.entriesEmptyTitle,
                                body: t.freelance.entriesEmptyBody,
                                icons: const [IconKey.worklog, IconKey.calendar, IconKey.workCompleted],
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                child: Text(
                                  t.freelance.entriesFilteredEmpty,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.appColors.textMuted,
                                  ),
                                ),
                              ),
                      _ => switch (rows[index - 2]) {
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
                      },
                    },
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
                      onPressed: stats.unbilledCount == 0 ? null : () => createPayment(context, projectId: project.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Entri yang terlihat, disisipi judul bulan dengan subtotalnya.
  static List<_Row> _rowsFor(List<WorklogEntry> entries) {
    final rows = <_Row>[];
    DateTime? month;
    var headerIndex = -1;
    for (final entry in entries) {
      final entryMonth = DateTime(entry.date.year, entry.date.month);
      if (entryMonth != month) {
        month = entryMonth;
        headerIndex = rows.length;
        rows.add(_MonthRow(entryMonth, 0, 0));
      }
      final header = rows[headerIndex] as _MonthRow;
      rows[headerIndex] = _MonthRow(entryMonth, header.hours + entry.hours, header.amount + entry.earnedAmount);
      rows.add(_EntryRow(entry));
    }
    return rows;
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

/// Chip penyaring status beserta jumlah entrinya.
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.counts, required this.onChanged});

  final EntryFilter selected;
  final Map<EntryFilter, int> counts;
  final ValueChanged<EntryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    String label(EntryFilter filter) => switch (filter) {
      EntryFilter.all => t.freelance.filterAll,
      EntryFilter.unbilled => t.freelance.statusUnbilled,
      EntryFilter.pending => t.freelance.statusPending,
      EntryFilter.paid => t.freelance.statusPaid,
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in EntryFilter.values) ...[
              AppChip(
                label: '${label(filter)} (${counts[filter]})',
                selected: filter == selected,
                color: colors.accent,
                onTap: () => onChanged(filter),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}
