import 'package:dependencies/dependencies.dart';

/// Skala jumlah instrumen (ADR-049 §3.2): jumlah disimpan sebagai `int`
/// dikali 10.000, jadi 1 lot = 10000, 0,5 gram = 5000. Obligasi tidak memakai
/// skala ini: jumlahnya nominal dalam sen.
const quantityScale = 10000;

/// Banyak lembar dalam satu lot saham (KT-A2).
const sharesPerLot = 100;

/// Penyebut harga obligasi: harga disimpan dalam basis poin ×100, jadi
/// 100,50% = 1005000 (ADR-049 §3.4).
const bondPriceScale = 1000000;

/// Jenis instrumen (ADR-049 §3.1). Satuan jumlah dan harga diturunkan dari
/// jenis, tidak disimpan.
enum InstrumentType {
  /// Saham: jumlah dalam lot, harga per lembar.
  stock,

  /// Reksa dana: jumlah dalam unit, harga per unit (NAB/UP).
  mutualFund,

  /// Obligasi: jumlah = nominal (sen), harga dalam persen dari nominal.
  bond,

  /// Emas: jumlah dalam gram, harga per gram.
  gold,

  /// Lainnya: jumlah dalam unit, harga per unit.
  other;

  /// `true` bila jumlahnya nominal uang (obligasi), bukan jumlah berskala.
  bool get usesNominal => this == InstrumentType.bond;
}

/// Kepemilikan yang sudah ada sebelum dicatat di aplikasi (ADR-049 §3.7
/// pintu 1). Tidak menyentuh dompet mana pun.
final class OpeningHolding extends Equatable {
  /// Membuat [OpeningHolding]. Jam pada [date] dibuang.
  OpeningHolding({required DateTime date, required this.quantity, required this.cost})
    : assert(quantity > 0, 'jumlah kepemilikan awal harus positif'),
      assert(cost >= 0, 'nilai perolehan tidak boleh negatif'),
      date = DateTime(date.year, date.month, date.day);

  /// Tanggal kepemilikan dianggap mulai.
  final DateTime date;

  /// Jumlah (§3.2).
  final int quantity;

  /// Nilai perolehan dalam sen, termasuk biaya.
  final int cost;

  @override
  List<Object?> get props => [date, quantity, cost];
}

/// Satu kepemilikan investasi (WEALTH_ASSETS §5.1, ADR-049 §3.1). Posisi
/// (jumlah, nilai perolehan, untung/rugi) tidak disimpan di sini, tetapi
/// diturunkan dari [opening] dan transaksi investasinya (§3.5).
final class Instrument extends Equatable {
  /// Membuat [Instrument].
  const Instrument({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    this.code,
    this.opening,
  });

  /// Identitas instrumen.
  final String id;

  /// Nama pilihan pemilik. Data pengguna, tidak lewat i18n.
  final String name;

  /// Jenis.
  final InstrumentType type;

  /// Kode bursa opsional, mis. `BBCA` (dipakai B-101).
  final String? code;

  /// Kepemilikan yang sudah ada, atau `null`.
  final OpeningHolding? opening;

  /// Kapan instrumen dibuat.
  final DateTime createdAt;

  /// Salinan dengan field yang disebutkan diganti. [clearCode] dan
  /// [clearOpening] mengosongkan field opsionalnya.
  Instrument copyWith({
    String? name,
    InstrumentType? type,
    String? code,
    bool clearCode = false,
    OpeningHolding? opening,
    bool clearOpening = false,
  }) => Instrument(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    createdAt: createdAt,
    code: clearCode ? null : (code ?? this.code),
    opening: clearOpening ? null : (opening ?? this.opening),
  );

  @override
  List<Object?> get props => [id, name, type, code, opening, createdAt];
}

/// Asal valuasi (ADR-049 §3.4).
enum ValuationSource {
  /// Diisi pengguna.
  manual,

  /// Diambil dari Google Sheet pengguna (B-101, ADR-051).
  sheet,

  /// Perkiraan dari Google Sheet (emas: ETF GLD × kurs, ADR-051 §3.1).
  sheetEstimate,
}

/// Harga satu instrumen pada satu tanggal (ADR-049 §3.4). [unitPrice] dalam
/// sen per lembar/unit/gram, atau basis poin ×100 untuk obligasi.
final class InstrumentValuation extends Equatable {
  /// Membuat [InstrumentValuation]. Jam pada [date] dibuang.
  InstrumentValuation({
    required this.instrumentId,
    required DateTime date,
    required this.unitPrice,
    this.source = ValuationSource.manual,
  }) : assert(unitPrice >= 0, 'harga tidak boleh negatif'),
       date = DateTime(date.year, date.month, date.day);

  /// Instrumen yang dinilai.
  final String instrumentId;

  /// Tanggal valuasi. Satu valuasi per instrumen per tanggal.
  final DateTime date;

  /// Harga per satuan harga.
  final int unitPrice;

  /// Asal valuasi.
  final ValuationSource source;

  @override
  List<Object?> get props => [instrumentId, date, unitPrice, source];
}
