import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/investment/domain/instrument.dart';
import 'package:saldough/shared/investment/domain/investment_repository.dart';
import 'package:saldough/shared/investment/domain/investment_usecases.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Setelan harga dari Google Sheet (ADR-051 §3.1). Nilai dari Remote Config;
/// [defaults] bila tidak ada atau tidak sah.
final class PriceSheetConfig extends Equatable {
  /// Membuat [PriceSheetConfig].
  const PriceSheetConfig({required this.goldMicroOuncesPerGldShare});

  /// Membaca [values] (nama parameter → teks).
  factory PriceSheetConfig.fromValues(Map<String, String> values) {
    final parsed = int.tryParse(values[goldKey]?.trim() ?? '');
    // 0,05–0,2 ons per lembar: di luar itu pasti salah ketik.
    final valid = parsed != null && parsed >= 50000 && parsed <= 200000;
    return PriceSheetConfig(goldMicroOuncesPerGldShare: valid ? parsed : defaults.goldMicroOuncesPerGldShare);
  }

  /// Nama parameter Remote Config: kandungan emas per lembar GLD, mikro-ons.
  static const goldKey = 'gold_gld_micro_ounces';

  /// Bawaan: ≈0,0919 ons per lembar GLD (November 2026).
  static const defaults = PriceSheetConfig(goldMicroOuncesPerGldShare: 91900);

  /// Kandungan emas per lembar ETF GLD dalam mikro-ons (×1.000.000).
  final int goldMicroOuncesPerGldShare;

  @override
  List<Object?> get props => [goldMicroOuncesPerGldShare];
}

/// Sumber [PriceSheetConfig] (port; implementasinya membaca Remote Config).
abstract interface class PriceSheetConfigSource {
  /// Setelan yang berlaku sekarang.
  PriceSheetConfig get config;
}

/// [PriceSheetConfigSource] dengan nilai bawaan, untuk uji dan lingkup tanpa
/// Remote Config.
final class DefaultPriceSheetConfig implements PriceSheetConfigSource {
  /// Membuat [DefaultPriceSheetConfig].
  const DefaultPriceSheetConfig();

  @override
  PriceSheetConfig get config => PriceSheetConfig.defaults;
}

/// Rumus kolom Harga untuk [instrument] (ADR-051 §3.1), atau `null` bila
/// harganya diisi pengguna sendiri di Sheet.
///
/// Saham berkode: harga per lembar dari `IDX:<KODE>`. Emas: perkiraan rupiah
/// per gram dari ETF GLD × kurs USDIDR ÷ 31,1035 gram per ons.
String? priceFormula(Instrument instrument, PriceSheetConfig config) {
  final code = instrument.code?.trim().toUpperCase();
  return switch (instrument.type) {
    InstrumentType.stock when code != null && RegExp(r'^[A-Z0-9]{1,8}$').hasMatch(code) =>
      '=IFERROR(GOOGLEFINANCE("IDX:$code","price"),"")',
    InstrumentType.gold =>
      '=IFERROR(GOOGLEFINANCE("NYSEARCA:GLD","price")/${_ounces(config)}'
          '*GOOGLEFINANCE("CURRENCY:USDIDR")/31.1035,"")',
    InstrumentType.stock || InstrumentType.mutualFund || InstrumentType.bond || InstrumentType.other => null,
  };
}

/// Mikro-ons sebagai desimal titik untuk rumus, mis. 91900 → "0.0919".
String _ounces(PriceSheetConfig config) {
  final micro = config.goldMicroOuncesPerGldShare;
  final fraction = (micro % 1000000).toString().padLeft(6, '0').replaceFirst(RegExp(r'0+$'), '');
  return '${micro ~/ 1000000}.${fraction.isEmpty ? '0' : fraction}';
}

/// Sumber valuasi dari Sheet untuk [type]: emas selalu perkiraan.
ValuationSource sheetSourceFor(InstrumentType type) =>
    type == InstrumentType.gold ? ValuationSource.sheetEstimate : ValuationSource.sheet;

/// Harga dari sel Sheet ([value], angka rupiah, atau persen untuk obligasi)
/// menjadi `unitPrice` (ADR-049 §3.4), dibulatkan sekali. `null` bila bukan
/// angka positif.
int? unitPriceFromSheet(InstrumentType type, Object? value) {
  final number = switch (value) {
    final num n => n,
    final String s => num.tryParse(s.trim()),
    _ => null,
  };
  if (number == null || number <= 0 || number.isNaN || number.isInfinite) return null;
  return type.usesNominal ? (number * bondPriceScale / 100).round() : (number * 100).round();
}

