import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';

/// Satu kalimat Kata Tanuki sebagai **fakta**, bukan teks (BP-8, BUKU_PERIODE §9).
/// Teksnya (id/en, "kamu", tanpa penilaian) dirakit lapisan presentasi dari
/// kunci `book.tanuki.*`, jadi mesin ini murni, bisa diuji tanpa bahasa, dan
/// tidak pernah menyentuh jaringan atau model bahasa.
sealed class TanukiLine extends Equatable {
  const TanukiLine();

  @override
  List<Object?> get props => const [];
}

/// "Periode ini kamu mencatat n transaksi."
final class TanukiRecords extends TanukiLine {
  /// Membuat [TanukiRecords].
  const TanukiRecords(this.count);

  /// Jumlah transaksi periode.
  final int count;

  @override
  List<Object?> get props => [count];
}

/// "Pemasukan …, pengeluaran …, sisanya …." (atau "selisihnya" bila negatif).
final class TanukiFlow extends TanukiLine {
  /// Membuat [TanukiFlow].
  const TanukiFlow({required this.income, required this.expense});

  /// Pemasukan, sen.
  final int income;

  /// Pengeluaran, sen.
  final int expense;

  /// Selisih, sen.
  int get net => income - expense;

  @override
  List<Object?> get props => [income, expense];
}

/// "X jadi kategori terbesar, n% dari pengeluaran."
final class TanukiTopCategory extends TanukiLine {
  /// Membuat [TanukiTopCategory].
  const TanukiTopCategory({required this.name, required this.percent});

  /// Nama kategori (halaman buku memakai nama asli).
  final String name;

  /// Persen dari pengeluaran.
  final int percent;

  @override
  List<Object?> get props => [name, percent];
}

/// "Semua rutin sudah beres: n tercatat, m dilewati."
final class TanukiRecurringClear extends TanukiLine {
  /// Membuat [TanukiRecurringClear].
  const TanukiRecurringClear({required this.recorded, required this.skipped});

  /// Rutin tercatat atau tertaut.
  final int recorded;

  /// Rutin dilewati.
  final int skipped;

  @override
  List<Object?> get props => [recorded, skipped];
}

/// "Semua transaksi punya kategori, jadi angkanya tepat."
final class TanukiTidy extends TanukiLine {
  /// Membuat [TanukiTidy].
  const TanukiTidy();
}

/// Paling banyak kalimat Kata Tanuki (BUKU_PERIODE §9).
const tanukiMaxLines = 4;

/// Memilih kalimat Kata Tanuki dari [content] dengan aturan tetap (BP-7, BP-8),
/// dua sampai empat kalimat, **urut tampil**: catatan, arus, kategori terbesar,
/// rutin, kerapian.
///
/// Kalimat yang berlaku: arus (selalu), catatan (selalu), kategori terbesar
/// (ada pengeluaran berkategori), rutin (ada rutin dan **semuanya beres**: tanpa
/// yang Menunggu atau Terlewat), kerapian (tidak ada transaksi tanpa kategori).
/// Bila lima-limanya berlaku, kalimat catatan yang dibuang (jumlahnya paling
/// sedikit bercerita); prioritas lain: arus, kategori, rutin, kerapian.
///
/// Tidak ada kalimat yang menilai belanja, menyuruh kebiasaan, atau
/// membandingkan dengan pengguna lain.
List<TanukiLine> tanukiLinesOf(PeriodBookContent content) {
  final records = TanukiRecords(content.period.transactionCount);
  final flow = TanukiFlow(income: content.flow.income, expense: content.flow.expense);
  final top = content.spending?.rows.where((r) => r.kind == BookRowKind.category).firstOrNull;
  final plan = content.plan;
  final topLine = top == null || top.categoryName == null
      ? null
      : TanukiTopCategory(name: top.categoryName!, percent: top.percent);
  final recurring = plan != null && plan.hasRoutine && plan.open == 0
      ? TanukiRecurringClear(recorded: plan.recorded, skipped: plan.skipped)
      : null;
  final tidy = content.uncategorizedCount == 0 ? const TanukiTidy() : null;

  // Urut prioritas bila harus dibuang: catatan paling akhir.
  final byPriority = <TanukiLine>[flow, ?topLine, ?recurring, ?tidy, records];
  final kept = byPriority.take(tanukiMaxLines).toSet();
  // Urut tampil.
  return [
    if (kept.contains(records)) records,
    flow,
    if (topLine != null && kept.contains(topLine)) topLine,
    if (recurring != null && kept.contains(recurring)) recurring,
    if (tidy != null && kept.contains(tidy)) tidy,
  ];
}
