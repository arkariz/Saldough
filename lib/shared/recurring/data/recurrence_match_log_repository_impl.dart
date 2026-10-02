import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/recurring/domain/recurrence_match_log.dart';

const _logKey = StorageKey(namespace: 'recurring', name: 'match_log');

/// Masa simpan log tautan otomatis, sama dengan kotak masuk notifikasi
/// (ADR-032 §3.6).
const _retention = Duration(days: 7);

/// [RecurrenceMatchLogRepository] satu dokumen di `recurring/match_log`.
/// Entri lewat 7 hari dibuang saat dibaca dan saat ditulis.
final class RecurrenceMatchLogRepositoryImpl with RepositoryGuard implements RecurrenceMatchLogRepository {
  /// Membuat [RecurrenceMatchLogRepositoryImpl].
  const RecurrenceMatchLogRepositoryImpl({required this._storage, this._clock = DateTime.now});

  final KeyValueStorage _storage;
  final DateTime Function() _clock;

  StoredValue<List<RecurrenceMatchEntry>> get _store => StoredValue<List<RecurrenceMatchEntry>>.json(
    key: _logKey,
    fromJson: (json) => [
      for (final e in json['items'] as List<dynamic>)
        if (e case final Map<String, dynamic> m)
          RecurrenceMatchEntry(
            transactionId: m['transactionId'] as String,
            transactionDate: DateTime.parse(m['transactionDate'] as String),
            ruleId: m['ruleId'] as String,
            ruleName: m['ruleName'] as String,
            occurrenceDate: DateTime.parse(m['occurrenceDate'] as String),
            amount: m['amount'] as int,
            matchedAt: DateTime.parse(m['matchedAt'] as String),
          ),
    ],
    toJson: (entries) => {
      'schemaVersion': 1,
      'items': [
        for (final e in entries)
          {
            'transactionId': e.transactionId,
            'transactionDate': e.transactionDate.toIso8601String(),
            'ruleId': e.ruleId,
            'ruleName': e.ruleName,
            'occurrenceDate': e.occurrenceDate.toIso8601String(),
            'amount': e.amount,
            'matchedAt': e.matchedAt.toIso8601String(),
          },
      ],
    },
    storage: _storage,
  );

  List<RecurrenceMatchEntry> _fresh(List<RecurrenceMatchEntry>? entries, DateTime now) => [
    for (final e in entries ?? const <RecurrenceMatchEntry>[])
      if (now.difference(e.matchedAt) < _retention) e,
  ];

  @override
  Future<Either<Failure, List<RecurrenceMatchEntry>>> list(DateTime now) =>
      guard(() async => _fresh(await _store.read(), now));

  @override
  Future<Either<Failure, Unit>> add(RecurrenceMatchEntry entry) => guardVoid(() async {
    final current = _fresh(await _store.read(), _clock());
    await _store.write([entry, ...current.where((e) => e.transactionId != entry.transactionId)]);
  });

  @override
  Future<Either<Failure, Unit>> remove(String transactionId) => guardVoid(() async {
    final current = _fresh(await _store.read(), _clock());
    await _store.write([...current.where((e) => e.transactionId != transactionId)]);
  });
}
