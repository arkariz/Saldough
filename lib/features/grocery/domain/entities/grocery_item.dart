import 'package:dependencies/dependencies.dart';

/// Satu bahan pada `GroceryPlan`. Lihat DOMAIN_MODEL.md bagian "Belanja".
final class GroceryItem extends Equatable {
  /// Membuat [GroceryItem].
  const GroceryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.amountOverride,
  });

  /// Identitas item.
  final String id;

  /// Nama bahan.
  final String name;

  /// Jumlah.
  final int quantity;

  /// Harga satuan dalam sen.
  final int unitPrice;

  /// Harga manual yang mengabaikan hasil perkalian. Wajib ada karena data
  /// nyata memuat koreksi manual — sampo `1 × Rp41.300` berharga Rp24.000
  /// (FR-GROC-002).
  final int? amountOverride;

  /// True kalau [amountOverride] terisi (FR-GROC-002: "menandai item yang
  /// harganya ditimpa").
  bool get isOverridden => amountOverride != null;

  /// Nominal item dalam sen — [amountOverride] kalau ada, kalau tidak
  /// `quantity × unitPrice`.
  int get amount => amountOverride ?? (quantity * unitPrice);

  /// Salinan [GroceryItem] dengan field yang disebutkan diganti.
  ///
  /// ⚠ Tidak menangani [amountOverride] — pakai [clearOverride] untuk
  /// mengosongkannya (jebakan copyWith klasik untuk field nullable, lihat
  /// `MonthlyCycle.copyWith`).
  GroceryItem copyWith({String? name, int? quantity, int? unitPrice, int? amountOverride}) {
    return GroceryItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      amountOverride: amountOverride ?? this.amountOverride,
    );
  }

  /// Salinan [GroceryItem] dengan [amountOverride] dikosongkan, kembali ke
  /// hasil hitung `quantity × unitPrice`.
  GroceryItem clearOverride() =>
      GroceryItem(id: id, name: name, quantity: quantity, unitPrice: unitPrice);

  @override
  List<Object?> get props => [id, name, quantity, unitPrice, amountOverride];
}
