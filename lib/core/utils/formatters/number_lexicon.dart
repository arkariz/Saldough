/// Kosakata bilangan satu bahasa untuk `SpokenAmountParser` (ADR-029 §3.1).
///
/// Pengurai tidak mengenal kata bahasa apa pun; ia hanya membaca **peran**
/// kata dari sini. Menambah bahasa berarti menambah satu [NumberLexicon],
/// bukan menyunting pengurai.
final class NumberLexicon {
  /// Membuat [NumberLexicon].
  const NumberLexicon({
    this.digits = const {},
    this.values = const {},
    this.tens = const {},
    this.teens = const {},
    this.hundreds = const {},
    this.scales = const {},
    this.oneScales = const {},
    this.slang = const {},
    this.half = const {},
    this.decimalPoint = const {},
    this.connectors = const {},
    this.digitSuffixes = const {'k': 1000},
    this.groupSeparator,
  });

  /// Angka satuan 0–9 ("dua", "two"): menunggu ditempatkan oleh kata
  /// sesudahnya ("dua puluh", "dua ribu").
  final Map<String, int> digits;

  /// Kata bernilai tetap yang dijumlahkan ("sebelas", "twenty", "seratus").
  final Map<String, int> values;

  /// Pengali sepuluh untuk angka sebelumnya ("puluh" pada "dua puluh").
  final Set<String> tens;

  /// Penambah sepuluh untuk angka sebelumnya ("belas" pada "dua belas").
  final Set<String> teens;

  /// Pengali seratus untuk angka sebelumnya, atau seratus bila berdiri
  /// sendiri ("ratus", "hundred").
  final Set<String> hundreds;

  /// Satuan skala ("ribu", "thousand", "jt"). Sebuah skala menandai angka
  /// sebagai uang.
  final Map<String, int> scales;

  /// Skala yang sudah bernilai satu kali skalanya ("seribu", "sejuta").
  final Map<String, int> oneScales;

  /// Slang nominal ("goceng").
  final Map<String, int> slang;

  /// Setengah ("setengah juta", "half a million").
  final Set<String> half;

  /// Kata koma desimal ("satu koma lima juta", "one point five million").
  final Set<String> decimalPoint;

  /// Kata sambung yang hanya bermakna di antara dua kata bilangan ("two
  /// hundred **and** fifty", "half **a** million").
  final Set<String> connectors;

  /// Akhiran skala yang menempel di digit ("35rb", "25k", "2jt").
  final Map<String, int> digitSuffixes;

  /// Pemisah ribuan bahasa ini (ADR-028 §7): "35.000" pasti ribuan bila
  /// `.`, ragu bila bukan. `null` = setiap pemisah tunggal dengan tiga digit
  /// sesudahnya ragu.
  final String? groupSeparator;

  /// Hanya digit, simbol, dan kode mata uang — untuk bahasa tanpa paket
  /// aturan (ADR-029 §3.4).
  static const neutral = NumberLexicon();

  /// Bahasa Indonesia.
  static const indonesian = NumberLexicon(
    digits: {
      'nol': 0,
      'satu': 1,
      'dua': 2,
      'tiga': 3,
      'empat': 4,
      'lima': 5,
      'enam': 6,
      'tujuh': 7,
      'delapan': 8,
      'sembilan': 9,
    },
    values: {'sepuluh': 10, 'sebelas': 11, 'seratus': 100},
    tens: {'puluh'},
    teens: {'belas'},
    hundreds: {'ratus'},
    scales: {
      'ribu': 1000,
      'rb': 1000,
      'rebu': 1000,
      'k': 1000,
      'juta': 1000000,
      'jt': 1000000,
      'jta': 1000000,
      'miliar': 1000000000,
      'milyar': 1000000000,
    },
    oneScales: {'seribu': 1000, 'sejuta': 1000000, 'semiliar': 1000000000, 'semilyar': 1000000000},
    slang: {'cepek': 100, 'gopek': 500, 'seceng': 1000, 'goceng': 5000, 'ceban': 10000, 'gocap': 50000},
    half: {'setengah'},
    decimalPoint: {'koma'},
    digitSuffixes: {'k': 1000, 'rb': 1000, 'ribu': 1000, 'jt': 1000000, 'juta': 1000000},
    groupSeparator: '.',
  );

  /// Bahasa Inggris.
  static const english = NumberLexicon(
    digits: {
      'zero': 0,
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
    },
    values: {
      'ten': 10,
      'eleven': 11,
      'twelve': 12,
      'thirteen': 13,
      'fourteen': 14,
      'fifteen': 15,
      'sixteen': 16,
      'seventeen': 17,
      'eighteen': 18,
      'nineteen': 19,
      'twenty': 20,
      'thirty': 30,
      'forty': 40,
      'fifty': 50,
      'sixty': 60,
      'seventy': 70,
      'eighty': 80,
      'ninety': 90,
    },
    hundreds: {'hundred'},
    scales: {'thousand': 1000, 'k': 1000, 'grand': 1000, 'million': 1000000, 'billion': 1000000000},
    half: {'half'},
    decimalPoint: {'point'},
    connectors: {'and', 'a'},
    groupSeparator: ',',
  );
}
