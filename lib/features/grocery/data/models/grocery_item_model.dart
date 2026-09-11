import 'package:saldough/features/grocery/domain/entities/grocery_item.dart';

/// Model serialisasi [GroceryItem].
final class GroceryItemModel {
  /// Membuat [GroceryItemModel].
  const GroceryItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.amountOverride,
  });

  /// Membaca [GroceryItemModel] dari JSON.
  factory GroceryItemModel.fromJson(Map<String, dynamic> json) => GroceryItemModel(
        id: json['id'] as String,
        name: json['name'] as String,
        quantity: json['quantity'] as int,
        unitPrice: json['unitPrice'] as int,
        amountOverride: json['amountOverride'] as int?,
      );

  /// Membuat model dari entitas domain.
  factory GroceryItemModel.fromEntity(GroceryItem item) => GroceryItemModel(
        id: item.id,
        name: item.name,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        amountOverride: item.amountOverride,
      );

  /// Identitas item.
  final String id;

  /// Nama bahan.
  final String name;

  /// Jumlah.
  final int quantity;

  /// Harga satuan dalam sen.
  final int unitPrice;

  /// Harga manual yang mengabaikan hasil perkalian.
  final int? amountOverride;

  /// Menulis [GroceryItemModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'amountOverride': amountOverride,
      };

  /// Mengubah model jadi entitas domain.
  GroceryItem toEntity() => GroceryItem(
        id: id,
        name: name,
        quantity: quantity,
        unitPrice: unitPrice,
        amountOverride: amountOverride,
      );
}
