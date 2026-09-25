import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';

/// Rencana pengeluaran untuk satu periode, terikat pada satu dompet.
///
/// ⚠ Anggaran adalah rencana, **bukan pemesanan uang**. Membuat, menyunting,
/// atau mengarsipkannya tidak pernah mengubah saldo dompet mana pun (aturan 5
/// CLAUDE.md). Beberapa anggaran boleh aktif sekaligus, berbagi satu dompet,
/// dan berbeda periode. Lihat DOMAIN_MODEL.md bagian "Anggaran".
final class Budget extends Equatable {
  /// Membuat [Budget].
  const Budget({
    required this.id,
    required this.name,
    required this.walletId,
    required this.period,
    required this.startDate,
    required this.plannedAmount,
    this.items = const [],
    this.isArchived = false,
  });

  /// Identitas anggaran.
  final String id;

  /// Nama yang dipilih pemilik, misalnya `Belanja`. Data pengguna.
  final String name;

  /// Dompet sumber. **Wajib** — hanya pengeluaran dari dompet ini, dan
  /// transfer yang keluar dari dompet ini, yang terhitung ke posnya.
  final String walletId;

  /// Panjang periode.
  final BudgetPeriod period;

  /// Awal berlakunya periode. Hanya tanggalnya yang dipakai.
  final DateTime startDate;

  /// Nominal rencana tingkat anggaran dalam sen, diketik pemilik — bukan
  /// jumlah nominal rencana posnya.
  final int plannedAmount;

  /// Pos-pos di dalamnya. Boleh kosong.
  final List<BudgetItem> items;

  /// Satu-satunya bagian siklus hidup yang disimpan. Lihat [statusAt].
  final bool isArchived;

  /// Batas akhir periode, eksklusif. Lihat [BudgetPeriod.endFrom].
  DateTime get endDate => period.endFrom(startDate);

  /// Status siklus hidup pada saat [now]. [BudgetStatus.finished] mulai
  /// berlaku tepat di [endDate].
  BudgetStatus statusAt(DateTime now) {
    if (isArchived) return BudgetStatus.archived;
    return now.isBefore(endDate) ? BudgetStatus.active : BudgetStatus.finished;
  }

  /// Salinan [Budget] dengan field yang disebutkan diganti.
  Budget copyWith({
    String? name,
    String? walletId,
    BudgetPeriod? period,
    DateTime? startDate,
    int? plannedAmount,
    List<BudgetItem>? items,
    bool? isArchived,
  }) {
    return Budget(
      id: id,
      name: name ?? this.name,
      walletId: walletId ?? this.walletId,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      plannedAmount: plannedAmount ?? this.plannedAmount,
      items: items ?? this.items,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  List<Object?> get props => [id, name, walletId, period, startDate, plannedAmount, items, isArchived];
}
