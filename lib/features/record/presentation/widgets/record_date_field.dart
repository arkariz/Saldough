import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';

/// Baris Tanggal di Catat (prototipe `Catat.dc.html`): label kecil di atas
/// "Hari ini, 12.25" / "Kemarin, 08.00" / "Sabtu, 26 Sep, 08.00", diketuk
/// membuka [showDatePicker].
///
/// Jam dari [date] dipertahankan saat tanggal diganti -- [showDatePicker]
/// hanya mengembalikan tanggal (tengah malam), dan transaksi yang dicatat
/// pukul 14:20 tidak boleh berubah jadi 00:00 hanya karena harinya digeser.
class RecordDateField extends StatelessWidget {
  /// Membuat [RecordDateField].
  const RecordDateField({
    required this.date,
    required this.onChanged,
    required this.kind,
    this.allowFuture = false,
    super.key,
  });

  /// Tanggal peristiwa yang sedang dipilih.
  final DateTime date;

  /// Dipanggil dengan tanggal baru.
  final ValueChanged<DateTime> onChanged;

  /// Jenis transaksi.
  final TransactionKind kind;

  /// Mode jadwal (T-15.3): tanggal sampai setahun ke depan boleh dipilih,
  /// karena rutin boleh dimulai nanti ("Simpan Jadwal"). Tanpa jadwal,
  /// transaksi tidak boleh bertanggal masa depan.
  final bool allowFuture;

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _withTimeOf(DateTime day) => DateTime(day.year, day.month, day.day, date.hour, date.minute);

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: allowFuture
          ? DateTime(DateTime.now().year + 1, DateTime.now().month, DateTime.now().day)
          : DateTime.now(),
    );
    if (picked != null) onChanged(_withTimeOf(picked));
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  /// "Hari ini", "Kemarin", atau tanggal singkat; lalu jam bertitik.
  String _label() {
    final today = _dayOnly(DateTime.now());
    final day = _dayOnly(date);
    final dayText = day == today
        ? t.transaction.todayLabel
        : day == today.subtract(const Duration(days: 1))
            ? t.transaction.yesterdayLabel
            : CycleMonthFormatter.formatDateShort(date);
    return '$dayText, ${_two(date.hour)}.${_two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppListRow(
      key: const ValueKey('record-date'),
      compact: true,
      leading: AppIcon(IconKey.calendar, color: colors.ink2),
      label: t.record.dateFieldLabel,
      title: _label(),
      chevron: true,
      onTap: () => _pick(context),
    );
  }
}
