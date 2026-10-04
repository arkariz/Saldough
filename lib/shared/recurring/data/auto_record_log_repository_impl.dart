import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/recurring/domain/auto_record.dart';

const _logKey = StorageKey(namespace: 'recurring', name: 'auto_record_log');

/// Lebih panjang dari jendela catat otomatis (awal bulan lalu sampai hari
/// ini), supaya kemunculan yang dibatalkan tidak dicatat lagi.
const _retention = Duration(days: 70);

/// [AutoRecordLogRepository] satu dokumen di `recurring/auto_record_log`.
final class AutoRecordLogRepositoryImpl with RepositoryGuard implements AutoRecordLogRepository {
  /// Membuat [AutoRecordLogRepositoryImpl].
  const AutoRecordLogRepositoryImpl({required this._storage, this._clock = DateTime.now});

  final KeyValueStorage _storage;
  final DateTime Function() _clock;

  StoredValue<List<AutoRecordEntry>> get _store => StoredValue<List<AutoRecordEntry>>.json(
    key: _logKey,
    fromJson: (json) => [
      for (final e in json['items'] as List<dynamic>)
        if (e case final Map<String, dynamic> m)
          AutoRecordEntry(
            transactionId: m['transactionId'] as String,
            ruleId: m['ruleId'] as String,
            ruleName: m['ruleName'] as String,
            occurrenceDate: DateTime.parse(m['occurrenceDate'] as String),
            recordedAt: DateTime.parse(m['recordedAt'] as String),
            undone: m['undone'] as bool? ?? false,
          ),
    ],
    toJson: (entries) => {
      'schemaVersion': 1,
      'items': [
        for (final e in entries)
          {
            'transactionId': e.transactionId,
            'ruleId': e.ruleId,
            'ruleName': e.ruleName,
            'occurrenceDate': e.occurrenceDate.toIso8601String(),
            'recordedAt': e.recordedAt.toIso8601String(),
            'undone': e.undone,
          },
      ],
    },
    storage: _storage,
  );

  List<AutoRecordEntry> _fresh(List<AutoRecordEntry>? entries, DateTime now) => [
    for (final e in entries ?? const <AutoRecordEntry>[])
      if (now.difference(e.recordedAt) < _retention) e,
  ];

  @override
  Future<Either<Failure, List<AutoRecordEntry>>> list(DateTime now) =>
      guard(() async => _fresh(await _store.read(), now));

  @override
  Future<Either<Failure, Unit>> add(List<AutoRecordEntry> entries) => guardVoid(() async {
    final current = _fresh(await _store.read(), _clock());
    await _store.write([...entries, ...current]);
  });

  @override
  Future<Either<Failure, Unit>> markUndone(String transactionId) => guardVoid(() async {
    final current = _fresh(await _store.read(), _clock());
    await _store.write([
      for (final e in current)
        if (e.transactionId == transactionId) e.markUndone() else e,
    ]);
  });
}
