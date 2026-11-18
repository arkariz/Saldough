import 'package:saldough/shared/savings_goal/domain/savings_goal.dart';

/// Serialisasi [SavingsGoal] untuk dokumen `savings_goal_all` (ADR-048 §3.4).
abstract final class SavingsGoalModel {
  SavingsGoalModel._();

  /// Versi skema dokumen. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 1;

  /// Membaca satu tujuan dari JSON.
  static SavingsGoal fromJson(Map<String, dynamic> json) => SavingsGoal(
    id: json['id'] as String,
    name: json['name'] as String,
    targetAmount: json['targetAmount'] as int,
    iconKey: json['iconKey'] as String,
    walletId: json['walletId'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    status: SavingsGoalStatus.values.byName(json['status'] as String),
    targetDate: _date(json['targetDate']),
    description: json['description'] as String?,
    completedAt: _date(json['completedAt']),
  );

  /// Menulis satu tujuan ke JSON.
  static Map<String, dynamic> toJson(SavingsGoal goal) => {
    'id': goal.id,
    'name': goal.name,
    'targetAmount': goal.targetAmount,
    'iconKey': goal.iconKey,
    'walletId': goal.walletId,
    'createdAt': goal.createdAt.toIso8601String(),
    'status': goal.status.name,
    if (goal.targetDate case final date?) 'targetDate': date.toIso8601String(),
    'description': ?goal.description,
    if (goal.completedAt case final date?) 'completedAt': date.toIso8601String(),
  };

  static DateTime? _date(Object? value) => value == null ? null : DateTime.parse(value as String);
}
