/// Pengurai tanggal dari teks bebas (ADR-029 §3.2): "kemarin", "tanggal 27
/// september", "27/9", "September 27th", "3 days ago".
///
/// Seperti `SpokenAmountParser`, pengurai ini tidak mengenal kata bahasa
/// apa pun; semuanya dari [DateLexicon]. Tanggal tanpa tahun diartikan
/// **tanggal terdekat yang sudah lewat** (keputusan pemilik 30 Sep 2026),
/// karena formulir CATAT tidak menerima tanggal masa depan.
library;

import 'package:saldough/shared/capture/domain/number_lexicon.dart';

/// Urutan tanggal yang ditulis dengan angka ("27/9" atau "9/27").
enum NumericDateOrder {
  /// Hari lalu bulan.
  dayMonth,

  /// Bulan lalu hari.
  monthDay,
}

/// Kosakata tanggal satu bahasa.
final class DateLexicon {
  /// Membuat [DateLexicon].
  const DateLexicon({
    this.relativeDays = const {},
    this.daysAgo = const [],
    this.months = const {},
    this.markers = const [],
    this.ordinalSuffixes = const [],
    this.ofWords = const [],
    this.monthBeforeDay = false,
    this.numericOrder = NumericDateOrder.dayMonth,
  });

  /// Frasa relatif dan jumlah hari mundurnya ("kemarin": 1).
  final Map<String, int> relativeDays;

  /// Frasa sesudah bilangan yang berarti "N hari lalu".
  final List<String> daysAgo;

  /// Nama dan singkatan bulan ke nomor bulannya. Hanya dikenali di sebelah
  /// angka hari, jadi "may" dalam kalimat biasa tidak menjadi Mei.
  final Map<String, int> months;

  /// Penanda tanggal ("tanggal", "on the"). Boleh ada sebelum tanggal
  /// bernama bulan; **wajib** untuk tanggal tanpa bulan ("tanggal 5").
  final List<String> markers;

  /// Akhiran urutan ("27th"). Bila ada, tanggal tanpa bulan wajib
  /// memakainya.
  final List<String> ordinalSuffixes;

  /// Kata sambung hari–bulan ("27th **of** September").
  final List<String> ofWords;

  /// Bulan boleh disebut sebelum hari ("September 27").
  final bool monthBeforeDay;

  /// Urutan tanggal angka.
  final NumericDateOrder numericOrder;

  /// Bahasa Indonesia.
  static const indonesian = DateLexicon(
    relativeDays: {'hari ini': 0, 'kemarin': 1, 'kemaren': 1, 'kemarin lusa': 2, 'kemaren lusa': 2},
    daysAgo: ['hari lalu', 'hari yang lalu', 'hari yg lalu'],
    months: {
      'januari': 1,
      'jan': 1,
      'februari': 2,
      'feb': 2,
      'maret': 3,
      'mar': 3,
      'april': 4,
      'apr': 4,
      'mei': 5,
      'juni': 6,
      'jun': 6,
      'juli': 7,
      'jul': 7,
      'agustus': 8,
      'agu': 8,
      'agt': 8,
      'ags': 8,
      'september': 9,
      'sept': 9,
      'sep': 9,
      'oktober': 10,
      'okt': 10,
      'november': 11,
      'nov': 11,
      'desember': 12,
      'des': 12,
    },
    markers: ['pada tanggal', 'tanggal', 'tgl.', 'tgl'],
  );

