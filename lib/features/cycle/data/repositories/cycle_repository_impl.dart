import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/cycle/data/models/cycle_model.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:saldough/features/cycle/domain/repositories/roll_up_resolver.dart';
import 'package:saldough/shared/income/income.dart';

const _indexKey = StorageKey(namespace: 'cycle', name: '_index');

StorageKey _cycleKey(String id) => StorageKey(namespace: 'cycle', name: id);

/// Implementasi [CycleRepository] di atas [KeyValueStorage], mengikuti pola
/// `CycleRepositoryImpl` di ARCHITECTURE_OVERVIEW.md.
///
/// Setiap [getCycle] menghitung ulang baris `rollUp` lewat [_resolver] —
/// nilai di dokumen tersimpan tidak pernah dipercaya (ADR-0008) — KECUALI
/// siklus sudah `isClosed` (T-4.12): begitu dikunci, nilai roll-up yang
/// tersimpan dibekukan apa adanya. Tanpa ini, siklus tertutup akan terus
/// bergerak setiap kali dibaca ulang kalau sumbernya (kartu/belanja) berubah
/// setelah bulan itu ditutup — bertentangan dengan makna "ditutup".
final class CycleRepositoryImpl
    with RepositoryGuard
    implements CycleRepository {
  /// Membuat [CycleRepositoryImpl] di atas [_storage], [_resolver], dan
  /// [_incomeSourceRepository].
  const CycleRepositoryImpl({
    required this._storage,
    required this._resolver,
    required this._incomeSourceRepository,
  });

  final KeyValueStorage _storage;
  final RollUpResolver _resolver;

  /// Dipakai untuk menyegarkan label dan nominal baris pemasukan yang
  /// ditautkan ke `IncomeSource` (lihat [_resolveIncomeSources]) — bukan
  /// lewat port baru, karena `IncomeSource` sudah di `shared/` (boleh
  /// diimpor langsung lintas fitur, ADR-0009), sama seperti `CycleBloc`
  /// sudah melakukannya untuk mengisi chip sumber di layar.
  final IncomeSourceRepository _incomeSourceRepository;

  StoredValue<CycleModel> _cycleStore(String id) =>
      StoredValue<CycleModel>.json(
        key: _cycleKey(id),
        fromJson: CycleModel.fromJson,
        toJson: (m) => m.toJson(),
        storage: _storage,
      );

  StoredValue<List<String>> get _indexStore => StoredValue<List<String>>.json(
    key: _indexKey,
    fromJson: (json) => (json['ids'] as List<dynamic>).cast<String>(),
    toJson: (ids) => {'ids': ids},
    storage: _storage,
  );

  @override
  Future<Either<Failure, MonthlyCycle?>> getCycle(String id) => guard(() async {
    final model = await _cycleStore(id).read();
    if (model == null) return null;
    final withRollUps = await _resolveRollUps(model.toEntity());
    return _resolveIncomeSources(withRollUps);
  });

  Future<MonthlyCycle> _resolveRollUps(MonthlyCycle cycle) async {
    if (cycle.isClosed) return cycle;
    final resolvedLines = await Future.wait(
      cycle.budgetLines.map((line) async {
        if (line.kind != .rollUp) return line;
        final resolution = await _resolver.resolve(line.rollUpSource!);
        return line.copyWith(
          amount: resolution.amount,
          rollUpSourceUnavailable: !resolution.isAvailable,
        );
      }),
    );
    return cycle.copyWith(budgetLines: resolvedLines);
  }

  /// Menyegarkan baris pemasukan yang ditautkan ke `IncomeSource`
  /// (`IncomeLine.sourceId`) dari nilai TERKINI sumbernya — bukan nilai yang
  /// dibekukan saat baris disimpan. Pola yang sama dengan [_resolveRollUps]
  /// (ADR-0008): hanya berlaku selagi siklus masih terbuka, supaya siklus
  /// yang sudah ditutup tidak diam-diam berubah kalau sumbernya disunting
  /// belakangan (perbaikan atas laporan pemilik: baris pemasukan
  /// sebelumnya tidak pernah mengikuti perubahan nama/nominal sumbernya).
  ///
  /// Hanya `label` dan (untuk [IncomeSourceKind.fixedSalary]) `amount` yang
  /// disegarkan. Nominal sumber [IncomeSourceKind.hourlyFreelance] TIDAK
  /// disegarkan — nominal itu hasil suntik `CycleIncomeWriter` setelah buku
  /// jam ditutup (T-3.9), snapshot gaji bersih historis yang tidak boleh
  /// ikut bergeser kalau tarif per jam berubah belakangan.
  Future<MonthlyCycle> _resolveIncomeSources(MonthlyCycle cycle) async {
    if (cycle.isClosed) return cycle;
    final resolvedLines = await Future.wait(
      cycle.incomeLines.map((line) async {
        final sourceId = line.sourceId;
        if (sourceId == null) return line;
        final result = await _incomeSourceRepository.getSource(sourceId);
        return result.fold((_) => line, (source) {
          if (source == null) return line;
          final amount =
              source.kind == .fixedSalary && source.fixedAmount != null
              ? source.fixedAmount!
              : line.amount;
          return line.copyWith(label: source.name, amount: amount);
        });
      }),
    );
    return cycle.copyWith(incomeLines: resolvedLines);
  }

  @override
  Future<Either<Failure, List<String>>> listCycleIds() => guard(() async {
    final ids = await _indexStore.read() ?? const [];
    return [...ids]..sort();
  });

  @override
  Future<Either<Failure, Unit>> saveCycle(MonthlyCycle cycle) =>
      guardVoid(() async {
        await _cycleStore(cycle.id).write(CycleModel.fromEntity(cycle));
        final ids = await _indexStore.read() ?? const [];
        if (!ids.contains(cycle.id)) {
          await _indexStore.write([...ids, cycle.id]);
        }
      });

  @override
  Future<Either<Failure, Unit>> deleteCycle(String id) => guardVoid(() async {
    await _cycleStore(id).remove();
    final ids = await _indexStore.read() ?? const [];
    if (ids.contains(id)) {
      await _indexStore.write(ids.where((existing) => existing != id).toList());
    }
  });
}
