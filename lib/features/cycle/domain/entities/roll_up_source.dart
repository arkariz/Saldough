import 'package:dependencies/dependencies.dart';

/// Menunjuk asal angka untuk `BudgetLine` ber-`kind` `rollUp`.
///
/// Hanya dua sumber yang berlaku hari ini (lihat DOMAIN_MODEL.md): rencana
/// belanja, atau satu kartu kredit tertentu. Nominalnya tidak pernah
/// disimpan di baris anggaran — selalu dihitung ulang dari sumber ini saat
/// siklus dibaca (ADR-0008).
sealed class RollUpSource extends Equatable {
  const RollUpSource();

  /// Baris `Bulanan`, dihitung dari rencana belanja ber-`id` [planId] — SAMA
  /// dengan id siklus yang ditautkan (tautan 1:1, laporan pemilik: rencana
  /// belanja sekarang satu dokumen per bulan, bukan lagi satu dokumen
  /// dibaca bersama oleh semua siklus terbuka).
  static RollUpSource grocery(String planId) => GroceryRollUpSource(planId);

  /// Baris tagihan kartu kredit, dihitung dari siklus tagihan [cardId].
  static RollUpSource card(String cardId) => CardRollUpSource(cardId);
}

/// Satu rencana belanja bulanan tertentu sebagai sumber roll-up.
final class GroceryRollUpSource extends RollUpSource {
  /// Membuat [GroceryRollUpSource] untuk rencana ber-`id` [planId].
  const GroceryRollUpSource(this.planId);

  /// Identitas rencana belanja (`GroceryPlan.id`, format `YYYY-MM`).
  final String planId;

  @override
  List<Object?> get props => ['grocery', planId];
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
