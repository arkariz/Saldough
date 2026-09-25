import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_kind.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';

/// Pemisah desimal sesuai bahasa aktif.
String get _decimalSeparator => LocaleSettings.currentLocale == AppLocale.en ? '.' : ',';

/// Menulis nilai per mil sebagai persen, mis. `25` → `2,5` (tanpa `%`).
String formatPerMilAsPercent(int perMil) {
  final whole = perMil ~/ 10;
  final tenth = perMil % 10;
  return tenth == 0 ? '$whole' : '$whole$_decimalSeparator$tenth';
}

/// Membaca persen berdesimal paling banyak satu angka (`2,5`, `2.5`, `10`)
/// jadi per mil (`25`, `25`, `100`). `null` kalau tidak sah, nol, atau
/// lebih dari 100%.
///
/// Satu angka desimal cukup karena satuan simpanannya per mil
/// (DOMAIN_MODEL.md bagian "Proyek").
int? parsePercentToPerMil(String text) {
  final match = RegExp(r'^(\d{1,3})(?:[.,](\d))?$').firstMatch(text.trim());
  if (match == null) return null;
  final perMil = int.parse(match.group(1)!) * 10 + int.parse(match.group(2) ?? '0');
  return perMil <= 0 || perMil > 1000 ? null : perMil;
}

/// Ringkasan satu potongan untuk ditampilkan, mis. `Pajak · 2,5%` atau
/// `Admin · Rp5.000`.
String describeDeduction(DeductionRule rule) => switch (rule.kind) {
  DeductionKind.percentage => '${rule.label} · ${formatPerMilAsPercent(rule.value)}%',
  DeductionKind.fixedAmount => '${rule.label} · ${AppMoneyFormatter.format(rule.value)}',
};

/// Rumus satu entri, mis. `4 jam × Rp150.000`.
String formatHoursTimesRate(int hours, int hourlyRate) =>
    t.freelance.hoursTimesRate(hours: hours, rate: AppMoneyFormatter.format(hourlyRate));
