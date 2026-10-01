import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';

/// Hasil pencocokan satu templat: kutipan dari teks notifikasi.
final class NotificationTemplateMatch {
  /// Membuat [NotificationTemplateMatch].
  const NotificationTemplateMatch({required this.amountText, this.note});

  /// Frasa nominal persis seperti di teks.
  final String amountText;

  /// Potongan catatan, atau `null` bila templat tanpa [NotificationPattern.noteToken].
  final String? note;
}

/// Peran satu kata contoh di pembuat pola (ADR-032 §3.3).
enum TemplateWordRole {
  /// Teks tetap.
  literal,

  /// Nominal transaksi.
  amount,

  /// Catatan (merchant atau lawan transaksi).
  note,

  /// Bagian yang berubah-ubah.
  ignore,
}

/// Satu kata teks contoh beserta posisinya.
final class TemplateWord {
  /// Membuat [TemplateWord].
  const TemplateWord({required this.text, required this.start, required this.end});

  /// Isi kata.
  final String text;

  /// Posisi awal di teks contoh.
  final int start;

  /// Posisi akhir (eksklusif).
  final int end;
}

/// Templat pola notifikasi: kompilasi ke regex, pencocokan, dan pembuatan
/// dari contoh (ADR-032 §3.3).
///
/// Pencocokan **utuh dan ketat** (tanpa beda huruf besar-kecil, spasi
/// apa pun dianggap sama): templat yang tidak pas tidak cocok, alih-alih
/// salah membaca. Nominal harus berawalan Rp/IDR atau berpemisah ribuan,
/// supaya potongan nomor rekening atau tanggal tidak pernah terbaca nominal.
abstract final class NotificationTemplate {
  NotificationTemplate._();

  /// Pola regex nominal di templat.
  static const amountPattern = r'(?:(?:rp|idr)\.?\s?\d(?:[\d.,]*\d)?|\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?)';

  static final _tokens = RegExp(r'\{amount\}|\{note\}|\{\*\}');
  static final _amountOnly = RegExp('^$amountPattern\$', caseSensitive: false);

  /// `true` bila [template] sah: tepat satu nominal, paling banyak satu
  /// catatan, dan ada teks tetap selain penanda.
  static bool isValid(String template) {
    final amounts = NotificationPattern.amountToken.allMatchesIn(template);
    final notes = NotificationPattern.noteToken.allMatchesIn(template);
    final literal = template.replaceAll(_tokens, '').trim();
    return amounts == 1 && notes <= 1 && literal.isNotEmpty;
  }

  /// Mencocokkan [template] dengan [text], atau `null`.
  static NotificationTemplateMatch? match(String template, String text) {
    if (!isValid(template)) return null;
    final buffer = StringBuffer(r'^\s*');
    var amountGroup = 0;
    var noteGroup = 0;
    var group = 0;
    var cursor = 0;
    for (final token in _tokens.allMatches(template)) {
      buffer.write(_literal(template.substring(cursor, token.start)));
      switch (token.group(0)) {
        case NotificationPattern.amountToken:
          amountGroup = ++group;
          buffer.write('($amountPattern)');
        case NotificationPattern.noteToken:
          noteGroup = ++group;
          buffer.write('(.+?)');
        default:
          buffer.write('.*?');
      }
      cursor = token.end;
    }
    buffer
      ..write(_literal(template.substring(cursor)))
      ..write(r'[\s.!]*$');
    final found = RegExp(buffer.toString(), caseSensitive: false, dotAll: true).firstMatch(text.trim());
    if (found == null) return null;
    final note = noteGroup == 0 ? null : found.group(noteGroup)!.trim();
    return NotificationTemplateMatch(
      amountText: found.group(amountGroup)!.trim(),
      note: note == null || note.isEmpty ? null : note,
    );
  }

