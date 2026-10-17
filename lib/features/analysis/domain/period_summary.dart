import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/category/category.dart';

/// Macam baris pada daftar Analisis (FINANCIAL_ANALYSIS B-9, B-10).
enum AnalysisGroupKind {
  /// Satu kategori tersimpan.
  category,

  /// Pemasukan pembayaran freelance tanpa kategori: kelompok turunan, bukan
  /// kategori tersimpan (B-9, KT-A4).
  freelance,

  /// Transaksi tanpa kategori; tidak pernah masuk [others] (B-10).
  uncategorized,

  /// Gabungan kategori di luar lima teratas, bila ada dua atau lebih (B-10).
  others,
}

/// Persen tampil satu baris (B-8): nominal ÷ total × 100 dibulatkan setengah
/// ke atas. Di atas 0 dan di bawah 0,5% tampil "<1%" ([belowOne]). Jumlah
/// persen antarbaris tidak dipaksa 100.
final class AnalysisShare extends Equatable {
  /// Membuat [AnalysisShare].
  const AnalysisShare({required this.percent, required this.belowOne});

  /// Persen [amount] dari [total], dalam bilangan bulat murni (tanpa `double`).
  factory AnalysisShare.of(int amount, int total) {
    if (total <= 0 || amount <= 0) return const AnalysisShare(percent: 0, belowOne: false);
    final percent = (amount * 200 + total) ~/ (2 * total);
    return AnalysisShare(percent: percent, belowOne: percent == 0);
  }

  /// Persen bulat; 0 bila [belowOne].
  final int percent;

  /// Nominal > 0 tetapi di bawah 0,5% dari total: tampil "<1%".
  final bool belowOne;

  @override
  List<Object?> get props => [percent, belowOne];
}

/// Satu baris legenda Analisis.
final class AnalysisGroup extends Equatable {
  /// Membuat [AnalysisGroup].
  const AnalysisGroup({
    required this.kind,
    required this.amount,
    required this.count,
    required this.share,
    this.category,
    this.children = const [],
  });

  /// Macam baris.
  final AnalysisGroupKind kind;

  /// Kategori untuk [AnalysisGroupKind.category]; selain itu `null`.
  final Category? category;

  /// Nominal dalam sen.
  final int amount;

  /// Jumlah transaksi di baris ini.
  final int count;

  /// Persen dari total jenisnya.
  final AnalysisShare share;

  /// Anggota [AnalysisGroupKind.others], urut nominal; selain itu kosong.
  final List<AnalysisGroup> children;

  /// Kategori diarsipkan tetap dihitung dan ditandai (B-14).
  bool get isArchived => category?.isArchived ?? false;

  /// Kunci stabil baris ini untuk pilihan di donat dan legenda.
  String get key => switch (kind) {
    AnalysisGroupKind.category => 'cat:${category!.id}',
    AnalysisGroupKind.freelance => 'freelance',
    AnalysisGroupKind.uncategorized => 'uncategorized',
    AnalysisGroupKind.others => 'others',
  };

  /// Nama untuk mengurutkan nominal yang sama: nama kategori; kelompok
  /// turunan memakai kunci tetap.
  String get sortName => switch (kind) {
    AnalysisGroupKind.category => category!.name.toLowerCase(),
    AnalysisGroupKind.freelance => 'freelance',
    AnalysisGroupKind.uncategorized => 'tanpa kategori',
    AnalysisGroupKind.others => 'lainnya',
  };

  @override
  List<Object?> get props => [kind, category, amount, count, share, children];
}

/// Transfer di periode itu sebagai informasi (B-4): tidak masuk total atau
/// persen.
final class TransferInfo extends Equatable {
  /// Membuat [TransferInfo].
  const TransferInfo({
    required this.total,
    required this.incoming,
    required this.outgoing,
    required this.perWallet,
  });

  /// Tanpa transfer.
  static const none = TransferInfo(
    total: 0,
    incoming: 0,
    outgoing: 0,
    perWallet: false,
  );

  /// Semua dompet: jumlah seluruh transfer periode.
  final int total;

  /// Satu dompet: transfer masuk ke dompet itu.
  final int incoming;

  /// Satu dompet: transfer keluar dari dompet itu.
  final int outgoing;

  /// Dihitung untuk satu dompet (dua baris: masuk dan keluar).
  final bool perWallet;

  /// Ada transfer yang perlu ditampilkan.
  bool get hasAny => perWallet ? incoming > 0 || outgoing > 0 : total > 0;

  @override
  List<Object?> get props => [total, incoming, outgoing, perWallet];
}

/// Ringkasan satu jenis (pengeluaran atau pemasukan) untuk satu periode
/// (FR-ANL-001).
final class PeriodSummary extends Equatable {
  /// Membuat [PeriodSummary].
  const PeriodSummary({
    required this.kind,
    required this.total,
    required this.groups,
    required this.transfers,
    required this.count,
  });

  /// Pengeluaran atau pemasukan.
  final CategoryKind kind;

  /// Total jenis ini, dalam sen. Sama dengan jumlah nominal [groups] (B-8).
  final int total;

  /// Baris legenda sesuai urutan tampil: terbesar dulu (maksimal lima),
  /// lalu Lainnya, lalu Tanpa kategori.
  final List<AnalysisGroup> groups;

  /// Informasi transfer.
  final TransferInfo transfers;

  /// Jumlah transaksi jenis ini di periode.
  final int count;

  /// Tidak ada transaksi jenis ini.
  bool get isEmpty => total == 0;

  /// Baris ber-[key], termasuk anggota Lainnya; `null` bila tidak ada.
  AnalysisGroup? groupOf(String key) {
    for (final group in groups) {
      if (group.key == key) return group;
      for (final child in group.children) {
        if (child.key == key) return child;
      }
    }
    return null;
  }

  /// Indeks irisan donat yang menyala untuk [key]: baris itu sendiri, atau
  /// Lainnya bila [key] anggotanya; `null` bila tidak ada.
  int? sliceOf(String key) {
    for (final (i, group) in groups.indexed) {
      if (group.key == key || group.children.any((child) => child.key == key)) return i;
    }
    return null;
  }

  @override
  List<Object?> get props => [kind, total, groups, transfers, count];
}
