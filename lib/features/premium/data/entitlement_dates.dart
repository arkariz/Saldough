/// Hari kalender sebagai `yyyy-MM-dd` (tanpa jam) untuk dokumen hak.
String encodeDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Kebalikan [encodeDay]; melempar [FormatException] bila tidak sah.
DateTime decodeDay(Object? raw) {
  if (raw is! String) throw const FormatException('Tanggal hak tidak valid');
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) throw const FormatException('Tanggal hak tidak valid');
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Waktu sebagai ISO-8601 UTC.
String encodeInstant(DateTime d) => d.toUtc().toIso8601String();

/// Kebalikan [encodeInstant], dalam waktu setempat; melempar
/// [FormatException] bila tidak sah.
DateTime decodeInstant(Object? raw) {
  if (raw is! String) throw const FormatException('Waktu hak tidak valid');
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) throw const FormatException('Waktu hak tidak valid');
  return parsed.toLocal();
}
