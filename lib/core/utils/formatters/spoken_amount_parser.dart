/// Pengurai nominal dari teks bebas: transkrip suara, teks notifikasi, teks
/// struk (ADR-027 §3.3).
///
/// Berbeda dari `parseMoneyInput` (kolom ketik bernominal satu angka),
/// pengurai ini mengenali satuan lisan ("ribu", "jt", "25k"), bilangan kata
/// ("dua puluh lima ribu"), slang ("goceng"), dan awalan "Rp". Kata-kata itu
/// datang dari [NumberLexicon] bahasanya (ADR-029 §3.1); pengurai sendiri
/// hanya mengenal digit dan penanda mata uang. Hasilnya selalu `int` sen —
/// seperseratus satuan utama (ADR-025 §3.1) — dihitung dengan aritmetika
/// bilangan bulat; tidak ada `double` di jalur ini.
///
/// Pengurai tidak menebak: dua nominal dalam satu teks, angka tanpa satuan
/// di bawah batas mata uangnya ("parkir 5"), dan "5,000" dalam bahasa
/// Indonesia (ribuan atau desimal?) dilaporkan sebagai [SpokenAmountIssue],
/// bukan dipilih salah satu.
library;

import 'package:saldough/core/currency/app_currency.dart';
import 'package:saldough/core/utils/formatters/number_lexicon.dart';

export 'package:saldough/core/utils/formatters/number_lexicon.dart';

/// Masalah yang membuat nominal tidak bisa diisi dengan yakin.
enum SpokenAmountIssue {
  /// Tidak ada nominal sama sekali.
  missing,

  /// Lebih dari satu nominal bersatuan ("kopi 25 ribu roti 15 ribu").
  multiple,

  /// Angka tanpa satuan uang di bawah batas angka polos mata uangnya
  /// ("parkir 5"; ADR-029 §3.3).
  withoutUnit,

  /// Penulisan yang bisa dibaca dua cara ("5,000"), atau pecahan lebih
  /// kecil dari sen.
  ambiguous,

  /// Menyebut mata uang lain ("10 dolar").
  foreignCurrency,
}

/// Satu frasa nominal yang ditemukan di teks.
final class SpokenAmount {
  /// Membuat [SpokenAmount].
  const SpokenAmount({
    required this.text,
    required this.sen,
    required this.hasUnit,
    this.isAmbiguous = false,
    this.start = 0,
    this.end = 0,
  });

  /// Potongan teks asli frasa ini, persis seperti di masukan.
  final String text;

  /// Posisi awal [text] di masukan.
  final int start;

  /// Posisi akhir (eksklusif) [text] di masukan.
  final int end;

  /// Nilainya dalam sen, atau `null` kalau [isAmbiguous].
  final int? sen;

  /// Punya penanda uang: satuan ("ribu", "k"), awalan "Rp", atau pengelompokan
  /// ribuan ("35.000"). Angka polos kecil ("dua" pada "dua kopi") tidak.
  final bool hasUnit;

  /// Penulisannya tidak bisa dibaca dengan yakin.
  final bool isAmbiguous;
}

/// Hasil [SpokenAmountParser.parse].
final class SpokenAmountResult {
  /// Membuat [SpokenAmountResult].
  const SpokenAmountResult({this.amount, this.issue});

  /// Nominal terpilih, atau `null`.
  final SpokenAmount? amount;

  /// Alasan [amount] kosong (atau diragukan), atau `null` kalau yakin.
  final SpokenAmountIssue? issue;

  /// Nominal dalam sen kalau tanpa masalah.
  int? get sen => issue == null ? amount?.sen : null;
}

/// Pengurai nominal lisan. Lihat dokumentasi pustaka.
abstract final class SpokenAmountParser {
  SpokenAmountParser._();

  /// Memilih satu nominal dari [text] dengan kosakata [lexicon] (lihat
  /// [select]).
  ///
  /// [currencyCode] adalah mata uang aplikasi (ADR-025): menyebut mata uang
  /// lain ("10 dolar" saat aplikasi memakai IDR, atau "Rp" saat memakai USD)
  /// dilaporkan [SpokenAmountIssue.foreignCurrency].
  static SpokenAmountResult parse(String text, {required NumberLexicon lexicon, String currencyCode = 'IDR'}) {
    final tokens = _tokenize(text);
    final own = _currencyWords[currencyCode] ?? const <String>{};
    final foreign = _moneyWords.difference(own);
    if (tokens.any((t) => foreign.contains(t.word))) {
      return const SpokenAmountResult(issue: SpokenAmountIssue.foreignCurrency);
    }
    return select(findAll(text, lexicon: lexicon), currencyCode: currencyCode);
  }

