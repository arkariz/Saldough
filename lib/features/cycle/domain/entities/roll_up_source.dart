import 'package:dependencies/dependencies.dart';

/// Menunjuk asal angka untuk `BudgetLine` ber-`kind` `rollUp`.
///
/// Hanya dua sumber yang berlaku hari ini (lihat DOMAIN_MODEL.md): rencana
/// belanja, atau satu kartu kredit tertentu. Nominalnya tidak pernah
/// disimpan di baris anggaran — selalu dihitung ulang dari sumber ini saat
/// siklus dibaca (ADR-0008).
sealed class RollUpSource extends Equatable {
  const RollUpSource();

  /// Baris `Bulanan`, dihitung dari rencana belanja bulanan.
  static const grocery = GroceryRollUpSource();

  /// Baris tagihan kartu kredit, dihitung dari siklus tagihan [cardId].
  static RollUpSource card(String cardId) => CardRollUpSource(cardId);
}

/// Rencana belanja bulanan sebagai sumber roll-up.
final class GroceryRollUpSource extends RollUpSource {
  /// Membuat [GroceryRollUpSource].
  const GroceryRollUpSource();

  @override
  List<Object?> get props => const ['grocery'];
}

/// Satu kartu kredit sebagai sumber roll-up.
final class CardRollUpSource extends RollUpSource {
  /// Membuat [CardRollUpSource] untuk kartu ber-`id` [cardId].
  const CardRollUpSource(this.cardId);

  /// Identitas kartu kredit.
  final String cardId;

  @override
  List<Object?> get props => ['card', cardId];
}
