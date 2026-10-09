import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Baris **Ulangi** di CATAT (T-15.3, J2; QA PR #43 F11): baris form seperti
/// Dompet dan Tanggal ("Ulangi · Tidak ›"). Diketuk → sheet pemilih berisi
/// frekuensi, kalimat jadwal dari tanggal formulir, dan **Atur lebih
/// lanjut** (selang, berakhir, nominal kira-kira, cara bayar). Baris tidak
/// pernah berubah bentuk; judulnya ringkasan pola ("Tiap tanggal 9").
///
/// Bukan formulir rutin tersendiri (aturan 8): rutin selalu lahir dari isian
/// CATAT yang sama.
class RecordRepeatField extends StatelessWidget {
  /// Membuat [RecordRepeatField].
  const RecordRepeatField({
    required this.value,
    required this.date,
    required this.kind,
    required this.onChanged,
    this.locked = false,
    super.key,
  });

  /// Pola terpilih; `null` = tidak diulang.
  final RecurringPattern? value;

  /// Tanggal formulir: patokan jadwal.
  final DateTime date;

  /// Jenis transaksi: cara bayar hanya untuk pengeluaran dan transfer.
  final TransactionKind kind;

  /// Dipanggil dengan pola baru, atau `null` saat "Tidak".
  final ValueChanged<RecurringPattern?> onChanged;

  /// Jadikan Rutin: pilihan "Tidak" tidak ditawarkan.
  final bool locked;

  Future<void> _open(BuildContext context) => showAppSheet<void>(
    context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _RepeatSheet(initial: value, date: date, kind: kind, locked: locked, onChanged: onChanged),
  );

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return AppListRow(
      key: const ValueKey('record-repeat'),
      compact: true,
      leading: AppIcon(IconKey.schedule, color: context.appColors.ink2),
      label: t.record.repeat.label,
      title: value == null ? t.record.repeat.off : repeatSummary(value, date),
      chevron: true,
      onTap: () => _open(context),
    );
  }
}

/// Kalimat jadwal [value] dari tanggal [date]: "Tiap tanggal 9 · 12 kali".
String repeatSummary(RecurringPattern value, DateTime date) {
  final when = switch (value.frequency) {
    RecurringFrequency.weekly => t.record.repeat.everyWeekday(day: CycleMonthFormatter.formatWeekday(date)),
    RecurringFrequency.monthly => t.record.repeat.everyMonthDay(day: date.day),
    RecurringFrequency.yearly => t.record.repeat.everyYearDate(date: CycleMonthFormatter.formatDayMonth(date)),
  };
  final interval = value.interval == 1 ? '' : ' · ${_intervalLabel(value)}';
  final end = switch (value.end) {
    RecurringNeverEnds() => '',
    RecurringEndsAfter(:final count) => ' · ${t.record.repeat.endsAfterSummary(n: count)}',
    RecurringEndsOn(date: final until) =>
      ' · ${t.record.repeat.endsOnSummary(date: CycleMonthFormatter.formatDateShort(until))}',
  };
  return '$when$interval$end';
}

String _frequencyLabel(RecurringFrequency frequency) => switch (frequency) {
  RecurringFrequency.weekly => t.record.repeat.weekly,
  RecurringFrequency.monthly => t.record.repeat.monthly,
  RecurringFrequency.yearly => t.record.repeat.yearly,
};

/// Sheet pemilih Ulangi (design system Sheet, varian pemilih): judul di
/// tengah, baris frekuensi dengan centang, kalimat jadwal, lalu opsi lanjut.
/// Tiap pilihan langsung diteruskan ke formulir lewat [onChanged].
class _RepeatSheet extends StatefulWidget {
  const _RepeatSheet({
    required this.initial,
    required this.date,
    required this.kind,
    required this.locked,
    required this.onChanged,
  });

  final RecurringPattern? initial;
  final DateTime date;
  final TransactionKind kind;
  final bool locked;
  final ValueChanged<RecurringPattern?> onChanged;