  /// Memilih satu nominal dari [found]: satu-satunya frasa bersatuan; kalau
  /// tidak ada, satu-satunya angka polos yang mencapai
  /// [AppCurrency.plainAmountMinUnits] (ADR-029 §3.3).
  static SpokenAmountResult select(List<SpokenAmount> found, {String currencyCode = 'IDR'}) {
    SpokenAmountResult single(SpokenAmount amount) =>
        SpokenAmountResult(amount: amount, issue: amount.isAmbiguous ? SpokenAmountIssue.ambiguous : null);

    final withUnit = found.where((a) => a.hasUnit).toList();
    if (withUnit.length > 1) return const SpokenAmountResult(issue: SpokenAmountIssue.multiple);
    if (withUnit.length == 1) return single(withUnit.single);
    final minUnits = AppCurrency.fromCode(currencyCode)?.plainAmountMinUnits;
    if (minUnits != null) {
      final plain = [
        for (final amount in found)
          if (!amount.isAmbiguous && (amount.sen ?? 0) >= minUnits * 100) amount,
      ];
      if (plain.length > 1) return const SpokenAmountResult(issue: SpokenAmountIssue.multiple);
      if (plain.length == 1) return single(plain.single);
    }
    if (found.isNotEmpty) return SpokenAmountResult(amount: found.first, issue: SpokenAmountIssue.withoutUnit);
    return const SpokenAmountResult(issue: SpokenAmountIssue.missing);
  }

