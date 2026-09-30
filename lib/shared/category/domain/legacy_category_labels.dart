import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/category/domain/category.dart';

/// Satu label kategori teks bebas lama (`categoryKey`) beserta jenis
/// transaksinya.
final class LegacyCategoryLabel extends Equatable {
  /// Membuat [LegacyCategoryLabel].
  const LegacyCategoryLabel({required this.kind, required this.label});

  /// Jenis transaksi pemilik label.
  final CategoryKind kind;

  /// Label apa adanya (ejaan pertama yang ditemukan).
  final String label;

  @override
  List<Object?> get props => [kind, label];
}

/// Port migrasi label kategori lama (ADR-026 §3.4), diimplementasikan
/// `shared/transaction` yang tahu tata letak buku besar — pola port kecil
/// ADR-0009.
abstract interface class LegacyCategoryLabels {
  /// Label unik (per jenis, beda huruf besar/spasi dihitung satu) pada
  /// pemasukan dan pengeluaran yang belum punya kategori. Label transfer tidak
  /// ikut.
  Future<Either<Failure, List<LegacyCategoryLabel>>> listLabels();

  /// Mengganti label lama tiap transaksi dengan id dari [idFor]; label pada
  /// transfer dibuang. Transaksi yang sudah punya kategori tidak disentuh.
  Future<Either<Failure, Unit>> replaceLabels(String? Function(LegacyCategoryLabel label) idFor);
}
