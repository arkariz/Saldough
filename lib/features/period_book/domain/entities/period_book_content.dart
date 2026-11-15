import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';

/// Halaman 1, Arus periode (BP-4): pemasukan, pengeluaran, selisih; transfer
/// tidak dihitung. Angkanya **sama persis** dengan Arus Beranda.
final class BookFlow extends Equatable {
  /// Membuat [BookFlow].
  const BookFlow({required this.income, required this.expense});

  /// Pemasukan, sen.
  final int income;

  /// Pengeluaran, sen.
  final int expense;

  /// Selisih, sen; boleh negatif (tanpa warna peringatan, rupa D6).
  int get net => income - expense;

  @override
  List<Object?> get props => [income, expense];
}

/// Jenis satu baris di halaman Ke mana uang pergi.
enum BookRowKind {
  /// Kategori (bawaan atau buatan pengguna).
  category,

  /// Pemasukan freelance tanpa kategori (hanya sisi pemasukan Analisis).
  freelance,

  /// Tanpa kategori.
  uncategorized,

  /// Lainnya: gabungan kategori di luar lima teratas.
  others,
}

/// Satu baris halaman 2. Persen dibulatkan setengah ke atas dan **tidak**
/// dipaksa menjumlah 100 (aturan Analisis, B-3).
final class BookSpendRow extends Equatable {
  /// Membuat [BookSpendRow].
  const BookSpendRow({
    required this.kind,
    required this.amount,
    required this.count,
    required this.percent,
    this.belowOne = false,
    this.categoryId,
    this.categoryName,
    this.builtInKey,
  });

  /// Jenisnya.
  final BookRowKind kind;

  /// Nominal, sen.
  final int amount;

  /// Jumlah transaksi.
  final int count;

  /// Persen dari total pengeluaran, bulat.
  final int percent;

  /// Kurang dari 1% ("<1%").
  final bool belowOne;

  /// Id kategori (jenis `category`).
  final String? categoryId;

  /// Nama kategori (jenis `category`).
  final String? categoryName;

  /// Kunci kategori bawaan; `null` = buatan pengguna.
  final String? builtInKey;

  @override
  List<Object?> get props => [kind, amount, count, percent, belowOne, categoryId, categoryName, builtInKey];
}

/// Halaman 2, Ke mana uang pergi: sampai lima kategori teratas, Lainnya, dan
/// Tanpa kategori. Muncul hanya bila ada pengeluaran.
final class BookSpending extends Equatable {
  /// Membuat [BookSpending].
  const BookSpending({required this.total, required this.count, required this.rows});

  /// Total pengeluaran, sen (sama dengan [BookFlow.expense]).
  final int total;

  /// Jumlah transaksi pengeluaran.
  final int count;

  /// Baris, urut seperti Analisis.
  final List<BookSpendRow> rows;

  @override
  List<Object?> get props => [total, count, rows];
}

/// Satu sorotan netral halaman 3 (B-7): kategori dan selisihnya terhadap
/// rata-rata tiga periode. Tanpa warna peringatan, tanpa penilaian (BP-7).
final class BookHighlight extends Equatable {
  /// Membuat [BookHighlight].
  const BookHighlight({
    required this.kind,
    required this.amount,
    required this.average,
    required this.percent,
    required this.isHigher,
    this.categoryId,
    this.categoryName,
  });

  /// `category` atau `freelance`.
  final BookRowKind kind;

  /// Nominal periode ini, sen.
  final int amount;

  /// Rata-rata periode pembanding, sen, dibulatkan setengah ke atas.
  final int average;

  /// Selisih persen terhadap rata-rata, bulat, selalu positif; arahnya di [isHigher].
  final int percent;

  /// Lebih tinggi dari rata-rata (tanda +), atau lebih rendah (tanda −).
  final bool isHigher;

  /// Id kategori.
  final String? categoryId;

  /// Nama kategori.
  final String? categoryName;

  @override
  List<Object?> get props => [kind, amount, average, percent, isHigher, categoryId, categoryName];
}

/// Halaman 3, Dibanding biasanya: paling banyak tiga sorotan. Hanya ada bila
/// ada pembanding dan periodenya bukan periode peralihan.
final class BookCompare extends Equatable {
  /// Membuat [BookCompare].
  const BookCompare({required this.highlights, required this.months});

  /// Sorotan, urut selisih terbesar; bisa kosong (halaman dilewati).
  final List<BookHighlight> highlights;

  /// Berapa periode pembanding (1–3).
  final int months;

  @override
  List<Object?> get props => [highlights, months];
}

/// Halaman 4, Rutin dan rencana.
final class BookPlan extends Equatable {
  /// Membuat [BookPlan].
  const BookPlan({this.recorded = 0, this.skipped = 0, this.planned, this.spent});

  /// Kemunculan rutin yang tercatat atau tertaut di periode ini.
  final int recorded;

  /// Kemunculan rutin yang dilewati.
  final int skipped;

  /// Total rencana anggaran periode ini, sen; `null` bila tidak ada anggaran.
  final int? planned;

  /// Total terpakai, sen; `null` bila tidak ada anggaran.
  final int? spent;

  /// Ada rutin yang dihitung.
  bool get hasRoutine => recorded + skipped > 0;

  /// Ada anggaran.
  bool get hasBudget => planned != null;

  @override
  List<Object?> get props => [recorded, skipped, planned, spent];
}

/// Isi buku satu periode (halaman 1–4; BUKU_PERIODE §7). Halaman bersyarat
/// bernilai `null` bila datanya tidak ada. Dihitung langsung dari data, tidak
/// disimpan (BP-4).
final class PeriodBookContent extends Equatable {
  /// Membuat [PeriodBookContent].
  const PeriodBookContent({
    required this.period,
    required this.flow,
    required this.uncategorizedCount,
    this.spending,
    this.compare,
    this.plan,
  });

  /// Periodenya.
  final ClosedPeriod period;

  /// Halaman 1 (selalu ada).
  final BookFlow flow;

  /// Jumlah transaksi pemasukan dan pengeluaran tanpa kategori, untuk catatan
  /// netral "n transaksi belum berkategori" (rupa D6); 0 = tanpa catatan.
  final int uncategorizedCount;

  /// Halaman 2, bila ada pengeluaran.
  final BookSpending? spending;

  /// Halaman 3, bila ada pembanding dan bukan peralihan.
  final BookCompare? compare;

  /// Halaman 4, bila ada rutin atau anggaran.
  final BookPlan? plan;

  @override
  List<Object?> get props => [period, flow, uncategorizedCount, spending, compare, plan];
}
