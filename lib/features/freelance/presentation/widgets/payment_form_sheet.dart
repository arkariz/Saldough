import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_fields.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/domain/usecases/calculate_net_pay.dart';
import 'package:saldough/features/freelance/presentation/freelance_format.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_form_fields.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_notice.dart';
import 'package:saldough/features/freelance/presentation/widgets/net_pay_breakdown_card.dart';

/// Hasil [PaymentFormSheet] saat disimpan; `null` berarti dibatalkan.
final class PaymentFormSaved {
  /// Membuat [PaymentFormSaved].
  const PaymentFormSaved({required this.projectId, required this.entryIds, required this.expectedDate});

  /// Proyek yang ditagihkan.
  final String projectId;

  /// Entri yang ditagihkan.
  final List<String> entryIds;

  /// Perkiraan tanggal diterima.
  final DateTime expectedDate;
}

/// Formulir mengelompokkan worklog jadi pembayaran (FR-FRL-003): proyek,
/// entri belum ditagihkan yang dicentang, tanggal perkiraan, lalu rincian
/// gaji kotor, potongan, dan gaji bersih.
///
/// Pembayaran tidak harus mengikuti batas bulan kalender — entri dipilih
/// satu per satu, bukan per bulan. Potongan yang dipakai adalah potongan
/// proyek saat ini, disalin ke pembayaran (ADR-019).
class PaymentFormSheet extends StatefulWidget {
  /// Membuat [PaymentFormSheet].
  const PaymentFormSheet({
    required this.projects,
    required this.unbilledEntries,
    this.initialProjectId,
    super.key,
  });

  /// Proyek pra-terpilih (tombol Tagih di rincian proyek).
  final String? initialProjectId;

  /// Proyek yang masih punya entri belum ditagihkan.
  final List<FreelanceProject> projects;

  /// Entri belum ditagihkan per `projectId`.
  final Map<String, List<WorklogEntry>> unbilledEntries;

  @override
  State<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends State<PaymentFormSheet> {
  static const _calculateNetPay = CalculateNetPay();

  String? _projectId;
  Set<String> _selected = const {};
  DateTime _expectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProjectId;
    if (initial != null && widget.projects.any((p) => p.id == initial)) {
      _selectProject(initial);
    } else if (widget.projects.length == 1) {
      _selectProject(widget.projects.single.id);
    }
  }

  void _selectProject(String id) {
    _projectId = id;
    _selected = {for (final entry in widget.unbilledEntries[id] ?? const <WorklogEntry>[]) entry.id};
  }

  FreelanceProject? get _project => widget.projects.where((p) => p.id == _projectId).firstOrNull;

  List<WorklogEntry> get _entries => widget.unbilledEntries[_projectId] ?? const [];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final project = _project;
    final chosen = _entries.where((e) => _selected.contains(e.id)).toList();
    final hours = chosen.fold(0, (sum, e) => sum + e.hours);
    final breakdown = project == null || chosen.isEmpty
        ? null
        : _calculateNetPay(
            grossPay: chosen.fold(0, (sum, e) => sum + e.earnedAmount),
            deductionRules: project.deductionRules,
          );
    final canSave = project != null && chosen.isNotEmpty && breakdown!.netPay > 0;
    return SizedBox.expand(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BudgetFormHeader(stepLabel: t.freelance.paymentStepLabel, title: t.freelance.paymentAddTitle),
            const SizedBox(height: AppSpacing.md),
            FreelanceNotice(title: t.freelance.ruleTitle, body: t.freelance.paymentCreateRuleBody),
            const SizedBox(height: AppSpacing.md),
            AppSectionLabel(t.freelance.projectLabel, hint: t.freelance.requiredHint),
            const SizedBox(height: AppSpacing.xs),
            AppMenuSelectButton<String>(
              icon: IconKey.freelance,
              label: project?.name ?? t.freelance.projectPick,
              isPlaceholder: project == null,
              wrapLabel: true,
              options: [
                for (final p in widget.projects) (value: p.id, label: p.name, icon: IconKey.freelance),
              ],
              onSelected: (id) => setState(() => id == null ? null : _selectProject(id)),
            ),
            if (project != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppSectionLabel(t.freelance.paymentEntriesLabel(count: chosen.length, hours: hours)),
              const SizedBox(height: AppSpacing.xs),
              for (final entry in _entries)
                CheckboxListTile(
                  value: _selected.contains(entry.id),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: colors.accent,
                  onChanged: (checked) => setState(() {
                    _selected = checked ?? false ? {..._selected, entry.id} : ({..._selected}..remove(entry.id));
                  }),
                  title: Text(CycleMonthFormatter.formatDateShort(entry.date), style: textTheme.titleSmall),
                  subtitle: Text(
                    [formatHoursTimesRate(entry.hours, entry.hourlyRate), ?entry.note].join(' · '),
                    style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                  secondary: Text(
                    AppMoneyFormatter.format(entry.earnedAmount),
                    style: PixelTypography.tabularMono(context, fontSize: 13, color: colors.textPrimary),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              FreelanceDateButton(
                label: t.freelance.expectedDateLabel,
                date: _expectedDate,
                onChanged: (date) => setState(() => _expectedDate = date),
              ),
              if (breakdown != null) ...[
                const SizedBox(height: AppSpacing.md),
                NetPayBreakdownCard(breakdown: breakdown),
                if (breakdown.netPay <= 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(t.freelance.netPayNotPositive, style: textTheme.bodySmall?.copyWith(color: colors.expense)),
                ],
              ],
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: t.freelance.paymentCreateAction,
              onPressed: canSave
                  ? () => Navigator.of(context).pop(
                      PaymentFormSaved(
                        projectId: project.id,
                        entryIds: [for (final entry in chosen) entry.id],
                        expectedDate: _expectedDate,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
