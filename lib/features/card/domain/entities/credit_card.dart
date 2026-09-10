import 'package:dependencies/dependencies.dart';

/// Satu kartu kredit. Lihat DOMAIN_MODEL.md bagian "Kartu kredit".
final class CreditCard extends Equatable {
  /// Membuat [CreditCard].
  const CreditCard({required this.id, required this.name, required this.statementDayOfMonth});

  /// Identitas kartu.
  final String id;

  /// Nama kartu, misalnya `"CC TOKPED"`.
  final String name;

  /// Tanggal cetak tagihan bulanan. Data, bukan konstanta kode — tiap kartu
  /// boleh punya tanggal berbeda dan pemilik bisa mengubahnya. Nilai seed
  /// terkonfirmasi: 15 (lihat `.claude/AGENT_CONTEXT.md`).
  final int statementDayOfMonth;

  /// Salinan [CreditCard] dengan field yang disebutkan diganti.
  CreditCard copyWith({String? name, int? statementDayOfMonth}) {
    return CreditCard(
      id: id,
      name: name ?? this.name,
      statementDayOfMonth: statementDayOfMonth ?? this.statementDayOfMonth,
    );
  }

  @override
  List<Object?> get props => [id, name, statementDayOfMonth];
}
