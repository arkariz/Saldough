import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Baris **Ulangi** di CATAT (T-15.3, J2): tertutup "Ulangi: Tidak"; diketuk
/// → pilihan frekuensi, kalimat jadwal dari tanggal formulir, dan **Atur
/// lebih lanjut** (selang, berakhir, nominal kira-kira, cara bayar).
///
/// Bukan formulir rutin tersendiri (aturan 8): rutin selalu lahir dari isian
/// CATAT yang sama.
class RecordRepeatField extends StatefulWidget {
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

  /// Jenis transaksi: mewarnai pilihan aktif; cara bayar hanya untuk
  /// pengeluaran dan transfer.
  final TransactionKind kind;

  /// Dipanggil dengan pola baru, atau `null` saat "Tidak".
  final ValueChanged<RecurringPattern?> onChanged;

  /// Jadikan Rutin: pilihan "Tidak" tidak ditawarkan dan bagian ini terbuka.
  final bool locked;

  @override
  State<RecordRepeatField> createState() => _RecordRepeatFieldState();
}

class _RecordRepeatFieldState extends State<RecordRepeatField> {
  late bool _expanded = widget.locked || widget.value != null;
  bool _advanced = false;

  static const _defaultCount = 12;

  RecurringPattern? get _value => widget.value;

  void _set(RecurringPattern? value) => widget.onChanged(value);

  @override
  Widget build(BuildContext context) {
    final value = _value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionLabel(t.record.repeat.label),
        const SizedBox(height: AppSpacing.xs),
        if (!_expanded)
          _CollapsedRow(
            text: value == null ? t.record.repeat.off : _summary(value),
            onTap: () => setState(() => _expanded = true),
          )
        else ...[
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (!widget.locked)
                _OptionChip(
                  label: t.record.repeat.off,
                  kind: widget.kind,
                  selected: value == null,
                  onTap: () => _set(null),
                ),
              for (final frequency in RecurringFrequency.values)
                _OptionChip(
                  label: _frequencyLabel(frequency),
                  kind: widget.kind,
                  selected: value?.frequency == frequency,
                  onTap: () => _set((value ?? const RecurringPattern()).copyWith(frequency: frequency)),
                ),
            ],
          ),
          if (value != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(_summary(value), style: Theme.of(context).textTheme.bodySmall),
            if (!_advanced)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _advanced = true),
                  child: Text(t.record.repeat.moreAction),
                ),
              )
            else
              _Advanced(value: value, kind: widget.kind, date: widget.date, onChanged: _set),
          ],
        ],
      ],
    );
  }

  String _summary(RecurringPattern value) {
    final date = widget.date;
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

  static String _frequencyLabel(RecurringFrequency frequency) => switch (frequency) {
    RecurringFrequency.weekly => t.record.repeat.weekly,
    RecurringFrequency.monthly => t.record.repeat.monthly,
    RecurringFrequency.yearly => t.record.repeat.yearly,
  };
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
        const SizedBox(height: AppSpacing.sm),
        _Stepper(
          label: _intervalLabel(value),
          onMinus: value.interval > 1 ? () => onChanged(value.copyWith(interval: value.interval - 1)) : null,
          onPlus: value.interval < 52 ? () => onChanged(value.copyWith(interval: value.interval + 1)) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSectionLabel(t.record.repeat.endLabel),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _OptionChip(
              label: t.record.repeat.endNever,
              kind: kind,
              selected: value.end is RecurringNeverEnds,
              onTap: () => onChanged(value.copyWith(end: const RecurringNeverEnds())),
            ),
            _OptionChip(
              label: t.record.repeat.endAfter,
              kind: kind,
              selected: count != null,
              onTap: () =>
                  onChanged(value.copyWith(end: const RecurringEndsAfter(_RecordRepeatFieldState._defaultCount))),
            ),
            _OptionChip(
              label: switch (value.end) {
                RecurringEndsOn(date: final until) => CycleMonthFormatter.formatDateShort(until),
                _ => t.record.repeat.endOn,
              },
              kind: kind,
              selected: value.end is RecurringEndsOn,
              onTap: () => _pickEnd(context),
            ),
          ],
        ),
        if (count != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _Stepper(
            label: t.record.repeat.endsAfterSummary(n: count),
            onMinus: count > 1 ? () => onChanged(value.copyWith(end: RecurringEndsAfter(count - 1))) : null,
            onPlus: count < 360 ? () => onChanged(value.copyWith(end: RecurringEndsAfter(count + 1))) : null,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppSectionLabel(t.record.repeat.amountLabel),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (mode, label) in [
              (RecurringAmountMode.fixed, t.record.repeat.amountFixed),
              (RecurringAmountMode.estimated, t.record.repeat.amountEstimated),
            ])
              _OptionChip(
                label: label,
                kind: kind,
                selected: value.amountMode == mode,
                onTap: () => onChanged(
                  value.copyWith(amountMode: mode, autoRecord: mode == RecurringAmountMode.fixed && value.autoRecord),
                ),
              ),
          ],
        ),
        // Catat otomatis hanya untuk nominal tetap (ADR-037 §3.2).
        if (value.amountMode == RecurringAmountMode.fixed)
          SwitchListTile(
            key: const ValueKey('repeat-auto-record'),
            contentPadding: EdgeInsets.zero,
            title: Text(t.record.repeat.autoRecordLabel),
            subtitle: Text(t.record.repeat.autoRecordHint),
            value: value.autoRecord,
            onChanged: (on) {
              AppAnalytics.log(RecurringEvents.autoRecordToggled(on: on, where: 'form'));
              onChanged(value.copyWith(autoRecord: on));
            },
          ),
        if (kind != TransactionKind.income) ...[
          const SizedBox(height: AppSpacing.sm),
          AppSectionLabel(t.record.repeat.paymentLabel),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final (mode, label) in [
                (RecurringPaymentMode.manual, t.record.repeat.paymentManual),
                (RecurringPaymentMode.autoDebit, t.record.repeat.paymentAutoDebit),
              ])
                _OptionChip(
                  label: label,
                  kind: kind,
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

class _CollapsedRow extends StatelessWidget {
  const _CollapsedRow({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const AppIcon(IconKey.calendar, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(text, style: transactionLabelStyle(context, color: colors.textPrimary)),
              ),
              const AppIcon(IconKey.chevronRight, size: 18),
            ],
          ),
        ),
      ),
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
        child: AppQuickChip(label: text, onTap: onTap ?? () {}),
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

class _OptionChip extends StatelessWidget {
  const _OptionChip({required this.label, required this.kind, required this.selected, required this.onTap});

  final String label;
  final TransactionKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? colors.tinted(colors.kindFill(kind), 0.28) : colors.surfaceMid,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  label,
                  style: transactionLabelStyle(context, color: selected ? colors.kindInk(kind) : colors.textMuted),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
      ).textTheme.bodySmall?.copyWith(color: lines.length > 1 ? colors.pending : colors.textMuted),
    );
  }
}
