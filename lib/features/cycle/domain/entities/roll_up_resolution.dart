import 'package:dependencies/dependencies.dart';

/// Hasil penghitungan ulang nominal sebuah `BudgetLine` ber-`kind` `rollUp`.
final class RollUpResolution extends Equatable {
  /// Membuat [RollUpResolution].
  const RollUpResolution({required this.amount, required this.isAvailable});

  /// Sumbernya belum ada — lihat ROADMAP.md Fase 2 ("baris roll-up
  /// ditampilkan bernilai nol dengan penanda bahwa sumbernya belum
  /// tersedia").
  const RollUpResolution.unavailable() : this(amount: 0, isAvailable: false);

  /// Nominal hasil hitung, dalam sen.
  final int amount;

  /// True kalau sumbernya sudah ada dan benar-benar dihitung. False berarti
  /// [amount] hanya nol karena belum ada yang bisa dihitung (belum Fase 4).
  final bool isAvailable;

  @override
  List<Object?> get props => [amount, isAvailable];
}
