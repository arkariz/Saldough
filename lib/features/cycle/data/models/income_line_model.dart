import 'package:saldough/features/cycle/domain/entities/income_line.dart';

/// Model serialisasi [IncomeLine].
final class IncomeLineModel {
  /// Membuat [IncomeLineModel].
  const IncomeLineModel({
    required this.id,
    required this.label,
    required this.amount,
    this.sourceId,
    this.isTemplate = false,
    this.needsReview = false,
  });

  /// Membaca [IncomeLineModel] dari JSON.
  factory IncomeLineModel.fromJson(Map<String, dynamic> json) => IncomeLineModel(
        id: json['id'] as String,
        label: json['label'] as String,
        amount: json['amount'] as int,
        sourceId: json['sourceId'] as String?,
        isTemplate: json['isTemplate'] as bool? ?? false,
        needsReview: json['needsReview'] as bool? ?? false,
      );

  /// Membuat model dari entitas domain.
  factory IncomeLineModel.fromEntity(IncomeLine line) => IncomeLineModel(
        id: line.id,
        label: line.label,
        amount: line.amount,
        sourceId: line.sourceId,
        isTemplate: line.isTemplate,
        needsReview: line.needsReview,
      );

  /// Identitas baris.
  final String id;

  /// Nama yang tampil.
  final String label;

  /// Nominal dalam sen.
  final int amount;

  /// Rujukan ke `IncomeSource`.
  final String? sourceId;

  /// True kalau baris ikut terbawa saat rollover.
  final bool isTemplate;

  /// True kalau baris ini hasil rollover yang belum dikonfirmasi.
  final bool needsReview;

  /// Menulis [IncomeLineModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'amount': amount,
        'sourceId': sourceId,
        'isTemplate': isTemplate,
        'needsReview': needsReview,
      };

  /// Mengubah model jadi entitas domain.
  IncomeLine toEntity() => IncomeLine(
        id: id,
        label: label,
        amount: amount,
        sourceId: sourceId,
        isTemplate: isTemplate,
        needsReview: needsReview,
      );
}
