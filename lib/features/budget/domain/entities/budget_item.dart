import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';

/// Satu baris di dalam `Budget`, misalnya `Ikan kembung` atau `Listrik`.
/// Lihat DOMAIN_MODEL.md bagian "Pos anggaran".
///
/// Nominal rencananya diisi salah satu dari dua cara: diketik langsung
/// ([enteredAmount]), atau dirinci jadi [quantity] × [unitPrice] untuk pos
/// yang berupa daftar belanja. Kalau keduanya terisi, rincian yang menang —
/// [plannedAmount] selalu diturunkan, tidak pernah disimpan terpisah dari
/// sumbernya.
///
/// Pos berjenis [BudgetItemKind.transfer] wajib punya [targetWalletId] dan
/// tidak boleh dirinci jadi jumlah × harga satuan (ADR-018).
final class BudgetItem extends Equatable {
  /// Membuat [BudgetItem]. Isi [enteredAmount], atau [quantity] beserta
  /// [unitPrice].
  const BudgetItem({
    required this.id,
    required this.name,
    this.enteredAmount,
    this.quantity,
    this.unitPrice,
    this.kind = BudgetItemKind.expense,
    this.targetWalletId,
    this.templateItemId,
  }) : assert(
         enteredAmount != null || (quantity != null && unitPrice != null),
         'Pos anggaran butuh nominal yang diketik, atau jumlah beserta harga satuan.',
       ),
       assert(
         kind != BudgetItemKind.transfer || (targetWalletId != null && quantity == null && unitPrice == null),
         'Pos transfer butuh dompet tujuan dan nominal yang diketik langsung.',
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

  /// Jenis pos. Data lama tanpa jenis dibaca sebagai pengeluaran.
  final BudgetItemKind kind;

  /// Dompet tujuan untuk pos [BudgetItemKind.transfer]; `null` untuk pos
  /// pengeluaran. Selalu berbeda dari dompet anggarannya.
  final String? targetWalletId;

  /// Kunci pos yang stabil antarperiode anggaran rutin (ADR-036 §3.1): id
  /// pos template yang melahirkannya, atau id pos template itu sendiri.
  /// `null` untuk pos insidental.
  final String? templateItemId;

  /// Apakah pos ini rencana transfer.
  bool get isTransfer => kind == BudgetItemKind.transfer;

  /// Apakah nominal rencana dirinci jadi jumlah × harga satuan.
  bool get isItemized => quantity != null && unitPrice != null;

  /// Nominal rencana dalam sen: `quantity × unitPrice` bila keduanya terisi,
  /// selain itu [enteredAmount].
  int get plannedAmount => isItemized ? quantity! * unitPrice! : enteredAmount!;

  /// Salinan dengan [id], [name], atau [templateItemId] diganti. Nominal
  /// diganti lewat [withAmountOf].
  BudgetItem copyWith({String? id, String? name, String? Function()? templateItemId}) => BudgetItem(
    id: id ?? this.id,
    name: name ?? this.name,
    enteredAmount: enteredAmount,
    quantity: quantity,
    unitPrice: unitPrice,
    kind: kind,
    targetWalletId: targetWalletId,
    templateItemId: templateItemId == null ? this.templateItemId : templateItemId(),
  );

  /// Salinan dengan nominal rencana yang sama dengan [other] (diketik atau
  /// dirinci), field lain tetap.
  BudgetItem withAmountOf(BudgetItem other) => BudgetItem(
    id: id,
    name: name,
    enteredAmount: other.enteredAmount,
    quantity: other.quantity,
    unitPrice: other.unitPrice,
    kind: kind,
    targetWalletId: targetWalletId,
    templateItemId: templateItemId,
  );

  @override
  List<Object?> get props => [id, name, enteredAmount, quantity, unitPrice, kind, targetWalletId, templateItemId];
}
