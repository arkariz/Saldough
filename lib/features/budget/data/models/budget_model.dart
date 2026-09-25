import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';

/// Model serialisasi [Budget] beserta posnya, terpisah dari entitas domain
/// (tanpa `freezed`, mengikuti konvensi monorepo).
///
/// Hanya field sumber yang ditulis. `plannedAmount` (anggaran maupun pos yang
/// dirinci), `spent`, `remaining`, `progress`, dan status aktif/selesai tidak
/// pernah disimpan — semuanya turunan.
///
/// Skema 1 masih menulis `plannedAmount` tingkat anggaran; sejak ADR-017
/// (skema 2) kunci itu diabaikan saat dibaca dan tidak ditulis lagi.
final class BudgetModel {
  /// Membuat [BudgetModel].
  const BudgetModel({
    required this.id,
    required this.name,
    required this.walletId,
    required this.period,
    required this.startDate,
    required this.items,
    required this.isArchived,
  });

  /// Membaca [BudgetModel] dari JSON.
  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
    id: json['id'] as String,
    name: json['name'] as String,
    walletId: json['walletId'] as String,
    period: json['period'] as String,
    startDate: DateTime.parse(json['startDate'] as String),
    items: (json['items'] as List<dynamic>).map((e) => BudgetItemModel.fromJson(e as Map<String, dynamic>)).toList(),
    isArchived: json['isArchived'] as bool,
  );

  /// Membuat [BudgetModel] dari entitas domain [Budget].
  factory BudgetModel.fromEntity(Budget budget) => BudgetModel(
    id: budget.id,
    name: budget.name,
    walletId: budget.walletId,
    period: budget.period.name,
    startDate: budget.startDate,
    items: budget.items.map(BudgetItemModel.fromEntity).toList(),
    isArchived: budget.isArchived,
  );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 2;

  /// Identitas anggaran.
  final String id;

  /// Nama anggaran.
  final String name;

  /// Dompet sumber.
  final String walletId;

  /// Nama [BudgetPeriod] (`weekly`/`monthly`).
  final String period;

  /// Awal periode.
  final DateTime startDate;

  /// Pos-pos di dalamnya.
  final List<BudgetItemModel> items;

  /// Diarsipkan atau tidak.
  final bool isArchived;

  /// Menulis [BudgetModel] ke JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'walletId': walletId,
    'period': period,
    'startDate': startDate.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'isArchived': isArchived,
  };

  /// Mengubah model ini jadi entitas domain [Budget].
  Budget toEntity() => Budget(
    id: id,
    name: name,
    walletId: walletId,
    period: BudgetPeriod.values.byName(period),
    startDate: startDate,
    items: items.map((i) => i.toEntity()).toList(),
    isArchived: isArchived,
  );
}

/// Model serialisasi [BudgetItem], disimpan di dalam dokumen [BudgetModel].
final class BudgetItemModel {
  /// Membuat [BudgetItemModel].
  const BudgetItemModel({
    required this.id,
    required this.name,
    this.enteredAmount,
    this.quantity,
    this.unitPrice,
  });

  /// Membaca [BudgetItemModel] dari JSON.
  factory BudgetItemModel.fromJson(Map<String, dynamic> json) => BudgetItemModel(
    id: json['id'] as String,
    name: json['name'] as String,
    enteredAmount: json['enteredAmount'] as int?,
    quantity: json['quantity'] as int?,
    unitPrice: json['unitPrice'] as int?,
  );

  /// Membuat [BudgetItemModel] dari entitas domain [BudgetItem].
  factory BudgetItemModel.fromEntity(BudgetItem item) => BudgetItemModel(
    id: item.id,
    name: item.name,
    enteredAmount: item.enteredAmount,
    quantity: item.quantity,
    unitPrice: item.unitPrice,
  );

  /// Identitas pos.
  final String id;

  /// Nama pos.
  final String name;

  /// Nominal yang diketik langsung, dalam sen.
  final int? enteredAmount;

  /// Jumlah barang.
  final int? quantity;

  /// Harga satuan, dalam sen.
  final int? unitPrice;

  /// Menulis [BudgetItemModel] ke JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'enteredAmount': enteredAmount,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };

  /// Mengubah model ini jadi entitas domain [BudgetItem].
  BudgetItem toEntity() => BudgetItem(
    id: id,
    name: name,
    enteredAmount: enteredAmount,
    quantity: quantity,
    unitPrice: unitPrice,
  );
}
