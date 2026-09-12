part of 'grocery_bloc.dart';

/// Event [GroceryBloc].
sealed class GroceryEvent {
  /// Membuat [GroceryEvent].
  const GroceryEvent();
}

/// Memuat rencana belanja bulan bawaan ([GroceryState.cycleId]) beserta
/// daftar `id` siklus yang sudah dibuat (dasar pemilih bulan).
final class GroceryPlanLoaded extends GroceryEvent {
  /// Membuat [GroceryPlanLoaded].
  const GroceryPlanLoaded();
}

/// Berpindah melihat/menyunting rencana belanja bulan [cycleId] —
/// dipancarkan pemilih bulan di `GroceryPage` (pola sama seperti
/// `InvestmentCycleSelected`).
final class GroceryCycleSelected extends GroceryEvent {
  /// Membuat [GroceryCycleSelected].
  const GroceryCycleSelected(this.cycleId);

  /// Identitas siklus (bulan) yang dipilih.
  final String cycleId;
}

/// Menambah (kalau [id] `null`) atau menyunting satu item.
final class GroceryItemSaved extends GroceryEvent {
  /// Membuat [GroceryItemSaved].
  const GroceryItemSaved({
    required this.isWeekly,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.id,
    this.amountOverride,
  });

  /// True untuk daftar mingguan, false untuk daftar bulanan.
  final bool isWeekly;

  /// `null` berarti item baru.
  final String? id;

  /// Nama bahan.
  final String name;

  /// Jumlah.
  final int quantity;

  /// Harga satuan dalam sen.
  final int unitPrice;

  /// Harga manual, kalau ditimpa.
  final int? amountOverride;
}

/// Menghapus item ber-`id` [id] dari daftar mingguan ([isWeekly] true) atau
/// bulanan.
final class GroceryItemRemoved extends GroceryEvent {
  /// Membuat [GroceryItemRemoved].
  const GroceryItemRemoved({required this.isWeekly, required this.id});

  /// True untuk daftar mingguan, false untuk daftar bulanan.
  final bool isWeekly;

  /// Identitas item.
  final String id;
}

/// Mengubah pengali minggu (FR-GROC-003).
final class WeeksPerMonthChanged extends GroceryEvent {
  /// Membuat [WeeksPerMonthChanged].
  const WeeksPerMonthChanged(this.weeksPerMonth);

  /// Pengali baru.
  final int weeksPerMonth;
}
