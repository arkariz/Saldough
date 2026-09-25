import 'package:dependencies/dependencies.dart';

/// Satu baris di dalam `Budget`, misalnya `Ikan kembung` atau `Listrik`.
/// Lihat DOMAIN_MODEL.md bagian "Pos anggaran".
///
/// Nominal rencananya diisi salah satu dari dua cara: diketik langsung
/// ([enteredAmount]), atau dirinci jadi [quantity] × [unitPrice] untuk pos
/// yang berupa daftar belanja. Kalau keduanya terisi, rincian yang menang —
/// [plannedAmount] selalu diturunkan, tidak pernah disimpan terpisah dari
/// sumbernya.
final class BudgetItem extends Equatable {
  /// Membuat [BudgetItem]. Isi [enteredAmount], atau [quantity] beserta
  /// [unitPrice].
  const BudgetItem({
    required this.id,
    required this.name,
    this.enteredAmount,
    this.quantity,
    this.unitPrice,
  }) : assert(
         enteredAmount != null || (quantity != null && unitPrice != null),
         'Pos anggaran butuh nominal yang diketik, atau jumlah beserta harga satuan.',
       );

  /// Identitas pos.
  final String id;

  /// Nama pos. Data pengguna, bukan teks antarmuka.
  final String name;

  /// Nominal rencana yang diketik langsung, dalam sen. Diabaikan kalau
  /// [quantity] dan [unitPrice] sama-sama terisi.
  final int? enteredAmount;

  /// Jumlah barang, untuk pos berupa daftar belanja.
  final int? quantity;

  /// Harga satuan dalam sen.
  final int? unitPrice;

  /// Apakah nominal rencana dirinci jadi jumlah × harga satuan.
  bool get isItemized => quantity != null && unitPrice != null;

  /// Nominal rencana dalam sen: `quantity × unitPrice` bila keduanya terisi,
  /// selain itu [enteredAmount].
  int get plannedAmount => isItemized ? quantity! * unitPrice! : enteredAmount!;

  @override
  List<Object?> get props => [id, name, enteredAmount, quantity, unitPrice];
}
