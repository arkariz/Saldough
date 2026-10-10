import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/core/foundation/repository_guard.dart';

/// Riwayat tanggal mulai bulan keuangan (ADR-038 §3.1).
abstract interface class FinancialMonthPreferenceRepository {
  /// Jadwal tersimpan; bawaan tanggal 1 sejak awal.
  Future<Either<Failure, FinancialMonthSchedule>> load();

  /// Menyimpan [schedule].
  Future<Either<Failure, Unit>> save(FinancialMonthSchedule schedule);
}

const _key = StorageKey(namespace: 'settings', name: 'financial_month_schedule');

/// Preferensi lama satu angka (ADR-035 §3.6), hanya dibaca untuk migrasi.
const _legacyKey = StorageKey(namespace: 'settings', name: 'financial_month_start');

/// Satu dokumen `{schemaVersion, entries: [{effectiveFrom, startDay}]}` di
/// `settings/financial_month_schedule`; `startDay` angka 1–28 atau
/// `"lastDay"`. Bila belum ada, preferensi lama `settings/financial_month_start`
/// dibaca sebagai satu entri yang berlaku sejak awal (P-2). Entri tidak sah
/// dilewati; tanpa entri sah, tanggal 1.
final class FinancialMonthPreferenceRepositoryImpl with RepositoryGuard implements FinancialMonthPreferenceRepository {
  /// Membuat [FinancialMonthPreferenceRepositoryImpl].
  const FinancialMonthPreferenceRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<FinancialMonthSchedule> get _store => StoredValue<FinancialMonthSchedule>.json(
    key: _key,
    fromJson: (json) {
      final entries = <FinancialMonthScheduleEntry>[
        if (json['entries'] case final List<Object?> list)
          for (final item in list)
            if (item case {'effectiveFrom': final String from, 'startDay': final Object? day})
              if ((DateTime.tryParse(from), FinancialMonthStart.fromJson(day)) case (final from?, final start?))
                (effectiveFrom: DateTime(from.year, from.month, from.day), start: start),
      ]..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
      return entries.isEmpty ? FinancialMonthSchedule.initial : FinancialMonthSchedule(entries);
    },
    toJson: (schedule) => {
      'schemaVersion': 1,
      'entries': [
        for (final entry in schedule.entries)
          {'effectiveFrom': _date(entry.effectiveFrom), 'startDay': entry.start.toJson()},
      ],
    },
    storage: _storage,
  );

  StoredValue<FinancialMonthStart> get _legacy => StoredValue<FinancialMonthStart>.json(
    key: _legacyKey,
    fromJson: (json) => FinancialMonthStart.fromJson(json['startDay']) ?? FinancialMonthStart.first,
    toJson: (start) => {'schemaVersion': 1, 'startDay': start.toJson()},
    storage: _storage,
  );

  @override
  Future<Either<Failure, FinancialMonthSchedule>> load() => guard(() async {
    final stored = await _store.read();
    if (stored != null) return stored;
    final legacy = await _legacy.read();
    return legacy == null ? FinancialMonthSchedule.initial : FinancialMonthSchedule.single(legacy);
  });

  @override
  Future<Either<Failure, Unit>> save(FinancialMonthSchedule schedule) => guardVoid(() => _store.write(schedule));
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