  @override
  State<_RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<_RepeatSheet> {
  late RecurringPattern? _value = widget.initial;
  bool _advanced = false;

  static const _defaultCount = 12;

  void _set(RecurringPattern? value) {
    setState(() => _value = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final value = _value;
    Widget check({required bool on}) =>
        on ? AppIcon(IconKey.check, color: colors.brand) : const SizedBox(width: AppSize.icon);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.record.repeat.label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.space2),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (!widget.locked)
                AppListRow(
                  key: const ValueKey('repeat-option-off'),
                  title: t.record.repeat.off,
                  trailing: check(on: value == null),
                  onTap: () => _set(null),
                ),
              for (final frequency in RecurringFrequency.values)
                AppListRow(
                  key: ValueKey('repeat-option-${frequency.name}'),
                  title: _frequencyLabel(frequency),
                  subtitle: value?.frequency == frequency ? repeatSummary(value!, widget.date) : null,
                  wrapSubtitle: true,
                  trailing: check(on: value?.frequency == frequency),
                  onTap: () => _set((value ?? const RecurringPattern()).copyWith(frequency: frequency)),
                ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                  child: !_advanced
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: AppButton.text(
                            small: true,
                            label: t.record.repeat.moreAction,
                            onPressed: () => setState(() => _advanced = true),
                          ),
                        )
                      : _Advanced(value: value, kind: widget.kind, date: widget.date, onChanged: _set),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: AppButton(
            key: const ValueKey('repeat-done'),
            label: t.common.done,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

String _intervalLabel(RecurringPattern value) => switch (value.frequency) {
  RecurringFrequency.weekly => t.record.repeat.everyNWeeks(n: value.interval),
  RecurringFrequency.monthly => t.record.repeat.everyNMonths(n: value.interval),
  RecurringFrequency.yearly => t.record.repeat.everyNYears(n: value.interval),
};

class _Advanced extends StatelessWidget {
  const _Advanced({required this.value, required this.kind, required this.date, required this.onChanged});

  final RecurringPattern value;
  final TransactionKind kind;
  final DateTime date;
  final ValueChanged<RecurringPattern> onChanged;

  Future<void> _pickEnd(BuildContext context) async {
    final current = switch (value.end) {
      RecurringEndsOn(date: final until) => until,
      _ => DateTime(date.year + 1, date.month, date.day),
    };
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(date) ? date : current,
      firstDate: date,
      lastDate: DateTime(date.year + 30),
    );
    if (picked != null) onChanged(value.copyWith(end: RecurringEndsOn(picked)));
  }

  @override
  Widget build(BuildContext context) {
    final count = switch (value.end) {
      RecurringEndsAfter(:final count) => count,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.space2),
        _Stepper(
          label: _intervalLabel(value),
          onMinus: value.interval > 1 ? () => onChanged(value.copyWith(interval: value.interval - 1)) : null,
          onPlus: value.interval < 52 ? () => onChanged(value.copyWith(interval: value.interval + 1)) : null,
        ),
        const SizedBox(height: AppSpacing.space2),
        AppSectionLabel(t.record.repeat.endLabel),
        const SizedBox(height: AppSpacing.space1),
        Wrap(
          spacing: AppSpacing.space1,
          runSpacing: AppSpacing.space1,
          children: [
            _OptionChip(
              label: t.record.repeat.endNever,
              selected: value.end is RecurringNeverEnds,
              onTap: () => onChanged(value.copyWith(end: const RecurringNeverEnds())),
            ),
            _OptionChip(
              label: t.record.repeat.endAfter,
              selected: count != null,
              onTap: () => onChanged(value.copyWith(end: const RecurringEndsAfter(_RepeatSheetState._defaultCount))),
            ),
            _OptionChip(
              label: switch (value.end) {
                RecurringEndsOn(date: final until) => CycleMonthFormatter.formatDateShort(until),
                _ => t.record.repeat.endOn,
              },
              selected: value.end is RecurringEndsOn,
              onTap: () => _pickEnd(context),
            ),
          ],
        ),
        if (count != null) ...[
          const SizedBox(height: AppSpacing.space1),
          _Stepper(
            label: t.record.repeat.endsAfterSummary(n: count),
            onMinus: count > 1 ? () => onChanged(value.copyWith(end: RecurringEndsAfter(count - 1))) : null,
            onPlus: count < 360 ? () => onChanged(value.copyWith(end: RecurringEndsAfter(count + 1))) : null,
          ),
        ],
        const SizedBox(height: AppSpacing.space2),
        AppSectionLabel(t.record.repeat.amountLabel),
        const SizedBox(height: AppSpacing.space1),
        Wrap(
          spacing: AppSpacing.space1,
          runSpacing: AppSpacing.space1,
          children: [
            for (final (mode, label) in [
              (RecurringAmountMode.fixed, t.record.repeat.amountFixed),
              (RecurringAmountMode.estimated, t.record.repeat.amountEstimated),
            ])
              _OptionChip(
                label: label,
                selected: value.amountMode == mode,
                onTap: () => onChanged(
                  value.copyWith(amountMode: mode, autoRecord: mode == RecurringAmountMode.fixed && value.autoRecord),
                ),
              ),
          ],
        ),
        // Catat otomatis hanya untuk nominal tetap (ADR-037 §3.2).
        if (value.amountMode == RecurringAmountMode.fixed)
          AppSwitchRow(
            key: const ValueKey('repeat-auto-record'),
            title: t.record.repeat.autoRecordLabel,
            subtitle: t.record.repeat.autoRecordHint,
            value: value.autoRecord,
            onChanged: (on) {
              AppAnalytics.log(RecurringEvents.autoRecordToggled(on: on, where: 'form'));
              onChanged(value.copyWith(autoRecord: on));
            },
          ),
        if (kind != TransactionKind.income) ...[
          const SizedBox(height: AppSpacing.space2),
          AppSectionLabel(t.record.repeat.paymentLabel),
          const SizedBox(height: AppSpacing.space1),
          Wrap(
            spacing: AppSpacing.space1,
            runSpacing: AppSpacing.space1,
            children: [
              for (final (mode, label) in [
                (RecurringPaymentMode.manual, t.record.repeat.paymentManual),
                (RecurringPaymentMode.autoDebit, t.record.repeat.paymentAutoDebit),
              ])
                _OptionChip(
                  label: label,
                  selected: value.paymentMode == mode,
                  onTap: () => onChanged(value.copyWith(paymentMode: mode)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.onMinus, required this.onPlus});

  final String label;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    Widget button(String text, String semantics, VoidCallback? onTap) => Semantics(
      label: semantics,
      enabled: onTap != null,
      excludeSemantics: true,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: AppChip(label: text, onTap: onTap ?? () {}),
      ),
    );
    return Row(
      children: [
        button('−', t.record.repeat.lessAction, onMinus),
        Expanded(
          child: Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ),
        button('+', t.record.repeat.moreCountAction, onPlus),
      ],
    );
  }
}

/// Pilihan frekuensi/akhir Ulangi sebagai chip (design system Chip).
class _OptionChip extends StatelessWidget {
  const _OptionChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppChip(label: label, selected: selected, onTap: onTap);
}

/// Label tombol simpan CATAT (J2): tanpa Ulangi → [plain]; dengan Ulangi,
/// tanggal hari ini atau lampau → "Catat & Jadwalkan", tanggal masa depan
/// → "Simpan Jadwal" (tidak ada transaksi yang dibuat).
String repeatSubmitLabel({
  required RecurringPattern? repeat,
  required DateTime date,
  required String plain,
  bool scheduleOnly = false,
}) {
  if (repeat == null) return plain;
  if (scheduleOnly) return t.record.repeat.saveScheduleAction;
  final now = DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  return day.isAfter(DateTime(now.year, now.month, now.day))
      ? t.record.repeat.saveScheduleAction
      : t.record.repeat.recordAndScheduleAction;
}

/// Tanggal formulir sesudah Ulangi dimatikan: transaksi tidak boleh
/// bertanggal masa depan, jadi tanggal masa depan kembali ke sekarang.
DateTime dateWithoutRepeat(DateTime date) {
  final now = DateTime.now();
  return date.isAfter(now) ? now : date;
}

/// Kemunculan rutin yang sedang dicatat lewat CATAT ("Ubah dulu").
typedef RecordOccurrence = ({RecurringRule rule, DateTime date});

/// Pemberitahuan ringan saat mencatat kemunculan rutin (T-15.6): E5 bila
/// nominal ≥5× atau ≤⅕ dari biasanya, E11 bila tanggalnya lebih dari 7 hari
/// dari jadwal. Tidak menahan simpan.
class RecordOccurrenceNotice extends StatelessWidget {
  /// Membuat [RecordOccurrenceNotice].
  const RecordOccurrenceNotice({required this.occurrence, required this.amount, required this.date, super.key});

  /// Kemunculannya.
  final RecordOccurrence occurrence;

  /// Nominal di formulir, atau `null`.
  final int? amount;

  /// Tanggal di formulir.
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rule = occurrence.rule;
    final lines = [
      t.recurring.occurrenceNotice(
        name: rule.note.isEmpty ? t.record.repeat.fallbackName : rule.note,
        date: CycleMonthFormatter.formatDayMonth(occurrence.date),
      ),
      if (amount case final typed? when isUnusualAmount(usual: rule.amount, typed: typed))
        t.recurring.unusualAmountNotice(usual: AppMoneyFormatter.format(rule.amount)),
      if (isFarFromOccurrence(date, occurrence.date))
        t.recurring.farDateNotice(date: CycleMonthFormatter.formatDayMonth(occurrence.date)),
    ];
    return Text(
      lines.join('\n'),
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: lines.length > 1 ? colors.warning : colors.ink2),
    );
  }
}