  /// Bahasa Inggris (AS: tanggal angka bulan dulu).
  static const english = DateLexicon(
    relativeDays: {'today': 0, 'yesterday': 1, 'day before yesterday': 2, 'the day before yesterday': 2},
    daysAgo: ['days ago', 'day ago'],
    months: {
      'january': 1,
      'jan': 1,
      'february': 2,
      'feb': 2,
      'march': 3,
      'mar': 3,
      'april': 4,
      'apr': 4,
      'may': 5,
      'june': 6,
      'jun': 6,
      'july': 7,
      'jul': 7,
      'august': 8,
      'aug': 8,
      'september': 9,
      'sept': 9,
      'sep': 9,
      'october': 10,
      'oct': 10,
      'november': 11,
      'nov': 11,
      'december': 12,
      'dec': 12,
    },
    markers: ['on the', 'on', 'the'],
    ordinalSuffixes: ['st', 'nd', 'rd', 'th'],
    ofWords: ['of'],
    monthBeforeDay: true,
    numericOrder: NumericDateOrder.monthDay,
  );
}

/// Satu sebutan tanggal di teks.
final class SpokenDate {
  /// Membuat [SpokenDate].
  const SpokenDate({required this.text, required this.start, required this.end, this.date});

  /// Potongan teks asli, persis seperti di masukan.
  final String text;

  /// Posisi awal [text].
  final int start;

  /// Posisi akhir (eksklusif) [text].
  final int end;

  /// Tanggalnya (jam dari waktu acuan), atau `null` kalau disebut tetapi
  /// tidak sah: tidak ada di kalender (31 Feb), di masa depan dengan tahun
  /// yang disebut, atau sebelum tahun 2000.
  final DateTime? date;
}

/// Pengurai tanggal lisan. Lihat dokumentasi pustaka.
abstract final class SpokenDateParser {
  SpokenDateParser._();

  /// Seluruh sebutan tanggal di [text], urut kemunculan dan tidak saling
  /// tumpang tindih. [today] adalah waktu acuan (waktu bukti ditangkap);
  /// [numbers] membaca bilangan kata pada "dua hari lalu".
  static List<SpokenDate> findAll(
    String text, {
    required DateLexicon lexicon,
    required NumberLexicon numbers,
    required DateTime today,
  }) {
    final lower = text.toLowerCase();
    final found = <SpokenDate>[];

    void collect(RegExp? pattern, DateTime? Function(RegExpMatch m) read) {
      if (pattern == null) return;
      for (final m in pattern.allMatches(lower)) {
        if (found.any((d) => m.start < d.end && d.start < m.end)) continue;
        found.add(SpokenDate(text: text.substring(m.start, m.end), start: m.start, end: m.end, date: read(m)));
      }
    }

    final markers = _alt(lexicon.markers);
    final months = _alt(lexicon.months.keys);
    final ordinals = _alt(lexicon.ordinalSuffixes);
    final ofWords = _alt(lexicon.ofWords);
    final lead = markers == null ? '' : '(?:(?:$markers)\\s+)?';
    final ord = ordinals == null ? '' : '(?:$ordinals)?';
    final of = ofWords == null ? '' : '(?:(?:$ofWords)\\s+)?';
    const year = r'(?:,?\s+(\d{4}))?';

    int? monthOf(String? word) => word == null ? null : lexicon.months[word];

    // "27 september 2026", "the 27th of September"
    collect(
      months == null ? null : RegExp('$_b$lead(\\d{1,2})$ord\\s+$of($months)$year$_e'),
      (m) => _date(today, day: int.parse(m[1]!), month: monthOf(m[2]), year: _year(m[3])),
    );
    // "September 27th, 2026"
    collect(
      months == null || !lexicon.monthBeforeDay ? null : RegExp('$_b$lead($months)\\s+(\\d{1,2})$ord$year$_e'),
      (m) => _date(today, day: int.parse(m[2]!), month: monthOf(m[1]), year: _year(m[3])),
    );
    // "27/9", "27/9/2026", "27-9-2026". Tanda hubung wajib bertahun, supaya
    // "2-3 kopi" tidak menjadi tanggal.
    DateTime? numeric(RegExpMatch m) {
      final first = int.parse(m[1]!);
      final second = int.parse(m[2]!);
      final dayFirst = lexicon.numericOrder == NumericDateOrder.dayMonth;
      return _date(
        today,
        day: dayFirst ? first : second,
        month: dayFirst ? second : first,
        year: _year(m[3]),
      );
    }

    collect(RegExp('$_b$lead(\\d{1,2})/(\\d{1,2})(?:/(\\d{4}|\\d{2}))?$_e'), numeric);
    collect(RegExp('$_b$lead(\\d{1,2})-(\\d{1,2})-(\\d{4}|\\d{2})$_e'), numeric);
    // "tanggal 5", "on the 5th"
    collect(
      markers == null ? null : RegExp('$_b(?:$markers)\\s+(\\d{1,2})${ordinals == null ? '' : '(?:$ordinals)'}$_e'),
      (m) => _date(today, day: int.parse(m[1]!)),
    );
    // "3 hari lalu", "two days ago"
    final agoWords = _alt(lexicon.daysAgo);
    final numberWords = _alt([...numbers.digits.keys, ...numbers.values.keys]);
    collect(
      agoWords == null ? null : RegExp('$_b(\\d{1,4}${numberWords == null ? '' : '|$numberWords'})\\s+(?:$agoWords)$_e'),
      (m) {
        final word = m[1]!;
        final days = int.tryParse(word) ?? numbers.digits[word] ?? numbers.values[word];
        return days == null ? null : _daysBack(today, days);
      },
    );
    // "kemarin lusa", "yesterday"
    final relative = _alt(lexicon.relativeDays.keys);
    collect(
      relative == null ? null : RegExp('$_b(?:$relative)$_e'),
      (m) => _daysBack(today, lexicon.relativeDays[m[0]]!),
    );

    return found..sort((a, b) => a.start.compareTo(b.start));
  }
}

