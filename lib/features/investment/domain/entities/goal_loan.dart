import 'package:dependencies/dependencies.dart';

/// Satu pinjaman antar pos tujuan (FR-INV-004). Lihat DOMAIN_MODEL.md bagian
/// "Pos tujuan dan pinjaman".
final class GoalLoan extends Equatable {
  /// Membuat [GoalLoan].
  const GoalLoan({
    required this.id,
    required this.fromGoalId,
    required this.toGoalId,
    required this.principal,
    required this.repaid,
    required this.date,
    this.note = '',
  });

  /// Identitas pinjaman.
  final String id;

  /// Rujukan ke `Goal` asal dana.
  final String fromGoalId;

  /// Rujukan ke `Goal` tujuan dana.
  final String toGoalId;

  /// Nominal pokok dalam sen.
  final int principal;

  /// Nominal pengembalian dalam sen — boleh berbeda dari [principal]. Contoh
  /// nyata: pokok Rp9.300.000 dikembalikan Rp9.331.000.
  final int repaid;

  /// Tanggal pinjaman.
  final DateTime date;

  /// Catatan bebas.
  final String note;

  /// Salinan [GoalLoan] dengan field yang disebutkan diganti.
  GoalLoan copyWith({
    String? fromGoalId,
    String? toGoalId,
    int? principal,
    int? repaid,
    DateTime? date,
    String? note,
  }) {
    return GoalLoan(
      id: id,
      fromGoalId: fromGoalId ?? this.fromGoalId,
      toGoalId: toGoalId ?? this.toGoalId,
      principal: principal ?? this.principal,
      repaid: repaid ?? this.repaid,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [id, fromGoalId, toGoalId, principal, repaid, date, note];
}
