import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_fields.dart';

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
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () => _pick(context),
        behavior: HitTestBehavior.opaque,
        child: TransactionSlab(
          radius: 4,
          shadow: 2,
          child: Row(
            children: [
              const AppIcon(IconKey.calendar),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(), style: transactionLabelStyle(context, color: colors.textMuted)),
                    Text(CycleMonthFormatter.formatDate(date), style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              Text(t.freelance.changeAction.toUpperCase(), style: transactionLabelStyle(context, color: colors.accent)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kolom jam kerja: angka bulat yang bisa diketik, ditambah pilihan cepat
/// jam yang umum. Jam disimpan bulat (DOMAIN_MODEL.md bagian "Worklog").
class FreelanceHoursField extends StatelessWidget {
  /// Membuat [FreelanceHoursField].
  const FreelanceHoursField({required this.controller, required this.onChanged, super.key});

  /// Pengendali teks; dibaca pemanggil lewat `BudgetQuantityField.valueOf`.
  final TextEditingController controller;

  /// Dipanggil tiap nilai berubah.
  final VoidCallback onChanged;

  static const _quickHours = [1, 2, 4, 8];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BudgetQuantityField(controller: controller, onChanged: (_) => onChanged()),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final hours in _quickHours)
              AppQuickChip(
                label: t.freelance.hoursValue(hours: hours),
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
