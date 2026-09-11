import 'package:saldough/features/investment/domain/entities/goal_loan.dart';

/// Model serialisasi [GoalLoan].
final class GoalLoanModel {
  /// Membuat [GoalLoanModel].
  const GoalLoanModel({
    required this.id,
    required this.fromGoalId,
    required this.toGoalId,
    required this.principal,
    required this.repaid,
    required this.date,
    required this.note,
  });

  /// Membaca [GoalLoanModel] dari JSON.
  factory GoalLoanModel.fromJson(Map<String, dynamic> json) => GoalLoanModel(
        id: json['id'] as String,
        fromGoalId: json['fromGoalId'] as String,
        toGoalId: json['toGoalId'] as String,
        principal: json['principal'] as int,
        repaid: json['repaid'] as int,
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String,
      );

  /// Membuat model dari entitas domain.
  factory GoalLoanModel.fromEntity(GoalLoan loan) => GoalLoanModel(
        id: loan.id,
        fromGoalId: loan.fromGoalId,
        toGoalId: loan.toGoalId,
        principal: loan.principal,
        repaid: loan.repaid,
        date: loan.date,
        note: loan.note,
      );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 1;

  /// Identitas pinjaman.
  final String id;

  /// Rujukan ke `Goal` asal dana.
  final String fromGoalId;

  /// Rujukan ke `Goal` tujuan dana.
  final String toGoalId;

  /// Nominal pokok dalam sen.
  final int principal;

  /// Nominal pengembalian dalam sen.
  final int repaid;

  /// Tanggal pinjaman.
  final DateTime date;

  /// Catatan bebas.
  final String note;

  /// Menulis [GoalLoanModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'fromGoalId': fromGoalId,
        'toGoalId': toGoalId,
        'principal': principal,
        'repaid': repaid,
        'date': date.toIso8601String(),
        'note': note,
      };

  /// Mengubah model jadi entitas domain.
  GoalLoan toEntity() => GoalLoan(
        id: id,
        fromGoalId: fromGoalId,
        toGoalId: toGoalId,
        principal: principal,
        repaid: repaid,
        date: date,
        note: note,
      );
}
