import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
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
    return DsFieldRow(
      key: const ValueKey('record-repeat'),
      icon: Icons.autorenew,
      leading: SvgPicture.asset(ClayIcons.repeat, width: 24, height: 24),
      label: t.record.repeat.label,
      title: value == null ? t.record.repeat.off : repeatSummary(value, date),
      titleMaxLines: 2,
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
    final ds = context.ds;
    final value = _value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(ClayIcons.repeat, width: 28, height: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Semantics(
                header: true,
                child: Text(t.record.repeat.label, textAlign: TextAlign.center, style: ds.typography.headlineSm),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DsFieldGroup(
                  children: [
                    if (!widget.locked)
                      _OptionRow(
                        key: const ValueKey('repeat-option-off'),
                        title: t.record.repeat.off,
                        selected: value == null,
                        onTap: () => _set(null),
                      ),
                    for (final frequency in RecurringFrequency.values)
                      _OptionRow(
                        key: ValueKey('repeat-option-${frequency.name}'),
                        title: _frequencyLabel(frequency),
                        subtitle: value?.frequency == frequency ? repeatSummary(value!, widget.date) : null,
                        selected: value?.frequency == frequency,
                        onTap: () => _set((value ?? const RecurringPattern()).copyWith(frequency: frequency)),
                      ),
                  ],
                ),
                if (value != null) ...[
                  const SizedBox(height: 8),
                  if (!_advanced)
                    // Selebar baris: area sentuhnya sama dengan yang dibaca
                    // aksesibilitas, bukan hanya teksnya (QA Fase 22, Q1).
                    DsButton.ghost(
                      key: const ValueKey('repeat-more'),
                      label: t.record.repeat.moreAction,
                      expand: true,
                      onPressed: () => setState(() => _advanced = true),
                    )
                  else
                    _Advanced(value: value, kind: widget.kind, date: widget.date, onChanged: _set),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: DsButton(
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

/// Satu pilihan frekuensi: penanda bulat, judul, dan kalimat jadwal bila
/// terpilih.
class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.title, required this.selected, required this.onTap, this.subtitle, super.key});

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: DsPressable(
        onPressed: onTap,
        pressedScale: 0.995,
        dimWhenDisabled: false,
        builder: (context, _) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 22,
                  color: selected ? c.actionPrimary : c.outlineStrong,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: ds.typography.bodyMd.copyWith(
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(subtitle!, style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _intervalLabel(RecurringPattern value) => switch (value.frequency) {
  RecurringFrequency.weekly => t.record.repeat.everyNWeeks(n: value.interval),
  RecurringFrequency.monthly => t.record.repeat.everyNMonths(n: value.interval),
  RecurringFrequency.yearly => t.record.repeat.everyNYears(n: value.interval),
};

enum _EndKind { never, after, on }

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
    final endKind = switch (value.end) {
      RecurringNeverEnds() => _EndKind.never,
      RecurringEndsAfter() => _EndKind.after,
      RecurringEndsOn() => _EndKind.on,
    };
    void toggleAuto() {
      // Otomasi R3 hanya untuk Plus (ADR-041 §3.8): bukan Plus, sakelar
      // membuka paywall dan nilainya tidak berubah.
      if (!ActivePlan.isPlus) {
        unawaited(
          context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.recurringAutomation)),
        );
        return;
      }
      final on = !value.autoRecord;
      AppAnalytics.log(RecurringEvents.autoRecordToggled(on: on, where: 'form'));
      onChanged(value.copyWith(autoRecord: on));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Section(),
        _Stepper(
          label: _intervalLabel(value),
          onMinus: value.interval > 1 ? () => onChanged(value.copyWith(interval: value.interval - 1)) : null,
          onPlus: value.interval < 52 ? () => onChanged(value.copyWith(interval: value.interval + 1)) : null,
        ),
        _Section(label: t.record.repeat.endLabel),
        DsSegmentedPill<_EndKind>(
          segments: [
            DsSegment(value: _EndKind.never, label: t.record.repeat.endNever),
            DsSegment(value: _EndKind.after, label: t.record.repeat.endAfter),
            DsSegment(
              value: _EndKind.on,
              label: switch (value.end) {
                RecurringEndsOn(date: final until) => CycleMonthFormatter.formatDateShort(until),
                _ => t.record.repeat.endOn,
              },
            ),
          ],
          selected: endKind,
          onChanged: (next) => switch (next) {
            _EndKind.never => onChanged(value.copyWith(end: const RecurringNeverEnds())),
            _EndKind.after => onChanged(value.copyWith(end: const RecurringEndsAfter(_RepeatSheetState._defaultCount))),
            _EndKind.on => unawaited(_pickEnd(context)),
          },
        ),
        if (count != null) ...[
          const SizedBox(height: 8),
          _Stepper(
            label: t.record.repeat.endsAfterSummary(n: count),
            onMinus: count > 1 ? () => onChanged(value.copyWith(end: RecurringEndsAfter(count - 1))) : null,
            onPlus: count < 360 ? () => onChanged(value.copyWith(end: RecurringEndsAfter(count + 1))) : null,
          ),
        ],
        _Section(label: t.record.repeat.amountLabel),
        DsSegmentedPill<RecurringAmountMode>(
          segments: [
            DsSegment(value: RecurringAmountMode.fixed, label: t.record.repeat.amountFixed),
            DsSegment(value: RecurringAmountMode.estimated, label: t.record.repeat.amountEstimated),
          ],
          selected: value.amountMode,
          onChanged: (mode) => onChanged(
            value.copyWith(amountMode: mode, autoRecord: mode == RecurringAmountMode.fixed && value.autoRecord),
          ),
        ),
        // Catat otomatis hanya untuk nominal tetap (ADR-037 §3.2).
        if (value.amountMode == RecurringAmountMode.fixed) ...[
          const SizedBox(height: 8),
          DsFieldGroup(
            children: [
              DsFieldRow(
                key: const ValueKey('repeat-auto-record'),
                icon: Icons.bolt,
                leading: SvgPicture.asset(ClayIcons.alarm, width: 24, height: 24),
                label: t.record.repeat.autoRecordLabel,
                title: t.record.repeat.autoRecordHint,
                onTap: toggleAuto,
                trailing: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PlusBadge(),
                      IgnorePointer(
                        child: Switch(value: value.autoRecord, onChanged: (_) {}),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        if (kind != TransactionKind.income) ...[
          _Section(label: t.record.repeat.paymentLabel),
          DsSegmentedPill<RecurringPaymentMode>(
            segments: [
              DsSegment(value: RecurringPaymentMode.manual, label: t.record.repeat.paymentManual),
              DsSegment(value: RecurringPaymentMode.autoDebit, label: t.record.repeat.paymentAutoDebit),
            ],
            selected: value.paymentMode ?? RecurringPaymentMode.manual,
            onChanged: (mode) => onChanged(value.copyWith(paymentMode: mode)),
          ),
        ],
      ],
    );
  }
}

/// Judul bagian lanjutan (kapital kecil) dengan jarak atas; tanpa [label]
/// hanya jarak.
class _Section extends StatelessWidget {
  const _Section({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: label == null
          ? const SizedBox.shrink()
          : Text(
              label!,
              style: ds.typography.pixelCaption.copyWith(color: ds.colors.textMuted, fontSize: 10),
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
    final ds = context.ds;
    final c = ds.colors;
    Widget button(IconData icon, String semantics, VoidCallback? onTap) => Semantics(
      label: semantics,
      button: true,
      enabled: onTap != null,
      excludeSemantics: true,
      child: DsPressable(
        onPressed: onTap,
        pressedScale: 0.9,
        builder: (context, _) => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.surfaceSunken,
            shape: BoxShape.circle,
            border: Border.all(color: c.outlineSubtle),
          ),
          child: Icon(icon, size: 20, color: c.actionPrimary),
        ),
      ),
    );
    return DsCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          button(Icons.remove, t.record.repeat.lessAction, onMinus),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          button(Icons.add, t.record.repeat.moreCountAction, onPlus),
        ],
      ),
    );
  }
}

/// Judul formulir CATAT: Ubah rutin ([scheduleOnly]) dan Jadikan Rutin
/// ([repeatLocked] tanpa [scheduleOnly]) tidak mencatat transaksi baru, jadi
/// tidak berjudul "Catat".
String recordFormTitle({required bool repeatLocked, required bool scheduleOnly}) {
  if (scheduleOnly) return t.record.repeat.editScheduleTitle;
  if (repeatLocked) return t.record.repeat.makeRecurringTitle;
  return t.appShell.recordAction;
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
