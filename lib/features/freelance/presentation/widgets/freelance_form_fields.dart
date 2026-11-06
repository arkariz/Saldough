import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';

/// Tombol tanggal: label kecil, tanggal lengkap, dan ikon kalender. Membuka
/// `showDatePicker`.
class FreelanceDateButton extends StatelessWidget {
  /// Membuat [FreelanceDateButton].
  const FreelanceDateButton({required this.label, required this.date, required this.onChanged, super.key});

  /// Label di atas tanggal.
  final String label;

  /// Tanggal terpilih.
  final DateTime date;

  /// Dipanggil dengan tanggal baru.
  final ValueChanged<DateTime> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DsFieldGroup(
      children: [
        DsFieldRow(
          icon: Icons.calendar_today_outlined,
          label: label,
          title: CycleMonthFormatter.formatDate(date),
          trailing: Text(t.freelance.changeAction, style: ds.typography.pixelLabel.copyWith(color: c.actionPrimary)),
          onTap: () => _pick(context),
          semanticsLabel: label,
        ),
      ],
    );
  }
}

/// Kolom jam kerja: angka bulat yang bisa diketik, ditambah pilihan cepat
/// jam yang umum. Jam disimpan bulat (DOMAIN_MODEL.md bagian "Worklog").
class FreelanceHoursField extends StatelessWidget {
  /// Membuat [FreelanceHoursField].
  const FreelanceHoursField({required this.controller, required this.onChanged, super.key});

  /// Pengendali teks; dibaca pemanggil lewat `AppFormQuantityField.valueOf`.
  final TextEditingController controller;

  /// Dipanggil tiap nilai berubah.
  final VoidCallback onChanged;

  static const _quickHours = [1, 2, 4, 8];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormQuantityField(controller: controller, onChanged: (_) => onChanged()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final hours in _quickHours)
              DsFilterChip(
                label: t.freelance.hoursValue(hours: hours),
                selected: false,
                onTap: () {
                  controller.text = '$hours';
                  onChanged();
                },
              ),
          ],
        ),
      ],
    );
  }
}
