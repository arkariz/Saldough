import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_item.dart';

/// Rencana belanja — satu dokumen PER BULAN (format `id` `YYYY-MM`, sama
/// seperti `MonthlyCycle`), menghasilkan nominal untuk baris anggaran
/// ber-`rollUpSource` `grocery` milik CYCLE DENGAN ID YANG SAMA (tautan 1:1,
/// laporan pemilik). Lihat DOMAIN_MODEL.md bagian "Belanja" dan ADR-0008.
///
/// Sebelum ini, `GroceryPlan` adalah dokumen tunggal dibaca bersama oleh
/// seluruh siklus terbuka — diganti karena pemilik ingin daftar belanja
/// bisa berbeda tiap bulan. `GroceryPlanRepositoryImpl.getPlan` mengisi
/// bulan yang belum pernah disunting dengan SALINAN bulan sebelumnya
/// (bukan kosong), supaya tidak perlu mengetik ulang tiap bulan.
final class GroceryPlan extends Equatable {
  /// Membuat [GroceryPlan].
  const GroceryPlan({
    required this.id,
    required this.weeklyItems,
    required this.monthlyItems,
    this.weeksPerMonth = 4,
  });

  /// Rencana kosong ber-`id` [id] dengan pengali minggu bawaan (FR-GROC-003).
  factory GroceryPlan.empty(String id) => GroceryPlan(id: id, weeklyItems: const [], monthlyItems: const []);

  /// Identitas rencana, format `YYYY-MM` — sama dengan `MonthlyCycle.id`
  /// milik siklus yang ditautkan.
  final String id;

  /// Daftar mingguan.
  final List<GroceryItem> weeklyItems;

  /// Daftar bulanan.
  final List<GroceryItem> monthlyItems;

  /// Pengali daftar mingguan. Bawaan 4.
  final int weeksPerMonth;

  /// Salinan [GroceryPlan] dengan field yang disebutkan diganti. [id] tidak
  /// bisa diganti lewat ini (sama seperti `MonthlyCycle.copyWith`) — bikin
  /// instance baru kalau benar-benar perlu [id] lain.
  GroceryPlan copyWith({List<GroceryItem>? weeklyItems, List<GroceryItem>? monthlyItems, int? weeksPerMonth}) {
    return GroceryPlan(
      id: id,
      weeklyItems: weeklyItems ?? this.weeklyItems,
      monthlyItems: monthlyItems ?? this.monthlyItems,
      weeksPerMonth: weeksPerMonth ?? this.weeksPerMonth,
    );
  }

  @override
  List<Object?> get props => [id, weeklyItems, monthlyItems, weeksPerMonth];
}
