import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_item.dart';

/// Rencana belanja — satu dokumen tunggal (bukan per bulan), menghasilkan
/// nominal untuk baris anggaran ber-`rollUpSource` `grocery`. Lihat
/// DOMAIN_MODEL.md bagian "Belanja".
final class GroceryPlan extends Equatable {
  /// Membuat [GroceryPlan].
  const GroceryPlan({
    required this.weeklyItems,
    required this.monthlyItems,
    this.weeksPerMonth = 4,
  });

  /// Rencana kosong dengan pengali minggu bawaan (FR-GROC-003).
  factory GroceryPlan.empty() => const GroceryPlan(weeklyItems: [], monthlyItems: []);

  /// Daftar mingguan.
  final List<GroceryItem> weeklyItems;

  /// Daftar bulanan.
  final List<GroceryItem> monthlyItems;

  /// Pengali daftar mingguan. Bawaan 4.
  final int weeksPerMonth;

  /// Salinan [GroceryPlan] dengan field yang disebutkan diganti.
  GroceryPlan copyWith({List<GroceryItem>? weeklyItems, List<GroceryItem>? monthlyItems, int? weeksPerMonth}) {
    return GroceryPlan(
      weeklyItems: weeklyItems ?? this.weeklyItems,
      monthlyItems: monthlyItems ?? this.monthlyItems,
      weeksPerMonth: weeksPerMonth ?? this.weeksPerMonth,
    );
  }

  @override
  List<Object?> get props => [weeklyItems, monthlyItems, weeksPerMonth];
}
