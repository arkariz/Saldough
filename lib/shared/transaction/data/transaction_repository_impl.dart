import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/transaction/data/transaction_model.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';
import 'package:saldough/shared/transaction/domain/transaction_repository.dart';

const _indexKey = StorageKey(namespace: 'transaction', name: '_index');

/// Format kunci bulan `YYYY-MM`, dipakai sebagai `name` [StorageKey] tiap
/// dokumen bulan dan sebagai entri di dokumen indeks.
String _monthKeyFor(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

/// Implementasi [TransactionRepository] di atas [KeyValueStorage], dengan
/// buku besar dipartisi per bulan. Lihat
/// [ADR-012](../../../docs/02-architecture/adr/0012-tata-letak-penyimpanan-buku-besar.md).
///
/// Kunci `transaction_YYYY-MM` menyimpan satu bulan; kunci `transaction__index`
/// menyimpan daftar bulan yang pernah ditulis, satu-satunya cara tahu bulan
/// mana saja yang ada — [KeyValueStorage] tidak punya operasi "daftar kunci".
final class TransactionRepositoryImpl with RepositoryGuard implements TransactionRepository {
  /// Membuat [TransactionRepositoryImpl] di atas [_storage].
  const TransactionRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<String>> get _indexStore => StoredValue<List<String>>.json(
        key: _indexKey,
        fromJson: (json) => (json['months'] as List<dynamic>).cast<String>(),
        toJson: (months) => {'months': months},
        storage: _storage,
      );

  StoredValue<List<TransactionModel>> _monthStore(String monthKey) => StoredValue<List<TransactionModel>>.json(
        key: StorageKey(namespace: 'transaction', name: monthKey),
        fromJson: (json) => (json['items'] as List<dynamic>)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        toJson: (models) => {
          'schemaVersion': TransactionModel.schemaVersion,
          'items': models.map((m) => m.toJson()).toList(),
        },
        storage: _storage,
      );

  Future<void> _markMonthPresent(String monthKey) async {
    final months = await _indexStore.read() ?? const <String>[];
    if (!months.contains(monthKey)) {
      await _indexStore.write([...months, monthKey]..sort());
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> listTransactionsInMonth(DateTime month) => guard(() async {
        final models = await _monthStore(_monthKeyFor(month)).read();
        return (models ?? const []).map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, List<Transaction>>> listAllTransactions() => guard(() async {
        final months = await _indexStore.read() ?? const <String>[];
        final result = <Transaction>[];
        for (final monthKey in months) {
          final models = await _monthStore(monthKey).read() ?? const <TransactionModel>[];
          result.addAll(models.map((m) => m.toEntity()));
        }
        return result;
      });

  @override
  Future<Either<Failure, Unit>> saveTransaction(Transaction transaction, {DateTime? previousDate}) =>
      guardVoid(() async {
        final targetMonthKey = _monthKeyFor(transaction.date);
        if (previousDate != null) {
          final previousMonthKey = _monthKeyFor(previousDate);
          if (previousMonthKey != targetMonthKey) {
            // Hapus dari dokumen bulan lama LEBIH DULU, sebelum menambah ke
            // dokumen bulan baru — supaya kegagalan di tengah tidak
            // menghasilkan transaksi ganda (lihat dokumentasi antarmuka).
            final previousStore = _monthStore(previousMonthKey);
            final previousModels = await previousStore.read() ?? <TransactionModel>[];
            await previousStore.write(previousModels.where((m) => m.id != transaction.id).toList());
          }
        }

        final targetStore = _monthStore(targetMonthKey);
        final targetModels = await targetStore.read() ?? <TransactionModel>[];
        final next = [
          ...targetModels.where((m) => m.id != transaction.id),
          TransactionModel.fromEntity(transaction),
        ];
        await targetStore.write(next);
        await _markMonthPresent(targetMonthKey);
      });

  @override
  Future<Either<Failure, Unit>> deleteTransaction(String id, DateTime date) => guardVoid(() async {
        final store = _monthStore(_monthKeyFor(date));
        final models = await store.read() ?? <TransactionModel>[];
        await store.write(models.where((m) => m.id != id).toList());
      });
}