const _b = '(?<![a-z0-9])';
const _e = '(?![a-z0-9])';

/// Alternasi regex, frasa terpanjang lebih dulu ("kemarin lusa" sebelum
/// "kemarin"), atau `null` kalau kosong.
String? _alt(Iterable<String> words) {
  if (words.isEmpty) return null;
  final sorted = words.toList()..sort((a, b) => b.length.compareTo(a.length));
  return sorted.map(RegExp.escape).join('|');
}

int? _year(String? raw) {
  if (raw == null) return null;
  final value = int.parse(raw);
  return raw.length == 2 ? 2000 + value : value;
}

bool _exists(int year, int month, int day) =>
    month >= 1 && month <= 12 && day >= 1 && day <= DateTime(year, month + 1, 0).day;

DateTime _at(DateTime today, int year, int month, int day) =>
    DateTime(year, month, day, today.hour, today.minute, today.second);

DateTime? _checked(DateTime today, DateTime date) {
  final todayDate = DateTime(today.year, today.month, today.day);
  if (DateTime(date.year, date.month, date.day).isAfter(todayDate) || date.year < 2000) return null;
  return date;
}

DateTime? _daysBack(DateTime today, int days) =>
    _checked(today, _at(today, today.year, today.month, today.day - days));

/// Tanggal dari [day] (+ [month] + [year]). Tanpa tahun: tanggal terdekat
/// yang sudah lewat; tanpa bulan: bulan terdekat yang tanggalnya sudah
/// lewat dan ada di kalender ("tanggal 31" → bulan terakhir yang punya 31).
DateTime? _date(DateTime today, {required int day, int? month, int? year}) {
  if (month != null && year != null) {
    return _exists(year, month, day) ? _checked(today, _at(today, year, month, day)) : null;
  }
  if (month != null) {
    for (var y = today.year; y >= today.year - 8; y--) {
      if (!_exists(y, month, day)) continue;
      final date = _checked(today, _at(today, y, month, day));
      if (date != null) return date;
    }
    return null;
  }
  for (var back = 0; back <= 12; back++) {
    final first = DateTime(today.year, today.month - back);
    if (!_exists(first.year, first.month, day)) continue;
    final date = _checked(today, _at(today, first.year, first.month, day));
    if (date != null) return date;
  }
  return null;
}
