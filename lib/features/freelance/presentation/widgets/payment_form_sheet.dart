import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
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
    final ds = context.ds;
    final c = ds.colors;
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFormHeader(title: t.freelance.paymentAddTitle),
            const SizedBox(height: 16),
            FreelanceNotice(title: t.freelance.ruleTitle, body: t.freelance.paymentCreateRuleBody),
            const SizedBox(height: 16),
            DsFieldGroup(
              children: [
                DsSelectRow<String>(
                  icon: Icons.work_outline_rounded,
                  label: t.freelance.projectLabel,
                  title: project?.name ?? t.freelance.projectPick,
                  placeholder: project == null,
                  options: [for (final p in widget.projects) DsMenuOption(value: p.id, label: p.name)],
                  onSelected: (id) => setState(() => id == null ? null : _selectProject(id)),
                ),
              ],
            ),
            if (project != null) ...[
              const SizedBox(height: 16),
              AppSectionLabel(t.freelance.paymentEntriesLabel(count: chosen.length, hours: hours)),
              const SizedBox(height: 8),
              DsListCard(
                children: [
                  for (final entry in _entries)
                    Material(
                      type: MaterialType.transparency,
                      child: CheckboxListTile(
                        value: _selected.contains(entry.id),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: c.actionPrimary,
                        onChanged: (checked) => setState(() {
                          _selected = checked ?? false ? {..._selected, entry.id} : ({..._selected}..remove(entry.id));
                        }),
                        title: Text(
                          CycleMonthFormatter.formatDateShort(entry.date),
                          style: ds.typography.titleMd.copyWith(fontSize: 14),
                        ),
                        subtitle: Text(
                          [formatHoursTimesRate(entry.hours, entry.hourlyRate), ?entry.note].join(' · '),
                          style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                        ),
                        secondary: Text(
                          AppMoneyFormatter.format(entry.earnedAmount),
                          style: ds.typography.amountSm.copyWith(color: c.textPrimary),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FreelanceDateButton(
                label: t.freelance.expectedDateLabel,
                date: _expectedDate,
                onChanged: (date) => setState(() => _expectedDate = date),
              ),
              if (breakdown != null) ...[
                const SizedBox(height: 16),
                NetPayBreakdownCard(breakdown: breakdown),
                if (breakdown.netPay <= 0) ...[
                  const SizedBox(height: 8),
                  Text(t.freelance.netPayNotPositive, style: ds.typography.bodySm.copyWith(color: c.error)),
                ],
              ],
            ],
            const SizedBox(height: 24),
            DsButton(
              label: t.freelance.paymentCreateAction,
              expand: true,
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