/// Satu baris Sheet milik aplikasi (ADR-051 §3.3): tanpa jumlah atau nominal.
final class PriceSheetRow extends Equatable {
  /// Membuat [PriceSheetRow].
  const PriceSheetRow({required this.instrumentId, required this.name, required this.code, this.formula});

  /// Kunci pencocokan (kolom A).
  final String instrumentId;

  /// Nama instrumen (kolom B).
  final String name;

  /// Kode bursa, boleh kosong (kolom C).
  final String code;

  /// Rumus kolom Harga, atau `null` = biarkan isian pengguna (kolom D).
  final String? formula;

  @override
  List<Object?> get props => [instrumentId, name, code, formula];
}

/// Tautan ke Sheet pengguna (ADR-051 §3.3), disimpan lokal dan ikut cadangan.
final class PriceSheetLink extends Equatable {
  /// Membuat [PriceSheetLink].
  const PriceSheetLink({required this.sheetId, this.lastFetchedAt});

  /// ID spreadsheet Google.
  final String sheetId;

  /// Kapan harga terakhir diambil, untuk jeda 15 menit (§3.4).
  final DateTime? lastFetchedAt;

  /// Salinan dengan [lastFetchedAt] baru.
  PriceSheetLink fetchedAt(DateTime time) => PriceSheetLink(sheetId: sheetId, lastFetchedAt: time);

  @override
  List<Object?> get props => [sheetId, lastFetchedAt];
}

/// Penyimpanan [PriceSheetLink].
abstract interface class PriceSheetLinkStore {
  /// Tautan tersimpan, atau `null`.
  Future<Either<Failure, PriceSheetLink?>> read();

  /// Menyimpan [link].
  Future<Either<Failure, Unit>> save(PriceSheetLink link);

  /// Melupakan tautan (Sheet tak terjangkau, ganti akun).
  Future<Either<Failure, Unit>> clear();
}

/// Akses Sheets API atas nama pengguna (port; implementasi HTTP di `data/`).
abstract interface class PriceSheetGateway {
  /// Membuat Sheet baru berjudul [title], mengembalikan ID-nya.
  Future<Either<Failure, String>> create(String title);

  /// Menyelaraskan [rows] ke Sheet [sheetId]: baris ber-`id` sama diperbarui
  /// di tempat, yang baru ditambah di bawah; baris lain tidak disentuh.
  Future<Either<Failure, Unit>> syncRows(String sheetId, List<PriceSheetRow> rows);

  /// Isi kolom Harga per `id`, apa adanya (angka, teks, atau kosong).
  Future<Either<Failure, Map<String, Object?>>> readPrices(String sheetId);
}

/// Kode galat Sheet (ADR-051 §3.6).
abstract final class PriceSheetFailures {
  /// Izin `drive.file` belum diberikan atau dicabut.
  static const notAuthorized = FailureCode('PRICE_SHEET_NOT_AUTHORIZED');

  /// Sheet tak terjangkau (dihapus, akun lain).
  static const notFound = FailureCode('PRICE_SHEET_NOT_FOUND');

  /// Jaringan atau Google tak terjangkau.
  static const unreachable = FailureCode('PRICE_SHEET_UNREACHABLE');
}

/// Judul Sheet yang dibuat aplikasi.
const priceSheetTitle = 'Tanukonomy – Harga investasi';

/// Memastikan Sheet ada dan barisnya selaras dengan instrumen Aktif
/// (ADR-051 §3.3). Mengembalikan tautannya.
final class SyncPriceSheet {
  /// Membuat [SyncPriceSheet].
  const SyncPriceSheet({
    required this.gateway,
    required this.links,
    required this.investments,
    required this.transactions,
    this.configSource = const DefaultPriceSheetConfig(),
  });

  /// Sheets API.
  final PriceSheetGateway gateway;

  /// Tautan tersimpan.
  final PriceSheetLinkStore links;

  /// Instrumen.
  final InvestmentRepository investments;

  /// Buku besar (status Aktif).
  final TransactionRepository transactions;

