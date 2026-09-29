import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/currency/currency.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late CurrencyPreferenceRepositoryImpl repository;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = CurrencyPreferenceRepositoryImpl(storage: storage);
  });

  Future<AppCurrency> loaded() async => (await repository.load()).getOrElse((_) => throw StateError('Left'));

  test('belum pernah dipilih berarti IDR, mata uang seluruh data lama', () async {
    expect(await loaded(), AppCurrency.idr);
  });

  test('menyimpan lalu membaca kembali pilihan', () async {
    await repository.save(AppCurrency.usd);
    expect(await loaded(), AppCurrency.usd);
  });

  test('kode tak dikenal jatuh ke IDR, bukan gagal', () async {
    await storage.write('settings_currency', '{"schemaVersion":1,"code":"XYZ"}');
    expect(await loaded(), AppCurrency.idr);
  });

  test('dokumen rusak menjadi Left; pemanggil memakai IDR', () async {
    await storage.write('settings_currency', '{bukan json');
    expect((await repository.load()).isLeft(), isTrue);
  });

  test('fromCode tak peka huruf besar', () {
    expect(AppCurrency.fromCode('jpy'), AppCurrency.jpy);
    expect(AppCurrency.fromCode(''), isNull);
  });

  test('pilihan cepat IDR sama persis dengan daftar lama (rupiah x 100)', () {
    expect(AppCurrency.idr.quickAmounts(QuickAmountMultipliers.expense), [1000000, 5000000, 10000000]);
    expect(AppCurrency.idr.quickAmounts(QuickAmountMultipliers.incomeOrTransfer), [50000000, 100000000, 500000000]);
    expect(
      AppCurrency.idr.quickAmounts(QuickAmountMultipliers.walletBalance),
      [10000000, 50000000, 100000000, 500000000],
    );
    expect(AppCurrency.usd.quickAmounts(QuickAmountMultipliers.expense), [100, 500, 1000]);
  });
}
