import 'package:saldough/features/cycle/data/models/roll_up_source_model.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line_kind.dart';

/// Model serialisasi [BudgetLine].
///
/// ⚠ [amount] pada baris [BudgetLineKind.rollUp] TIDAK pernah dibaca saat
/// memuat siklus (ADR-0008) — tersimpan apa adanya cuma sebagai jejak
/// riwayat, `CycleRepositoryImpl` selalu menghitungnya ulang lewat
/// `RollUpResolver` dan menimpa nilainya sebelum dikembalikan ke domain.
final class BudgetLineModel {
  /// Membuat [BudgetLineModel].
  const BudgetLineModel({
    required this.id,
    required this.label,
    required this.amount,
    required this.kind,
    this.rollUpSourceJson,
    this.isTemplate = false,
    this.needsReview = false,
  });

  /// Membaca [BudgetLineModel] dari JSON.
  factory BudgetLineModel.fromJson(Map<String, dynamic> json) => BudgetLineModel(
        id: json['id'] as String,
        label: json['label'] as String,
        amount: json['amount'] as int,
        kind: BudgetLineKind.values.byName(json['kind'] as String),
        rollUpSourceJson: json['rollUpSource'] as Map<String, dynamic>?,
        isTemplate: json['isTemplate'] as bool? ?? false,
        needsReview: json['needsReview'] as bool? ?? false,
      );

  /// Membuat model dari entitas domain.
  factory BudgetLineModel.fromEntity(BudgetLine line) => BudgetLineModel(
        id: line.id,
        label: line.label,
        amount: line.amount,
        kind: line.kind,
        rollUpSourceJson: RollUpSourceModel.toJson(line.rollUpSource),
        isTemplate: line.isTemplate,
        needsReview: line.needsReview,
      );

  /// Identitas baris.
  final String id;

  /// Nama yang tampil.
  final String label;

  /// Nominal dalam sen — lihat peringatan di atas untuk baris `rollUp`.
  final int amount;

  /// Jenis baris.
  final BudgetLineKind kind;

  /// JSON mentah sumber roll-up, diuraikan lewat [RollUpSourceModel].
  final Map<String, dynamic>? rollUpSourceJson;

  /// True kalau baris ikut terbawa saat rollover.
  final bool isTemplate;

  /// True kalau baris ini hasil rollover yang belum dikonfirmasi.
  final bool needsReview;

  /// Menulis [BudgetLineModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'amount': amount,
        'kind': kind.name,
        'rollUpSource': rollUpSourceJson,
        'isTemplate': isTemplate,
        'needsReview': needsReview,
      };

  /// Mengubah model jadi entitas domain, dengan [amount] opsional menimpa
  /// nilai tersimpan — dipakai `CycleRepositoryImpl` untuk menyisipkan hasil
  /// [RollUpResolver] pada baris `rollUp`.
  BudgetLine toEntity({int? resolvedAmount, bool rollUpSourceUnavailable = false}) => BudgetLine(
        id: id,
        label: label,
        amount: resolvedAmount ?? amount,
        kind: kind,
        rollUpSource: RollUpSourceModel.fromJson(rollUpSourceJson),
        isTemplate: isTemplate,
        needsReview: needsReview,
        rollUpSourceUnavailable: kind == BudgetLineKind.rollUp && rollUpSourceUnavailable,
      );
}
