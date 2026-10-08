import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/presentation/freelance_format.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_form_fields.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_notice.dart';

/// Hasil [EntryFormSheet]; `null` berarti dibatalkan.
sealed class EntryFormResult {
  /// Membuat [EntryFormResult].
  const EntryFormResult();
}

/// Entri disimpan.
final class EntryFormSaved extends EntryFormResult {
  /// Membuat [EntryFormSaved].
  const EntryFormSaved({
    required this.projectId,
    required this.date,
    required this.hours,
    required this.hourlyRate,
    required this.note,
  });

  /// Proyek yang dikerjakan.
  final String projectId;

  /// Tanggal kerja.
  final DateTime date;

  /// Jumlah jam.
  final int hours;

  /// Tarif per jam, sen.
  final int hourlyRate;

  /// Catatan, boleh kosong.
  final String note;
}

/// Entri dihapus.
final class EntryFormDeleted extends EntryFormResult {
  /// Membuat [EntryFormDeleted].
  const EntryFormDeleted();
}

/// Formulir entri worklog (FR-FRL-002, rujukan `pixel_kas_tambah_worklog`):
/// proyek, tanggal, jam, tarif, dan catatan, dengan rumus jam × tarif.
///
/// Tarif terisi dari proyek yang dipilih dan boleh diubah untuk entri ini
/// saja (ADR-019).
///
/// ⚠ Menyimpan entri **tidak** mengubah saldo dompet mana pun — dinyatakan di
/// kartu aturan di puncak formulir.
class EntryFormSheet extends StatefulWidget {
  /// Membuat [EntryFormSheet]. [initial] `null` = entri baru.
  const EntryFormSheet({required this.projects, this.initial, this.initialProjectId, super.key});

  /// Proyek yang bisa dipilih.
  final List<FreelanceProject> projects;

  /// Entri yang disunting.
  final WorklogEntry? initial;

  /// Proyek pra-terpilih untuk entri baru (dari rincian proyek).
  final String? initialProjectId;

  @override
  State<EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends State<EntryFormSheet> {
  final _hours = TextEditingController();
  final _rate = TextEditingController();
  final _note = TextEditingController();
  String? _projectId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final entry = widget.initial;
    if (entry == null) {
      if (widget.initialProjectId case final id?) {
        _selectProject(id);
      } else if (widget.projects.length == 1) {
        _selectProject(widget.projects.single.id);
      }
      return;
    }
    _projectId = entry.projectId;
    _date = entry.date;
    _hours.text = '${entry.hours}';
    _rate.text = AppFormMoneyField.initialText(entry.hourlyRate);
    _note.text = entry.note ?? '';
  }

  @override
  void dispose() {
    _hours.dispose();
    _rate.dispose();
    _note.dispose();
    super.dispose();
  }

  void _selectProject(String id) {
    _projectId = id;
    final project = widget.projects.where((p) => p.id == id).firstOrNull;
    if (project != null) _rate.text = AppFormMoneyField.initialText(project.hourlyRate);
  }

  int? get _hoursValue => AppFormQuantityField.valueOf(_hours);

  int? get _rateValue => AppFormMoneyField.senOf(_rate);

  bool get _canSave => _projectId != null && _hoursValue != null && _rateValue != null;

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      EntryFormSaved(
        projectId: _projectId!,
        date: _date,
        hours: _hoursValue!,
        hourlyRate: _rateValue!,
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final editing = widget.initial != null;
    final hours = _hoursValue;
    final rate = _rateValue;
    void refresh([String? _]) => setState(() {});
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, AppSpacing.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFormHeader(
                stepLabel: t.freelance.entryStepLabel,
                title: editing ? t.freelance.entryEditTitle : t.freelance.entryAddTitle,
              ),
              const SizedBox(height: AppSpacing.space4),
              FreelanceNotice(title: t.freelance.ruleTitle, body: t.freelance.entryRuleBody),
              const SizedBox(height: AppSpacing.space4),
              AppSectionLabel(t.freelance.projectLabel, hint: t.freelance.requiredHint),
              const SizedBox(height: AppSpacing.space1),
              AppMenuSelectButton<String>(
                icon: IconKey.freelance,
                label: widget.projects.where((p) => p.id == _projectId).firstOrNull?.name ?? t.freelance.projectPick,
                isPlaceholder: _projectId == null,
                wrapLabel: true,
                options: [
                  for (final project in widget.projects)
                    (value: project.id, label: project.name, icon: IconKey.freelance),
                ],
                onSelected: (id) => setState(() => id == null ? null : _selectProject(id)),
              ),
              const SizedBox(height: AppSpacing.space4),
              FreelanceDateButton(
                label: t.freelance.workDateLabel,
                date: _date,
                onChanged: (date) => setState(() => _date = date),
              ),
              const SizedBox(height: AppSpacing.space4),
              AppSectionLabel(t.freelance.hoursLabel, hint: t.freelance.requiredHint),
              const SizedBox(height: AppSpacing.space1),
              FreelanceHoursField(controller: _hours, onChanged: refresh),
              const SizedBox(height: AppSpacing.space4),
              AppSectionLabel(t.freelance.hourlyRateLabel, hint: t.freelance.requiredHint),
              const SizedBox(height: AppSpacing.space1),
              AppFormMoneyField(controller: _rate, onChanged: refresh),
              const SizedBox(height: 4),
              Text(t.freelance.entryRateHelp, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
              const SizedBox(height: AppSpacing.space4),
              TransactionSlab(
                color: colors.tinted(colors.positive, 0.12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.freelance.earnedLabel.toUpperCase(),
                      style: transactionLabelStyle(context, color: colors.ink2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hours == null || rate == null ? '—' : AppMoneyFormatter.format(hours * rate),
                      style: context.numberStyles.amountLg.copyWith(color: colors.ink),
                    ),
                    if (hours != null && rate != null)
                      Text(
                        formatHoursTimesRate(hours, rate),
                        style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              AppSectionLabel(t.freelance.noteLabel),
              const SizedBox(height: AppSpacing.space1),
              AppFormTextField(controller: _note, hint: t.freelance.noteHint, maxLength: 120, onChanged: refresh),
              const SizedBox(height: AppSpacing.space6),
              AppButton(label: t.freelance.entrySaveAction, onPressed: _canSave ? _save : null),
              const SizedBox(height: AppSpacing.space1),
              Text(
                t.freelance.entrySaveHint,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: colors.ink2),
              ),
              if (editing) ...[
                const SizedBox(height: AppSpacing.space4),
                AppButton.secondary(
                  label: t.freelance.entryDeleteAction,
                  textColor: colors.ink,
                  onPressed: () => Navigator.of(context).pop(const EntryFormDeleted()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
