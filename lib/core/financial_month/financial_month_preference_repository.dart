import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_month_range.dart';
import 'package:saldough/core/foundation/repository_guard.dart';

/// Preferensi tanggal awal bulan keuangan (KT-R2, ADR-034 §3.6).
abstract interface class FinancialMonthPreferenceRepository {
  /// Tanggal awal (1–28); bawaan 1.
  Future<Either<Failure, int>> load();

  /// Menyimpan tanggal awal [startDay] (1–28).
  Future<Either<Failure, Unit>> save(int startDay);
}

const _key = StorageKey(namespace: 'settings', name: 'financial_month_start');

/// Satu dokumen `{schemaVersion, startDay}` di `settings/financial_month_start`.
/// Nilai di luar 1–28 dibaca sebagai 1.
final class FinancialMonthPreferenceRepositoryImpl with RepositoryGuard implements FinancialMonthPreferenceRepository {
  /// Membuat [FinancialMonthPreferenceRepositoryImpl].
  const FinancialMonthPreferenceRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<int> get _store => StoredValue<int>.json(
    key: _key,
    fromJson: (json) => switch (json['startDay']) {
      final int day when day >= financialMonthStartDays.min && day <= financialMonthStartDays.max => day,
      _ => 1,
    },
    toJson: (day) => {'schemaVersion': 1, 'startDay': day},
    storage: _storage,
  );

  @override
  Future<Either<Failure, int>> load() => guard(() async => await _store.read() ?? 1);

  @override
  Future<Either<Failure, Unit>> save(int startDay) {
    assert(startDay >= financialMonthStartDays.min && startDay <= financialMonthStartDays.max, 'Awal bulan 1–28.');
    return guardVoid(() => _store.write(startDay));
  }
}
