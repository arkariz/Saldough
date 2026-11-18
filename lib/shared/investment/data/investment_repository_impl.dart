import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/investment/data/investment_models.dart';
import 'package:saldough/shared/investment/domain/instrument.dart';
import 'package:saldough/shared/investment/domain/investment_repository.dart';

const _instrumentsKey = StorageKey(namespace: 'investment', name: 'instruments');
const _valuationsKey = StorageKey(namespace: 'investment', name: 'valuations');

/// [InvestmentRepository] di atas dua dokumen, `investment_instruments` dan
/// `investment_valuations` (ADR-049 §3.9), mengikuti
/// `SavingsGoalRepositoryImpl`.
final class InvestmentRepositoryImpl with RepositoryGuard implements InvestmentRepository {
  /// Membuat [InvestmentRepositoryImpl].
  const InvestmentRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<Instrument>> get _instruments => StoredValue<List<Instrument>>.json(
    key: _instrumentsKey,
    fromJson: (json) =>
        (json['items'] as List<dynamic>).map((e) => InstrumentModel.fromJson(e as Map<String, dynamic>)).toList(),
    toJson: (items) => {
      'schemaVersion': InstrumentModel.schemaVersion,
      'items': items.map(InstrumentModel.toJson).toList(),
    },
    storage: _storage,
  );

  StoredValue<List<InstrumentValuation>> get _valuations => StoredValue<List<InstrumentValuation>>.json(
    key: _valuationsKey,
    fromJson: (json) =>
        (json['items'] as List<dynamic>).map((e) => ValuationModel.fromJson(e as Map<String, dynamic>)).toList(),
    toJson: (items) => {
      'schemaVersion': ValuationModel.schemaVersion,
      'items': items.map(ValuationModel.toJson).toList(),
    },
    storage: _storage,
  );

  @override
  Future<Either<Failure, List<Instrument>>> listInstruments() => guard(() async => await _instruments.read() ?? const []);

  @override
  Future<Either<Failure, Unit>> saveInstrument(Instrument instrument) => guardVoid(() async {
    final items = await _instruments.read() ?? <Instrument>[];
    final index = items.indexWhere((i) => i.id == instrument.id);
    final next = [...items];
    if (index == -1) {
      next.add(instrument);
    } else {
      next[index] = instrument;
    }
    await _instruments.write(next);
  });

  @override
  Future<Either<Failure, Unit>> deleteInstrument(String id) => guardVoid(() async {
    final items = await _instruments.read() ?? <Instrument>[];
    final valuations = await _valuations.read() ?? <InstrumentValuation>[];
    // Valuasi dulu: valuasi yatim tidak berbahaya, instrumen tanpa valuasi
    // yang seharusnya terhapus juga tidak.
    await _valuations.write(valuations.where((v) => v.instrumentId != id).toList());
    await _instruments.write(items.where((i) => i.id != id).toList());
  });

  @override
  Future<Either<Failure, List<InstrumentValuation>>> listValuations() => guard(() async {
    return [...?await _valuations.read()]..sort((a, b) {
      final byInstrument = a.instrumentId.compareTo(b.instrumentId);
      return byInstrument != 0 ? byInstrument : a.date.compareTo(b.date);
    });
  });

  @override
  Future<Either<Failure, Unit>> saveValuations(List<InstrumentValuation> valuations) => guardVoid(() async {
    if (valuations.isEmpty) return;
    final replaced = {for (final v in valuations) '${v.instrumentId}|${v.date.toIso8601String()}'};
    final items = await _valuations.read() ?? <InstrumentValuation>[];
    await _valuations.write([
      ...items.where((v) => !replaced.contains('${v.instrumentId}|${v.date.toIso8601String()}')),
      ...valuations,
    ]);
  });

  @override
  Future<Either<Failure, Unit>> deleteValuation(String instrumentId, DateTime date) => guardVoid(() async {
    final day = DateTime(date.year, date.month, date.day);
    final items = await _valuations.read() ?? <InstrumentValuation>[];
    await _valuations.write(items.where((v) => !(v.instrumentId == instrumentId && v.date == day)).toList());
  });
}