  /// Seluruh frasa bilangan di [text], urut kemunculan.
  static List<SpokenAmount> findAll(String text, {required NumberLexicon lexicon}) {
    final tokens = _tokenize(text);
    final result = <SpokenAmount>[];
    var i = 0;
    while (i < tokens.length) {
      if (!_isNumberish(tokens[i], lexicon)) {
        i++;
        continue;
      }
      final start = i;
      while (i < tokens.length) {
        if (_isNumberish(tokens[i], lexicon)) {
          i++;
          continue;
        }
        // Kata sambung hanya ikut bila diapit kata bilangan ("two hundred and
        // fifty", "half a million").
        var j = i;
        while (j < tokens.length && lexicon.connectors.contains(tokens[j].word)) {
          j++;
        }
        if (j == i || j == tokens.length || !_isNumberish(tokens[j], lexicon)) break;
        i = j;
      }
      result.addAll(_evaluateRun(text, tokens.sublist(start, i), lexicon));
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// Token

final class _Token {
  const _Token({required this.word, required this.start, required this.end});

  /// Huruf kecil, tanpa tanda baca di tepi.
  final String word;
  final int start;
  final int end;
}

List<_Token> _tokenize(String text) {
  final tokens = <_Token>[];
  for (final match in RegExp(r'[^\s]+').allMatches(text)) {
    var start = match.start;
    var end = match.end;
    // Tanda baca di tepi ("35 ribu," / "(BCA)") tidak ikut token, tetapi
    // pemisah di dalam angka ("35.000,00") tetap.
    while (start < end && !_isWordChar(text.codeUnitAt(start))) {
      start++;
    }
    while (end > start && !_isWordChar(text.codeUnitAt(end - 1))) {
      end--;
    }
    if (start == end) continue;
    final raw = text.substring(start, end).toLowerCase();
    // "rp35.000" -> "rp" + "35.000"
    final rp = RegExp(r'^(rp\.?)(\d.*)$').firstMatch(raw);
    if (rp != null) {
      final prefixLength = rp.group(1)!.length;
      tokens
        ..add(_Token(word: 'rp', start: start, end: start + prefixLength))
        ..add(_Token(word: rp.group(2)!, start: start + prefixLength, end: end));
      continue;
    }
    // "$10" -> "$" + "10"
    if (raw.startsWith(r'$') && raw.length > 1) {
      tokens
        ..add(_Token(word: r'$', start: start, end: start + 1))
        ..add(_Token(word: raw.substring(1), start: start + 1, end: end));
      continue;
    }
    tokens.add(_Token(word: raw, start: start, end: end));
  }
  return tokens;
}

bool _isWordChar(int c) =>
    (c >= 0x30 && c <= 0x39) || (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || c == 0x24 || c > 0x7F;

// ---------------------------------------------------------------------------
// Kosakata

/// Kata penanda mata uang per kode ISO. Bukan kosakata satu bahasa: kode
/// dan nama mata uang dipakai lintas bahasa.
const _currencyWords = {
  'IDR': {'rp', 'rupiah', 'idr'},
  'USD': {'dolar', 'dollar', 'dollars', 'usd', 'bucks', r'$'},
  'EUR': {'euro', 'euros', 'eur'},
  'JPY': {'yen', 'jpy'},
  'MYR': {'ringgit', 'myr'},
  'SGD': {'sgd'},
};

/// Seluruh penanda mata uang: di depan atau di belakang angka, menandainya
/// sebagai uang.
final Set<String> _moneyWords = {for (final words in _currencyWords.values) ...words};

final _digitToken = RegExp(r'^\d[\d.,]*$');

/// Digit berakhiran skala ("35rb", "25k") menurut [lexicon].
({String digits, int scale})? _suffixed(String w, NumberLexicon lexicon) {
  final match = RegExp(r'^(\d[\d.,]*)([a-z]+)$').firstMatch(w);
  if (match == null) return null;
  final scale = lexicon.digitSuffixes[match.group(2)];
  return scale == null ? null : (digits: match.group(1)!, scale: scale);
}

/// Deret digit lebih panjang dari ini bukan nominal (nomor rekening,
/// referensi transaksi) dan tidak pernah diurai -- mencegah `int.parse`
/// meluap.
const _maxDigits = 15;

/// Nominal di atas ini (satuan utama) dianggap salah baca, bukan uang.
const _maxUnits = 1000000000000;

/// Paling banyak angka desimal yang diterima ("1,5" ya, "1,23456" ragu).
const _maxFractionDigits = 4;

int _digitCount(String w) => RegExp(r'\d').allMatches(w).length;

bool _isNumberish(_Token token, NumberLexicon lexicon) {
  final w = token.word;
  final isDigits = _digitToken.hasMatch(w) || _suffixed(w, lexicon) != null;
  if (isDigits) return _digitCount(w) <= _maxDigits;
  return lexicon.digits.containsKey(w) ||
      lexicon.values.containsKey(w) ||
      lexicon.scales.containsKey(w) ||
      lexicon.oneScales.containsKey(w) ||
      lexicon.slang.containsKey(w) ||
      _moneyWords.contains(w) ||
      lexicon.tens.contains(w) ||
      lexicon.teens.contains(w) ||
      lexicon.hundreds.contains(w) ||
      lexicon.half.contains(w) ||
      lexicon.decimalPoint.contains(w);
}

// ---------------------------------------------------------------------------
// Evaluasi

/// Bilangan rasional kecil, supaya "1,5 juta" dihitung tanpa `double`.
final class _Rational {
  const _Rational(this.num, [this.den = 1]);

  final int num;
  final int den;

  _Rational operator +(_Rational o) => _Rational(num * o.den + o.num * den, den * o.den);
  _Rational scale(int factor) => _Rational(num * factor, den);
  bool get isZero => num == 0;

  /// Lebih besar dari [units] satuan utama.
  bool exceeds(int units) => num > units * den;

  /// Nilai dalam sen (x100), atau `null` kalau lebih halus dari sen.
  int? get sen => (num * 100) % den == 0 ? (num * 100) ~/ den : null;
}

/// Hasil membaca satu token angka: nilainya dan apakah pemisahnya meyakinkan.
({_Rational value, bool grouped, bool ambiguous})? _readDigits(String raw, NumberLexicon lexicon) {
  var s = raw;
  if (s.endsWith('.') || s.endsWith(',')) s = s.substring(0, s.length - 1);
  if (!RegExp(r'^\d[\d.,]*$').hasMatch(s)) return null;
  final dots = '.'.allMatches(s).length;
  final commas = ','.allMatches(s).length;
  if (dots == 0 && commas == 0) return (value: _Rational(int.parse(s)), grouped: false, ambiguous: false);

  // Dua jenis pemisah: yang terakhir adalah desimal ("1.500.000,50" atau
  // "1,500,000.50").
  if (dots > 0 && commas > 0) {
    final decimalSep = s.lastIndexOf(',') > s.lastIndexOf('.') ? ',' : '.';
    final groupSep = decimalSep == ',' ? '.' : ',';
    final parts = s.split(decimalSep);
    if (parts.length != 2) return null;
    final whole = parts[0].replaceAll(groupSep, '');
    return (
      value: _decimal(whole, parts[1]),
      grouped: true,
      ambiguous: parts[1].length > 2 || parts[1].length > _maxFractionDigits,
    );
  }

  final sep = dots > 0 ? '.' : ',';
  final parts = s.split(sep);
  final groupsOfThree = parts.skip(1).every((p) => p.length == 3) && parts.first.length <= 3;
  if (parts.length > 2) {
    // "1.500.000": hanya sah sebagai pengelompokan ribuan.
    return groupsOfThree ? (value: _Rational(int.parse(parts.join())), grouped: true, ambiguous: false) : null;
  }
  if (parts[1].length == 3) {
    // Pemisah ribuan bahasanya ("35.000" dalam id, "5,000" dalam en) pasti
    // ribuan. Pemisah lain bisa desimal -- jangan menebak.
    return (value: _Rational(int.parse(parts.join())), grouped: true, ambiguous: sep != lexicon.groupSeparator);
  }
  // "1,5" / "1.5" / "35.000,00"-tanpa-titik: desimal.
  return (
    value: _decimal(parts[0], parts[1]),
    grouped: false,
    ambiguous: parts[1].length > _maxFractionDigits,
  );
}

_Rational _decimal(String whole, String fraction) {
  if (fraction.length > _maxFractionDigits) return const _Rational(0, 0);
  var den = 1;
  for (var i = 0; i < fraction.length; i++) {
    den *= 10;
  }
  return _Rational(int.parse(whole.isEmpty ? '0' : whole) * den + int.parse(fraction), den);
}

/// Mengevaluasi satu deret token bilangan yang bersebelahan. Bisa
/// menghasilkan lebih dari satu nominal kalau skalanya naik lagi ("500 ribu
/// 1 juta"), ada dua angka digit berturut-turut, atau ada sisa tak tersusun
/// sesudah skala ("25 ribu 2 gelas": "2" adalah jumlah barang, bukan Rp2).
List<SpokenAmount> _evaluateRun(String text, List<_Token> run, NumberLexicon lexicon) {
  final results = <SpokenAmount>[];

  var total = const _Rational(0);
  var group = const _Rational(0); // nilai di bawah skala berjalan
  var pending = const _Rational(0); // digit terakhir yang belum ditempatkan
  var hasValue = false;
  var hasUnit = false;
  var ambiguous = false;
  var lastScale = 0;
  var groupHasDigits = false;
  int? startIndex;
  int? endIndex;
  // Token skala terakhir, dan sisa sesudahnya: sah hanya kalau tersusun
  // ("dua ribu LIMA RATUS"), bukan satu angka lepas ("tiga puluh ribu DUA").
  int? scaleIndex;
  int? remainderStart;
  var remainderComposed = false;
  // "satu koma lima juta": bagian bulat dan digit desimal yang terkumpul.
  _Rational? commaWhole;
  var commaDigits = '';

  void add(_Rational value, int from, int to, {required bool unit}) {
    final bad = ambiguous || value.den == 0 || value.exceeds(_maxUnits);
    final sen = bad ? null : value.sen;
    results.add(
      SpokenAmount(
        text: text.substring(run[from].start, run[to].end),
        sen: sen,
        hasUnit: unit,
        isAmbiguous: bad || sen == null,
        start: run[from].start,
        end: run[to].end,
      ),
    );
  }

  void closeComma() {
    final whole = commaWhole;
    if (whole == null) return;
    commaWhole = null;
    if (commaDigits.isEmpty) {
      pending = whole;
      return;
    }
    pending = whole + _decimal('0', commaDigits);
    if (commaDigits.length > _maxFractionDigits) ambiguous = true;
    commaDigits = '';
  }

  void emit() {
    closeComma();
    final remainder = group + pending;
    if (hasValue && startIndex != null) {
      final start = startIndex!;
      final end = endIndex!;
      final splitAt = scaleIndex;
      final restFrom = remainderStart;
      if (lastScale != 0 && !remainder.isZero && !remainderComposed && splitAt != null && restFrom != null) {
        add(total, start, splitAt, unit: hasUnit);
        add(remainder, restFrom, end, unit: false);
      } else {
        add(total + remainder, start, end, unit: hasUnit);
      }
    }
    total = const _Rational(0);
    group = const _Rational(0);
    pending = const _Rational(0);
    hasValue = false;
    hasUnit = false;
    ambiguous = false;
    lastScale = 0;
    groupHasDigits = false;
    startIndex = null;
    endIndex = null;
    scaleIndex = null;
    remainderStart = null;
    remainderComposed = false;
  }

  void mark(int index) {
    startIndex ??= index;
    endIndex = index;
    if (scaleIndex != null && index > scaleIndex! && remainderStart == null) remainderStart = index;
  }

  void composed() {
    if (lastScale != 0) remainderComposed = true;
  }

  void applyScale(int scale, int index) {
    closeComma();
    if (lastScale != 0 && scale >= lastScale) {
      // Skala naik lagi: nominal baru.
      emit();
    }
    var unit = group + pending;
    if (unit.isZero) unit = const _Rational(1);
    if (unit.den == 0 || unit.exceeds(_maxUnits ~/ scale)) {
      ambiguous = true;
    } else {
      total = total + unit.scale(scale);
    }
    group = const _Rational(0);
    pending = const _Rational(0);
    groupHasDigits = false;
    lastScale = scale;
    hasValue = true;
    hasUnit = true;
    mark(index);
    scaleIndex = index;
    remainderStart = null;
    remainderComposed = false;
  }

  for (var i = 0; i < run.length; i++) {
    final w = run[i].word;
    if (lexicon.connectors.contains(w)) continue;
    if (commaWhole != null) {
      // Mengumpulkan digit desimal sesudah "koma".
      if (lexicon.digits.containsKey(w)) {
        commaDigits += '${lexicon.digits[w]}';
        mark(i);
        continue;
      }
      if (RegExp(r'^\d+$').hasMatch(w)) {
        commaDigits += w;
        mark(i);
        continue;
      }
      closeComma();
    }
    if (lexicon.decimalPoint.contains(w)) {
      if (!hasValue) continue;
      commaWhole = group + pending;
      group = const _Rational(0);
      pending = const _Rational(0);
      mark(i);
      continue;
    }
    if (_moneyWords.contains(w)) {
      // "Rp" di depan menandai uang; "rupiah" di belakang juga.
      if (w == 'rp' && hasValue) emit();
      hasUnit = true;
      mark(i);
      continue;
    }
    final suffixed = _suffixed(w, lexicon);
    if (suffixed != null) {
      final read = _readDigits(suffixed.digits, lexicon);
      if (read == null) continue;
      if (groupHasDigits) emit();
      pending = read.value;
      hasValue = true;
      ambiguous = ambiguous || read.ambiguous;
      mark(i);
      applyScale(suffixed.scale, i);
      continue;
    }
    final read = _digitToken.hasMatch(w) ? _readDigits(w, lexicon) : null;
    if (read != null) {
      // Dua angka digit berturut-turut tanpa skala di antaranya adalah dua
      // nominal ("25000 15000").
      if (groupHasDigits || !pending.isZero) emit();
      pending = read.value;
      groupHasDigits = true;
      hasValue = true;
      hasUnit = hasUnit || read.grouped;
      ambiguous = ambiguous || read.ambiguous;
      mark(i);
      continue;
    }
    if (lexicon.digits.containsKey(w)) {
      if (!pending.isZero) {
        group = group + pending;
      }
      pending = _Rational(lexicon.digits[w]!);
      hasValue = true;
      mark(i);
      continue;
    }
    if (lexicon.values.containsKey(w)) {
      group = group + pending + _Rational(lexicon.values[w]!);
      pending = const _Rational(0);
      hasValue = true;
      mark(i);
      composed();
      continue;
    }
    if (lexicon.teens.contains(w)) {
      group = group + const _Rational(10) + pending;
      pending = const _Rational(0);
      mark(i);
      composed();
      continue;
    }
    if (lexicon.tens.contains(w)) {
      group = group + pending.scale(10);
      pending = const _Rational(0);
      mark(i);
      composed();
      continue;
    }
    if (lexicon.hundreds.contains(w)) {
      group = group + (pending.isZero ? const _Rational(1) : pending).scale(100);
      pending = const _Rational(0);
      mark(i);
      composed();
      continue;
    }
    if (lexicon.half.contains(w)) {
      // "setengah juta" = 0,5 juta; "satu setengah juta" = 1,5 juta.
      pending = pending + const _Rational(1, 2);
      hasValue = true;
      mark(i);
      composed();
      continue;
    }
    if (lexicon.oneScales.containsKey(w)) {
      pending = const _Rational(1);
      hasValue = true;
      applyScale(lexicon.oneScales[w]!, i);
      continue;
    }
    if (lexicon.scales.containsKey(w)) {
      if (!hasValue) continue; // "ribu" tanpa angka di depannya.
      applyScale(lexicon.scales[w]!, i);
      continue;
    }
    if (lexicon.slang.containsKey(w)) {
      if (hasValue) emit();
      total = _Rational(lexicon.slang[w]!);
      hasValue = true;
      hasUnit = true;
      lastScale = 1;
      mark(i);
      scaleIndex = i;
      continue;
    }
  }
  emit();
  return results;
}
