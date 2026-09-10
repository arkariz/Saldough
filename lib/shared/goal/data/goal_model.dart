import 'package:saldough/shared/goal/domain/goal.dart';

/// Model serialisasi [Goal], terpisah dari entitas domain (tanpa `freezed`,
/// mengikuti konvensi monorepo — lihat ARCHITECTURE_OVERVIEW.md).
final class GoalModel {
  /// Membuat [GoalModel].
  const GoalModel({
    required this.id,
    required this.name,
    required this.openingBalance,
  });

  /// Membaca [GoalModel] dari JSON.
  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
        id: json['id'] as String,
        name: json['name'] as String,
        openingBalance: json['openingBalance'] as int,
      );

  /// Membuat [GoalModel] dari entitas domain [Goal].
  factory GoalModel.fromEntity(Goal goal) => GoalModel(
        id: goal.id,
        name: goal.name,
        openingBalance: goal.openingBalance,
      );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 1;

  /// Identitas pos.
  final String id;

  /// Nama pos.
  final String name;

  /// Saldo awal dalam sen.
  final int openingBalance;

  /// Menulis [GoalModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'openingBalance': openingBalance,
      };

  /// Mengubah model jadi entitas domain [Goal].
  Goal toEntity() => Goal(id: id, name: name, openingBalance: openingBalance);
}
