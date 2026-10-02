import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/recurring/data/recurring_rule_model.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule_repository.dart';

const _rulesKey = StorageKey(namespace: 'recurring', name: 'all');

/// Implementasi [RecurringRuleRepository] di atas [KeyValueStorage].
///
/// Seluruh rutin disimpan sebagai satu dokumen JSON di kunci `recurring/all`
/// (ADR-012, ADR-034 §3.1): jumlahnya puluhan, bukan ribuan.
final class RecurringRuleRepositoryImpl with RepositoryGuard implements RecurringRuleRepository {
  /// Membuat [RecurringRuleRepositoryImpl] di atas [_storage].
  const RecurringRuleRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<RecurringRule>> get _store => StoredValue<List<RecurringRule>>.json(
    key: _rulesKey,
    fromJson: (json) =>
        (json['items'] as List<dynamic>).map((e) => RecurringRuleModel.fromJson(e as Map<String, dynamic>)).toList(),
    toJson: (rules) => {
      'schemaVersion': RecurringRuleModel.schemaVersion,
      'items': rules.map(RecurringRuleModel.toJson).toList(),
    },
    storage: _storage,
  );

  @override
  Future<Either<Failure, List<RecurringRule>>> listRules() => guard(() async => await _store.read() ?? const []);

  @override
  Future<Either<Failure, Unit>> saveRule(RecurringRule rule) => guardVoid(() async {
    final rules = await _store.read() ?? <RecurringRule>[];
    final index = rules.indexWhere((r) => r.id == rule.id);
    // Menimpa di posisi semula supaya urutan daftar tidak melompat.
    final next = [...rules];
    if (index == -1) {
      next.add(rule);
    } else {
      next[index] = rule;
    }
    await _store.write(next);
  });

  @override
  Future<Either<Failure, Unit>> deleteRule(String id) => guardVoid(() async {
    final rules = await _store.read() ?? <RecurringRule>[];
    await _store.write(rules.where((r) => r.id != id).toList());
  });
}
