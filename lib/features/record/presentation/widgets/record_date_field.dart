import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/record/presentation/widgets/fit_start.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_frame.dart';

/// Bagian waktu formulir CATAT: pintasan "Hari Ini" / "Kemarin" dan kotak
/// tanggal yang membuka [showDatePicker] (rujukan visual
/// `pixel_kas_catat_pengeluaran`, bagian "Waktu Transaksi").
///
/// Jam dari [date] dipertahankan saat tanggal diganti -- [showDatePicker]
/// hanya mengembalikan tanggal (tengah malam), dan transaksi yang dicatat
/// pukul 14:20 tidak boleh berubah jadi 00:00 hanya karena harinya digeser.
class RecordDateField extends StatelessWidget {
  /// Membuat [RecordDateField].
  const RecordDateField({required this.date, required this.onChanged, required this.kind, super.key});

  /// Tanggal peristiwa yang sedang dipilih.
  final DateTime date;

  /// Dipanggil dengan tanggal baru.
  final ValueChanged<DateTime> onChanged;

  /// Jenis transaksi: mewarnai pintasan yang sedang aktif.
  final TransactionKind kind;

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _withTimeOf(DateTime day) => DateTime(day.year, day.month, day.day, date.hour, date.minute);

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) onChanged(_withTimeOf(picked));
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    final today = _dayOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final current = _dayOnly(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecordSectionLabel(t.record.dateFieldLabel),
        const SizedBox(height: AppSpacing.xs),
        // `Wrap`: pintasan dan kotak tanggal tidak muat sebaris pada layar
        // sempit atau teks besar; kotak turun baris alih-alih meluap.
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _DayChip(
              label: t.transaction.todayLabel,
              kind: kind,
              selected: current == today,
              onTap: () => onChanged(_withTimeOf(today)),
            ),
            _DayChip(
              label: t.transaction.yesterdayLabel,
              kind: kind,
              selected: current == yesterday,
              onTap: () => onChanged(_withTimeOf(yesterday)),
            ),
            GestureDetector(
              onTap: () => _pick(context),
              behavior: HitTestBehavior.opaque,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(IconKey.calendar, size: 18),
                      const SizedBox(width: 6),
                      // Memperkecil, bukan meluap, kalau tanggal + jam lebih lebar
                      // dari layar (teks besar).
                      Flexible(
                        child: FitStart(
                          child: Text(
                            '${CycleMonthFormatter.formatDateShort(date)}, ${_two(date.hour)}:${_two(date.minute)}',
                            style: transactionLabelStyle(context, color: colors.textPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.kind, required this.selected, required this.onTap});

  final String label;
  final TransactionKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        // `Center(widthFactor: 1)`, bukan `Container(alignment: center)`: yang
        // terakhir mengisi seluruh lebar `Wrap` dan chip bertumpuk vertikal.
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
    );
  }
}