  /// Setelan rumus emas.
  final PriceSheetConfigSource configSource;

  /// Menjalankan sinkronisasi; Sheet dibuat bila belum ada tautan.
  Future<Either<Failure, PriceSheetLink>> call() async {
    final summaries = await LoadInstrumentSummaries(investments: investments, transactions: transactions)();
    if (summaries case Left(value: final f)) return left(f);
    final stored = await links.read();
    if (stored case Left(value: final f)) return left(f);
    var link = stored.getOrElse((_) => null);
    if (link == null) {
      final created = await gateway.create(priceSheetTitle);
      if (created case Left(value: final f)) return left(f);
      link = PriceSheetLink(sheetId: created.getOrElse((_) => ''));
      if (await links.save(link) case Left(value: final f)) return left(f);
    }
    final config = configSource.config;
    final rows = [
      for (final s in summaries.getOrElse((_) => const []))
        if (s.position.isActive)
          PriceSheetRow(
            instrumentId: s.instrument.id,
            name: s.instrument.name,
            code: s.instrument.code ?? '',
            formula: priceFormula(s.instrument, config),
          ),
    ];
    final synced = await gateway.syncRows(link.sheetId, rows);
    if (synced case Left(value: final f)) return left(f);
    return right(link);
  }
}

/// Membaca harga dari Sheet menjadi valuasi bertanggal [today] (ADR-051
/// §3.4). Tidak menyimpan; penyimpanan dan aturan "isian manual menang"
/// ada di pemanggil. Saham yang masih kosong dicoba ulang ([retries] kali,
/// berjeda [retryDelay]) karena rumus mungkin belum selesai dihitung.
final class ReadSheetPrices {
  /// Membuat [ReadSheetPrices].
  const ReadSheetPrices({
    required this.gateway,
    required this.investments,
    this.retries = 2,
    this.retryDelay = const Duration(seconds: 2),
  });

  /// Sheets API.
  final PriceSheetGateway gateway;

  /// Instrumen (jenis tiap `id`).
  final InvestmentRepository investments;

  /// Banyak coba ulang bila ada harga otomatis yang kosong.
  final int retries;

  /// Jeda antarcoba.
  final Duration retryDelay;

  /// Valuasi dari Sheet [sheetId] untuk instrumen yang ada.
  Future<Either<Failure, List<InstrumentValuation>>> call(String sheetId, {required DateTime today}) async {
    final listed = await investments.listInstruments();
    if (listed case Left(value: final f)) return left(f);
    final byId = {for (final i in listed.getOrElse((_) => const [])) i.id: i};
    var cells = const <String, Object?>{};
    for (var attempt = 0; attempt <= retries; attempt++) {
      if (attempt > 0) await Future<void>.delayed(retryDelay);
      final read = await gateway.readPrices(sheetId);
      if (read case Left(value: final f)) return left(f);
      cells = read.getOrElse((_) => const {});
      // Hanya baris berumus (saham, emas) yang ditunggu; isian pengguna tidak.
      final pending = cells.entries.any((e) {
        final type = byId[e.key]?.type;
        final automatic = type == InstrumentType.stock || type == InstrumentType.gold;
        return automatic && unitPriceFromSheet(type!, e.value) == null && (e.value == null || e.value == '');
      });
      if (!pending) break;
    }
    return right([
      for (final MapEntry(:key, :value) in cells.entries)
        if (byId[key] case final instrument?)
          if (unitPriceFromSheet(instrument.type, value) case final price?)
            InstrumentValuation(
              instrumentId: key,
              date: today,
              unitPrice: price,
              source: sheetSourceFor(instrument.type),
            ),
    ]);
  }
}

/// Valuasi Sheet yang boleh disimpan dari [fetched] (ADR-051 §3.4): isian
/// **manual** pada tanggal yang sama untuk instrumen itu tidak ditimpa.
List<InstrumentValuation> sheetValuationsToSave(
  List<InstrumentValuation> fetched,
  Iterable<InstrumentValuation> existing,
) {
  final manualToday = {
    for (final v in existing)
      if (v.source == ValuationSource.manual) '${v.instrumentId}|${v.date.toIso8601String()}',
  };
  return [
    for (final v in fetched)
      if (!manualToday.contains('${v.instrumentId}|${v.date.toIso8601String()}')) v,
  ];
}
