import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_memory.dart';
import 'package:saldough/features/period_book/domain/repositories/period_book_memory_store.dart';
import 'package:saldough/features/period_book/domain/services/closed_periods.dart';
import 'package:saldough/features/period_book/domain/services/period_book_access.dart';
import 'package:saldough/features/period_book/domain/services/period_book_shelf.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Pintu tunggal ke hak dan keadaan Buku Periode (ADR-045 §3.1, §3.6): periode
/// tertutup, Rak Buku, ajakan Beranda, dan gerbang rute. Dirakit di akar
/// komposisi karena membaca transaksi, jadwal periode, hak Plus, dan ingatan
/// buku. Tidak pernah melempar: gagal membaca = keadaan paling hati-hati
/// (tanpa ajakan, rak kosong, buku terkunci kecuali sudah diketahui terbuka).
class PeriodBookGate {
  /// Membuat [PeriodBookGate].
  PeriodBookGate({
    required this._entitlements,
    required this._memory,
    required this._transactions,
    required this._schedule,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Entitlements _entitlements;
  final PeriodBookMemoryStore _memory;
  final TransactionRepository _transactions;
  final FinancialMonthPreferenceRepository _schedule;
  final DateTime Function() _now;

  bool get _plusActive => _entitlements.can(PlusFeature.periodBook);

  /// Periode tertutup dengan ≥1 transaksi, terbaru di atas (BP-3).
  Future<List<ClosedPeriod>> closedPeriods() async {
    final transactions = await _transactions.listAllTransactions();
    final schedule = await _schedule.load();
    return transactions.fold((_) => const [], (all) => schedule.fold(
      (_) => const [],
      (s) => closedPeriodsOf(transactions: all, schedule: s, today: _now()),
    ));
  }

  Future<PeriodBookMemory> _loadMemory() async => (await _memory.load()).getOrElse((_) => PeriodBookMemory.empty);

  /// Isi Rak Buku (BP-9, BP-10).
  Future<List<ShelfEntry>> shelf() async => shelfOf(
    closed: await closedPeriods(),
    memory: await _loadMemory(),
    plusActive: _plusActive,
  );

  /// Ajakan akhir periode di Beranda, atau `null` (BP-2, BP-9, BP-14).
  Future<PeriodInvitation?> invitation() async {
    final schedule = (await _schedule.load()).getOrElse((_) => FinancialMonthSchedule.initial);
    return invitationFor(
      closed: await closedPeriods(),
      memory: await _loadMemory(),
      plusActive: _plusActive,
      previousPeriodStart: previousPeriodOf(_now(), schedule).start,
    );
  }

  /// Gerbang rute (BP-10): dipanggil rute ritual, sampul, dan rapor, bukan hanya
  /// UI. Plus aktif membuka apa pun; sesudahnya hanya buku yang pernah dibuka.
  Future<BookAccess> accessOf(String periodId) async =>
      bookAccessOf(plusActive: _plusActive, everOpened: (await _loadMemory()).isOpened(periodId));

  /// Menandai buku [periodId] dibuka sekarang (sekali; tanggal pertama
  /// dipertahankan). Hanya boleh dipanggil sesudah [accessOf] memberi `open`.
  Future<Either<Failure, Unit>> markOpened(String periodId) async {
    final memory = await _loadMemory();
    if (memory.isOpened(periodId)) {
      return const Right(unit);
    }
    return _memory.save(memory.withOpened(periodId, _now()));
  }

  /// Ingatan buku sekarang (untuk melanjutkan ritual, BP-6).
  Future<PeriodBookMemory> memory() => _loadMemory();

  /// Menandai langkah ritual [step] selesai untuk [periodId] (BP-6).
  Future<Either<Failure, Unit>> markStepDone(String periodId, int step) async =>
      _memory.save((await _loadMemory()).withStepDone(periodId, step));

  /// "Nanti" pada kartu Beranda: tidak muncul lagi untuk periode itu (BP-2).
  Future<Either<Failure, Unit>> dismissCard(String periodId) async =>
      _memory.save((await _loadMemory()).withCardDismissed(periodId));

  /// Sakelar Ajakan akhir periode (BP-14).
  Future<Either<Failure, Unit>> setInviteEnabled({required bool enabled}) async =>
      _memory.save((await _loadMemory()).withInviteEnabled(enabled: enabled));
}
