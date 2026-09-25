import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/freelance/data/models/freelance_models.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/domain/repositories/freelance_repository.dart';

const _projectsKey = StorageKey(namespace: 'freelance', name: 'projects');
const _worklogKey = StorageKey(namespace: 'freelance', name: 'worklog');
const _paymentsKey = StorageKey(namespace: 'freelance', name: 'payments');

/// Implementasi [FreelanceRepository] di atas [KeyValueStorage], mengikuti
/// pola `BudgetRepositoryImpl`.
///
/// Tiga dokumen JSON: `freelance/projects`, `freelance/worklog`, dan
/// `freelance/payments` (T-5.2).
///
/// ⚠ Ketiganya sengaja tidak dipartisi karena lajunya rendah — satu entri
/// per hari kerja. Tinjau ulang kalau entrinya melewati beberapa ratus.
final class FreelanceRepositoryImpl with RepositoryGuard implements FreelanceRepository {
  /// Membuat [FreelanceRepositoryImpl] di atas [_storage].
  const FreelanceRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<T>> _store<T>(
    StorageKey key,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(T) toJson,
  ) => StoredValue<List<T>>.json(
    key: key,
    fromJson: (json) => (json['items'] as List<dynamic>).map((e) => fromJson(e as Map<String, dynamic>)).toList(),
    toJson: (items) => {'schemaVersion': freelanceSchemaVersion, 'items': items.map(toJson).toList()},
    storage: _storage,
  );

  StoredValue<List<FreelanceProject>> get _projects =>
      _store(_projectsKey, FreelanceProjectJson.fromJson, FreelanceProjectJson.toJson);

  StoredValue<List<WorklogEntry>> get _worklog =>
      _store(_worklogKey, WorklogEntryJson.fromJson, WorklogEntryJson.toJson);

  StoredValue<List<FreelancePayment>> get _payments =>
      _store(_paymentsKey, FreelancePaymentJson.fromJson, FreelancePaymentJson.toJson);

  /// Menimpa item ber-`id` sama di posisi semula (urutan tidak melompat saat
  /// disunting), menambah sisanya di akhir.
  static List<T> _upsert<T>(List<T> current, List<T> incoming, String Function(T) idOf) {
    final byId = {for (final item in incoming) idOf(item): item};
    final next = [for (final item in current) byId.remove(idOf(item)) ?? item];
    return [...next, ...byId.values];
  }

  @override
  Future<Either<Failure, List<FreelanceProject>>> listProjects() =>
      guard(() async => await _projects.read() ?? const []);

  @override
  Future<Either<Failure, Unit>> saveProject(FreelanceProject project) => guardVoid(() async {
    await _projects.write(_upsert(await _projects.read() ?? const [], [project], (p) => p.id));
  });

  @override
  Future<Either<Failure, Unit>> deleteProject(String id) => guardVoid(() async {
    final projects = await _projects.read() ?? const <FreelanceProject>[];
    await _projects.write(projects.where((p) => p.id != id).toList());
  });

  @override
  Future<Either<Failure, List<WorklogEntry>>> listEntries() => guard(() async => await _worklog.read() ?? const []);

  @override
  Future<Either<Failure, Unit>> saveEntries(List<WorklogEntry> entries) => guardVoid(() async {
    await _worklog.write(_upsert(await _worklog.read() ?? const [], entries, (e) => e.id));
  });

  @override
  Future<Either<Failure, Unit>> deleteEntry(String id) => guardVoid(() async {
    final entries = await _worklog.read() ?? const <WorklogEntry>[];
    await _worklog.write(entries.where((e) => e.id != id).toList());
  });

  @override
  Future<Either<Failure, List<FreelancePayment>>> listPayments() =>
      guard(() async => await _payments.read() ?? const []);

  @override
  Future<Either<Failure, Unit>> savePayment(FreelancePayment payment) => guardVoid(() async {
    await _payments.write(_upsert(await _payments.read() ?? const [], [payment], (p) => p.id));
  });

  @override
  Future<Either<Failure, Unit>> deletePayment(String id) => guardVoid(() async {
    final payments = await _payments.read() ?? const <FreelancePayment>[];
    await _payments.write(payments.where((p) => p.id != id).toList());
  });
}