  /// Kata-kata [text] untuk pembuat pola.
  static List<TemplateWord> words(String text) => [
    for (final m in RegExp(r'\S+').allMatches(text)) TemplateWord(text: m.group(0)!, start: m.start, end: m.end),
  ];

  /// `true` bila [word] bisa ditandai sebagai nominal.
  static bool isAmountWord(String word) => _amountIn(word) != null;

  /// Templat dari [text] dengan peran tiap kata [roles] (indeks [words]).
  /// Kata berangka yang tidak ditandai menjadi [NotificationPattern.anyToken]
  /// supaya nomor referensi, jam, dan saldo yang berubah tetap cocok.
  /// `null` bila tidak ada tepat satu kata nominal, atau catatannya tidak
  /// berurutan.
  static String? fromSample(String text, Map<int, TemplateWordRole> roles) {
    final list = words(text);
    final amountIndexes = [
      for (final e in roles.entries)
        if (e.value == TemplateWordRole.amount) e.key,
    ];
    if (amountIndexes.length != 1) return null;
    final noteIndexes = [
      for (final e in roles.entries)
        if (e.value == TemplateWordRole.note) e.key,
    ]..sort();
    if (noteIndexes.isNotEmpty && noteIndexes.last - noteIndexes.first + 1 != noteIndexes.length) return null;

    // Rentang yang diganti penanda: (awal, akhir, penanda).
    final replacements = <(int, int, String)>[];
    for (var i = 0; i < list.length; i++) {
      final word = list[i];
      final role = roles[i] ?? TemplateWordRole.literal;
      switch (role) {
        case TemplateWordRole.amount:
          final span = _amountIn(word.text);
          if (span == null) return null;
          replacements.add((word.start + span.$1, word.start + span.$2, NotificationPattern.amountToken));
        case TemplateWordRole.note:
          if (i != noteIndexes.first) continue;
          final last = list[noteIndexes.last];
          final noteText = text.substring(word.start, last.end);
          final trimmed = noteText.replaceAll(RegExp(r'[,.;:!?]+$'), '');
          replacements.add((word.start, word.start + trimmed.length, NotificationPattern.noteToken));
        case TemplateWordRole.ignore:
          replacements.add((word.start, word.end, NotificationPattern.anyToken));
        case TemplateWordRole.literal:
          if (RegExp(r'\d').hasMatch(word.text)) {
            replacements.add((word.start, word.end, NotificationPattern.anyToken));
          }
      }
    }
    final out = StringBuffer();
    var cursor = 0;
    for (final r in replacements) {
      out
        ..write(text.substring(cursor, r.$1))
        ..write(r.$3);
      cursor = r.$2;
    }
    out.write(text.substring(cursor));
    final collapsed = out
        .toString()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\{\*\}(?:\s*\{\*\})+'), NotificationPattern.anyToken);
    return isValid(collapsed) ? collapsed : null;
  }

  /// Rentang nominal di dalam [word] (tanda baca di sekitarnya dibuang).
  static (int, int)? _amountIn(String word) {
    final m = RegExp(amountPattern, caseSensitive: false).firstMatch(word);
    if (m == null) return null;
    final inner = word.substring(m.start, m.end);
    if (!_amountOnly.hasMatch(inner)) return null;
    // Sisa di depan hanya boleh tanda baca ("(Rp5.000").
    if (RegExp(r'[\p{L}\d]', unicode: true).hasMatch(word.substring(0, m.start))) return null;
    return (m.start, m.end);
  }

  static String _literal(String text) {
    if (text.isEmpty) return '';
    return text.trim().isEmpty
        ? r'\s*'
        : [
            if (RegExp(r'^\s').hasMatch(text)) r'\s*',
            text.trim().split(RegExp(r'\s+')).map(RegExp.escape).join(r'\s+'),
            if (RegExp(r'\s$').hasMatch(text)) r'\s*',
          ].join();
  }
}

extension on String {
  int allMatchesIn(String text) => RegExp(RegExp.escape(this)).allMatches(text).length;
}
