import 'dart:convert';
import 'dart:io';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// ADR-051: rumus per jenis, konversi harga, Sheets API lewat HTTP tiruan,
/// sinkron baris, coba ulang, dan isian manual menang.
void main() {
  final created = DateTime(2026, 11);
  Instrument inst(String id, InstrumentType type, {String? code}) =>
      Instrument(id: id, name: id.toUpperCase(), type: type, createdAt: created, code: code);

  group('rumus dan konversi', () {
    test('saham berkode → IDX; emas → perkiraan GLD; lainnya diisi pengguna', () {
      const config = PriceSheetConfig.defaults;
      expect(
        priceFormula(inst('a', InstrumentType.stock, code: 'bbca'), config),
        '=IFERROR(GOOGLEFINANCE("IDX:BBCA","price"),"")',
      );
      expect(priceFormula(inst('b', InstrumentType.stock), config), isNull);
      expect(priceFormula(inst('c', InstrumentType.stock, code: 'BB"CA'), config), isNull);
      expect(
        priceFormula(inst('g', InstrumentType.gold), config),
        '=IFERROR(GOOGLEFINANCE("NYSEARCA:GLD","price")/0.0919*GOOGLEFINANCE("CURRENCY:USDIDR")/31.1035,"")',
      );
      expect(priceFormula(inst('m', InstrumentType.mutualFund), config), isNull);
      expect(priceFormula(inst('o', InstrumentType.bond), config), isNull);
    });

    test('Remote Config: nilai sah dipakai, di luar batas memakai bawaan', () {
      expect(PriceSheetConfig.fromValues(const {PriceSheetConfig.goldKey: '91500'}).goldMicroOuncesPerGldShare, 91500);
      expect(PriceSheetConfig.fromValues(const {PriceSheetConfig.goldKey: '5'}), PriceSheetConfig.defaults);
      expect(PriceSheetConfig.fromValues(const {}), PriceSheetConfig.defaults);
    });

    test('harga sel → unitPrice sen; obligasi persen; bukan angka diabaikan', () {
      expect(unitPriceFromSheet(InstrumentType.stock, 5750), 575000);
      expect(unitPriceFromSheet(InstrumentType.gold, 2401234.567), 240123457);
      expect(unitPriceFromSheet(InstrumentType.bond, 100.5), 1005000);
      expect(unitPriceFromSheet(InstrumentType.mutualFund, '1351.22'), 135122);
      expect(unitPriceFromSheet(InstrumentType.stock, ''), isNull);
      expect(unitPriceFromSheet(InstrumentType.stock, '#N/A'), isNull);
      expect(unitPriceFromSheet(InstrumentType.stock, 0), isNull);
    });

    test('isian manual hari itu tidak ditimpa valuasi Sheet', () {
      final today = DateTime(2026, 11, 18);
      final fetched = [
        InstrumentValuation(instrumentId: 'a', date: today, unitPrice: 1, source: ValuationSource.sheet),
        InstrumentValuation(instrumentId: 'b', date: today, unitPrice: 2, source: ValuationSource.sheet),
      ];
      final existing = [
        InstrumentValuation(instrumentId: 'a', date: today, unitPrice: 9),
        InstrumentValuation(instrumentId: 'b', date: today, unitPrice: 8, source: ValuationSource.sheet),
      ];
      expect(sheetValuationsToSave(fetched, existing).map((v) => v.instrumentId), ['b']);
    });
  });

  group('GoogleSheetsPriceGateway', () {
    late List<(String, Uri, Object?)> calls;
    late List<(int, String)> replies;
    GoogleSheetsPriceGateway gateway({String? token = 't'}) => GoogleSheetsPriceGateway(
      accessToken: () async => token,
      transport: (method, uri, {required token, body}) async {
        calls.add((method, uri, body == null ? null : jsonDecode(body)));
        return replies.removeAt(0);
      },
    );

    setUp(() {
      calls = [];
      replies = [];
    });

    test('create: locale en_US lalu baris judul', () async {
      replies = [(200, '{"spreadsheetId":"S1"}'), (200, '{}')];
      final id = await gateway().create(priceSheetTitle);
      expect(id, right<Failure, String>('S1'));
      expect((calls[0].$3! as Map)['properties'], {'title': priceSheetTitle, 'locale': 'en_US'});
      expect(calls[1].$2.path, endsWith('/S1/values/A1:D1'));
      expect((calls[1].$3! as Map)['values'], [GoogleSheetsPriceGateway.header]);
    });

    test('syncRows: baris ada diperbarui di tempat, baru ditambah; Harga pengguna tidak ditimpa', () async {
      replies = [
        (200, '{"values":[["a"],[],["catatan pengguna"],["m"]]}'),
        (200, '{}'),
      ];
      final result = await gateway().syncRows('S1', const [
        PriceSheetRow(instrumentId: 'a', name: 'BBCA', code: 'BBCA', formula: '=F'),
        PriceSheetRow(instrumentId: 'm', name: 'RDPU', code: ''),
        PriceSheetRow(instrumentId: 'n', name: 'Baru', code: 'TLKM', formula: '=G'),
      ]);
      expect(result.isRight(), isTrue);
      final data = ((calls[1].$3! as Map)['data'] as List).cast<Map<String, dynamic>>();
      expect(data.map((d) => d['range']), ['A2:D2', 'A5:C5', 'A6:D6']);
      expect(data[1]['values'], [
        ['m', 'RDPU', ''],
      ]);
      expect((calls[1].$3! as Map)['valueInputOption'], 'USER_ENTERED');
    });

    test('readPrices: kolom D per id, nilai mentah', () async {
      replies = [(200, '{"values":[["a","BBCA","BBCA",5750],["m","RDPU",""],["g","Emas","",2401234.5]]}')];
      final prices = (await gateway().readPrices('S1')).getOrElse((_) => const {});
      expect(prices, {'a': 5750, 'm': null, 'g': 2401234.5});
      expect(calls.single.$2.queryParameters['valueRenderOption'], 'UNFORMATTED_VALUE');
    });

    test('galat: tanpa token, 403, 404, jaringan', () async {
      FailureCode? code(Either<Failure, Object?> r) => r.fold((f) => f.code, (_) => null);
      expect(code(await gateway(token: null).readPrices('S1')), PriceSheetFailures.notAuthorized);
      replies = [(403, '{}')];
      expect(code(await gateway().readPrices('S1')), PriceSheetFailures.notAuthorized);
      replies = [(404, '{}')];
      expect(code(await gateway().readPrices('S1')), PriceSheetFailures.notFound);
      final offline = GoogleSheetsPriceGateway(
        accessToken: () async => 't',
        transport: (method, uri, {required token, body}) => throw const SocketException('mati'),
      );
      expect(code(await offline.readPrices('S1')), PriceSheetFailures.unreachable);
    });
  });

  group('use case', () {
    late InMemoryKeyValueStorage storage;
    late InvestmentRepositoryImpl investments;
    late TransactionRepositoryImpl transactions;
    late PriceSheetLinkStoreImpl links;
    setUp(() async {
      storage = InMemoryKeyValueStorage();
      investments = InvestmentRepositoryImpl(storage: storage);
      transactions = TransactionRepositoryImpl(storage: storage);
      links = PriceSheetLinkStoreImpl(storage: storage);
      await investments.saveInstrument(inst('a', InstrumentType.stock, code: 'BBCA'));
      await investments.saveInstrument(inst('g', InstrumentType.gold));
      await investments.saveInstrument(inst('m', InstrumentType.mutualFund));
    });

    test('SyncPriceSheet: membuat Sheet sekali, menyimpan tautan, menulis instrumen Aktif', () async {
      final gateway = _FakeGateway();
      final sync = SyncPriceSheet(gateway: gateway, links: links, investments: investments, transactions: transactions);
      final link = (await sync()).getOrElse((_) => throw StateError('gagal'));
      await sync();
      expect(gateway.created, 1);
      expect(link.sheetId, 'S1');
      expect((await links.read()).getOrElse((_) => null)?.sheetId, 'S1');
      expect(gateway.rows.map((r) => (r.instrumentId, r.formula != null)), [('a', true), ('g', true), ('m', false)]);
    });

    test('ReadSheetPrices: coba ulang saat saham masih kosong; emas perkiraan; isian pengguna dibaca', () async {
      final gateway = _FakeGateway()
        ..reads = [
          {'a': '', 'g': null, 'm': 1351.22},
          {'a': 5750, 'g': 2401234.5, 'm': 1351.22},
        ];
      final read = ReadSheetPrices(gateway: gateway, investments: investments, retryDelay: Duration.zero);
      final today = DateTime(2026, 11, 18);
      final values = (await read('S1', today: today)).getOrElse((_) => const []);
      expect(gateway.readCount, 2);
      expect({for (final v in values) v.instrumentId: (v.unitPrice, v.source)}, {
        'a': (575000, ValuationSource.sheet),
        'g': (240123450, ValuationSource.sheetEstimate),
        'm': (135122, ValuationSource.sheet),
      });
      expect(values.every((v) => v.date == today), isTrue);
    });

    test('RefreshSheetPrices: belum terhubung, jeda 15 menit, Segarkan, isian manual menang', () async {
      final gateway = _FakeGateway()..reads = [
        {'a': 5750, 'g': 2401234.5, 'm': null},
      ];
      var clock = DateTime(2026, 11, 18, 9);
      RefreshSheetPrices refresher() => RefreshSheetPrices(
        sync: SyncPriceSheet(gateway: gateway, links: links, investments: investments, transactions: transactions),
        read: ReadSheetPrices(gateway: gateway, investments: investments, retryDelay: Duration.zero),
        links: links,
        investments: investments,
        now: () => clock,
      );
      expect((await refresher()()).getOrElse((_) => throw StateError('x')).outcome, SheetRefreshOutcome.notLinked);
      await links.save(const PriceSheetLink(sheetId: 'S1'));
      // Isian manual BBCA hari ini tidak boleh ditimpa.
      await investments.saveValuations([
        InstrumentValuation(instrumentId: 'a', date: DateTime(2026, 11, 18), unitPrice: 600000),
      ]);
      expect((await refresher()()).getOrElse((_) => throw StateError('x')).outcome, SheetRefreshOutcome.updated);
      final saved = (await investments.listValuations()).getOrElse((_) => const []);
      expect({for (final v in saved) v.instrumentId: (v.unitPrice, v.source)}, {
        'a': (600000, ValuationSource.manual),
        'g': (240123450, ValuationSource.sheetEstimate),
      });
      expect((await links.read()).getOrElse((_) => null)?.lastFetchedAt, clock);
      clock = clock.add(const Duration(minutes: 10));
      expect((await refresher()()).getOrElse((_) => throw StateError('x')).outcome, SheetRefreshOutcome.fresh);
      expect((await refresher()(force: true)).getOrElse((_) => throw StateError('x')).outcome, SheetRefreshOutcome.updated);
    });

    test('ConnectPriceSheet: izin ditolak tidak membuat Sheet; izin diberikan membuat dan mengambil', () async {
      final gateway = _FakeGateway()..reads = [
        {'a': 5750},
      ];
      final sync = SyncPriceSheet(gateway: gateway, links: links, investments: investments, transactions: transactions);
      final refresh = RefreshSheetPrices(
        sync: sync,
        read: ReadSheetPrices(gateway: gateway, investments: investments, retryDelay: Duration.zero),
        links: links,
        investments: investments,
      );
      final denied = await ConnectPriceSheet(authorize: () async => false, sync: sync, refresh: refresh)();
      expect(denied.fold((f) => f.code, (_) => null), PriceSheetFailures.notAuthorized);
      expect(gateway.created, 0);
      final granted = await ConnectPriceSheet(authorize: () async => true, sync: sync, refresh: refresh)();
      expect(granted.getOrElse((_) => throw StateError('x')), (outcome: SheetRefreshOutcome.updated, saved: 1));
      expect(gateway.created, 1);
    });

    test('model valuasi bolak-balik untuk sumber perkiraan', () {
      final v = InstrumentValuation(
        instrumentId: 'g',
        date: DateTime(2026, 11, 18),
        unitPrice: 1,
        source: ValuationSource.sheetEstimate,
      );
      expect(ValuationModel.fromJson(ValuationModel.toJson(v)), v);
    });
  });
}

final class _FakeGateway implements PriceSheetGateway {
  int created = 0;
  List<PriceSheetRow> rows = const [];
  List<Map<String, Object?>> reads = const [];
  int readCount = 0;

  @override
  Future<Either<Failure, String>> create(String title) async {
    created++;
    return right('S1');
  }

  @override
  Future<Either<Failure, Unit>> syncRows(String sheetId, List<PriceSheetRow> rows) async {
    this.rows = rows;
    return right(unit);
  }

  @override
  Future<Either<Failure, Map<String, Object?>>> readPrices(String sheetId) async {
    final i = readCount < reads.length ? readCount : reads.length - 1;
    readCount++;
    return right(reads[i]);
  }
}
