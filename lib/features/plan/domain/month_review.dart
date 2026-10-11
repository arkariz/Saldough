import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Langkah tinjau awal bulan (J4, ADR-036 §3.7). Semuanya bisa dilewati.
enum MonthReviewStep {
  /// Anggaran rutin yang baru lahir.
  budgets,

  /// Rutin bernominal kira-kira.
  estimates,

  /// Kilas balik bulan lalu (W10, W9).
  lookback,
}

/// Status tinjau satu bulan keuangan. Disimpan satu dokumen untuk bulan
/// berjalan; bulan baru menimpanya.
final class MonthReview extends Equatable {
  /// Membuat [MonthReview].
  const MonthReview({
    required this.monthStart,
    this.monthEnd,
    this.doneSteps = const {},
    this.completed = false,
    this.dismissed = false,
  });

  /// Awal bulan keuangan yang ditinjau.
  final DateTime monthStart;

  /// Akhir (eksklusif) periode yang ditinjau (ADR-038); `null` = dokumen
  /// lama, berlaku untuk periode biasa yang mulai [monthStart].
  final DateTime? monthEnd;

  /// Apakah tinjau ini milik [period]. Periode peralihan berawal sama dengan
  /// periode lama tetapi panjangnya berbeda, jadi ia mendapat tinjau sendiri
  /// sekali (FINANCIAL_PERIOD P-9).
  bool isFor(FinancialPeriod period) =>
      monthStart == period.start && (monthEnd == null ? !period.isTransition : monthEnd == period.end);

  /// Langkah yang sudah dicentang.
  final Set<MonthReviewStep> doneSteps;

  /// "Selesai meninjau" ditekan.
  final bool completed;

  /// "Nanti" ditekan: kartu dilipat jadi satu baris.
  final bool dismissed;

  /// Salinan dengan field yang disebutkan diganti.
  MonthReview copyWith({Set<MonthReviewStep>? doneSteps, bool? completed, bool? dismissed}) => MonthReview(
    monthStart: monthStart,
    monthEnd: monthEnd,
    doneSteps: doneSteps ?? this.doneSteps,
    completed: completed ?? this.completed,
    dismissed: dismissed ?? this.dismissed,
  );

  @override
  List<Object?> get props => [monthStart, monthEnd, doneSteps, completed, dismissed];
}

/// Perkiraan akhir bulan yang dibuat saat bulan keuangan pertama kali
/// dibuka (W9, ADR-036 §3.7): semua dompet aktif, setelan di luar rencana
/// saat itu. Hanya di perangkat.
final class ForecastSnapshot extends Equatable {
  /// Membuat [ForecastSnapshot].
  const ForecastSnapshot({required this.monthStart, required this.endBalance, this.takenOn});

  /// Awal bulan keuangan yang diperkirakan.
  final DateTime monthStart;

  /// Perkiraan saldo akhir bulan, sen.
  final int endBalance;

  /// Kapan dibuat; `null` = dokumen lama (dianggap tidak layak untuk W9).
  final DateTime? takenOn;

  /// Layak untuk W9: dibuat dalam [days] hari pertama bulan keuangan,
  /// supaya bulan yang dibuka terlambat tidak tampak "tepat" (T-16.16 K9).
  bool isEarly({required int days}) =>
      takenOn != null && takenOn!.isBefore(DateTime(monthStart.year, monthStart.month, monthStart.day + days));

  /// Berapa bulan terakhir yang disimpan.
  static const keep = 3;

  @override
  List<Object?> get props => [monthStart, endBalance, takenOn];
}

/// [snapshots] dengan [snapshot] bila bulannya belum ada (snapshot pertama
/// menang), urut naik, hanya [ForecastSnapshot.keep] bulan terakhir.
List<ForecastSnapshot> withSnapshot(List<ForecastSnapshot> snapshots, ForecastSnapshot snapshot) {
  if (snapshots.any((s) => s.monthStart == snapshot.monthStart)) return snapshots;
  final all = [...snapshots, snapshot]..sort((a, b) => a.monthStart.compareTo(b.monthStart));
  return all.length <= ForecastSnapshot.keep ? all : all.sublist(all.length - ForecastSnapshot.keep);
}

/// Saldo [walletIds] tepat sebelum [date]: [currentBalance] dikurangi efek
/// transaksi bertanggal [date] atau sesudahnya. Transfer di antara dompet
/// itu tidak mengubah jumlahnya (aturan 7).
int balanceBefore(
  DateTime date, {
  required int currentBalance,
  required Iterable<Transaction> transactions,
  required Set<String> walletIds,
}) {
  var after = 0;
  for (final t in transactions) {
    if (t.date.isBefore(date)) continue;
    after += switch (t) {
      IncomeTransaction(:final walletId, :final amount) => walletIds.contains(walletId) ? amount : 0,
      ExpenseTransaction(:final walletId, :final amount) => walletIds.contains(walletId) ? -amount : 0,
      TransferTransaction(:final fromWalletId, :final toWalletId, :final amount) =>
        (walletIds.contains(toWalletId) ? amount : 0) - (walletIds.contains(fromWalletId) ? amount : 0),
    };
  }
  return currentBalance - after;
}

/// Tinjau awal bulan tersimpan di `plan/month_review` dan snapshot
/// perkiraan di `plan/forecast_snapshots` (ADR-036 §3.7).
abstract interface class MonthReviewRepository {
  /// Status tersimpan, atau `null` bila belum pernah.
  Future<Either<Failure, MonthReview?>> load();

  /// Menyimpan [review], menimpa bulan sebelumnya.
  Future<Either<Failure, Unit>> save(MonthReview review);

  /// Tinjau yang baru disimpan, supaya Beranda dan Bulan ini (bloc
  /// terpisah) sama-sama tahu (T-16.14).
  Stream<MonthReview> get changes;

  /// Snapshot perkiraan tersimpan, urut naik.
  Future<Either<Failure, List<ForecastSnapshot>>> loadSnapshots();

  /// Menyimpan [snapshots] (sudah dipangkas lewat [withSnapshot]).
  Future<Either<Failure, Unit>> saveSnapshots(List<ForecastSnapshot> snapshots);
}
