import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';

/// Baris tanggal dipakai ketiga formulir CATAT — menampilkan [date] dan
/// membuka [showDatePicker] saat diketuk.
class RecordDateField extends StatelessWidget {
  /// Membuat [RecordDateField].
  const RecordDateField({required this.date, required this.onChanged, super.key});

  /// Tanggal peristiwa yang sedang dipilih.
  final DateTime date;

  /// Dipanggil dengan tanggal baru setelah pemilih ditutup dengan pilihan.
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: t.record.dateFieldLabel),
        child: Text(MaterialLocalizations.of(context).formatMediumDate(date)),
      ),
    );
  }
}
