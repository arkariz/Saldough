import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/worklog/data/models/billing_book_model.dart';
import 'package:saldough/features/worklog/domain/entities/billing_book.dart';
import 'package:saldough/features/worklog/domain/entities/work_log_entry.dart';
import 'package:saldough/features/worklog/domain/repositories/worklog_repository.dart';

StorageKey _booksKey(String sourceId) => StorageKey(namespace: 'worklog', name: sourceId);

/// Implementasi [WorklogRepository] di atas [KeyValueStorage]: seluruh buku
/// satu sumber tersimpan sebagai satu dokumen JSON, mengikuti pola
/// `GoalRepositoryImpl` (ADR-0009).
final class WorklogRepositoryImpl with RepositoryGuard implements WorklogRepository {
  /// Membuat [WorklogRepositoryImpl] di atas [_storage].
  const WorklogRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<BillingBookModel>> _store(String sourceId) => StoredValue<List<BillingBookModel>>.json(
        key: _booksKey(sourceId),
        fromJson: (json) => (json['items'] as List<dynamic>)
            .map((e) => BillingBookModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        toJson: (models) => {
          'schemaVersion': BillingBookModel.schemaVersion,
          'items': models.map((m) => m.toJson()).toList(),
        },
        storage: _storage,
      );

  @override
  Future<Either<Failure, List<BillingBook>>> listBooks(String sourceId) => guard(() async {
        final models = await _store(sourceId).read();
        return (models ?? const []).map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, BillingBook>> addEntry({
    required String sourceId,
    required WorkLogEntry entry,
  }) =>
      guard(() async {
        final store = _store(sourceId);
        final books = (await store.read() ?? const []).map((m) => m.toEntity()).toList();
        final open = books.where((b) => !b.isClosed).firstOrNull;

        final BillingBook target;
        if (open != null && !entry.startsNewBook) {
          target = open.withEntry(entry);
        } else {
          target = BillingBook.startWith(id: _freshId(), sourceId: sourceId, entry: entry);
        }

        final next = [
          ...books.where((b) => b.id != target.id),
          target,
        ].map(BillingBookModel.fromEntity).toList();
        await store.write(next);
        return target;
      });

  @override
  Future<Either<Failure, Unit>> saveBook(BillingBook book) => guardVoid(() async {
        final store = _store(book.sourceId);
        final books = await store.read() ?? const [];
        final next = [
          ...books.where((m) => m.id != book.id),
          BillingBookModel.fromEntity(book),
        ];
        await store.write(next);
      });

  String _freshId() => DateTime.now().microsecondsSinceEpoch.toString();
}
