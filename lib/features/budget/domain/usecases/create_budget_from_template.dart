import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';

/// Membuat [Budget] mandiri dari sebuah [BudgetTemplate] (T-7.3,
/// FR-BUD-005). Dart murni, tanpa I/O — penyimpanannya tetap lewat
/// `BudgetRepository`, dan tidak ada saldo dompet yang berubah (aturan 5).
///
/// ⚠ Setiap pos mendapat id BARU dari `newItemId`. Kalau id pos template
/// dipakai ulang, dua anggaran dari template yang sama akan berbagi id pos,
/// dan satu transaksi tertaut akan terhitung di keduanya. `newItemId` harus
/// menghasilkan id unik di setiap panggilan, juga di dalam satu putaran.
///
/// ⚠ Pos transfer template membawa dompet tujuan, padahal dompet anggaran
/// baru dipilih di sini. Kalau keduanya sama, pos itu tidak sah (ADR-018),
/// dan pemilik diminta menyesuaikan dompet tujuannya (keputusan pemilik,
/// 26 Sep 2026) — hasilnya [BudgetFromTemplateNeedsTarget], bukan anggaran
/// yang diam-diam membuang atau mengubah pos.
final class CreateBudgetFromTemplate {
  /// Membuat [CreateBudgetFromTemplate].
  const CreateBudgetFromTemplate();

  /// Membuat anggaran ber-`id` [id] dari [template] untuk [walletId].
  ///
  /// [name] bawaannya nama template. [targetWalletIds] memetakan id pos
  /// template ke dompet tujuan pengganti yang dipilih pemilik untuk pos
  /// transfer yang bentrok.
  BudgetFromTemplateResult call(
    BudgetTemplate template, {
    required String id,
    required String walletId,
    required BudgetPeriod period,
    required DateTime startDate,
    required String Function() newItemId,
    String? name,
    Map<String, String> targetWalletIds = const {},
  }) {
    String? targetOf(BudgetItem item) => targetWalletIds[item.id] ?? item.targetWalletId;

    final conflicts = [
      for (final item in template.items)
        if (item.isTransfer && targetOf(item) == walletId) item,
    ];
    if (conflicts.isNotEmpty) return BudgetFromTemplateNeedsTarget(conflicts);

    return BudgetFromTemplateReady(
      Budget(
        id: id,
        name: name ?? template.name,
        walletId: walletId,
        period: period,
        startDate: startDate,
        items: [
          for (final item in template.items)
            BudgetItem(
              id: newItemId(),
              name: item.name,
              enteredAmount: item.enteredAmount,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              kind: item.kind,
              targetWalletId: item.isTransfer ? targetOf(item) : null,
            ),
        ],
      ),
    );
  }
}

/// Hasil [CreateBudgetFromTemplate].
sealed class BudgetFromTemplateResult {
  const BudgetFromTemplateResult();
}

/// Anggaran siap disimpan.
final class BudgetFromTemplateReady extends BudgetFromTemplateResult {
  /// Membuat [BudgetFromTemplateReady].
  const BudgetFromTemplateReady(this.budget);

  /// Anggaran baru, lepas dari templatenya.
  final Budget budget;
}

/// Pos transfer yang dompet tujuannya sama dengan dompet anggaran. Pemilik
/// harus memilih dompet tujuan lain untuk tiap pos ini, lalu memanggil ulang
/// dengan `targetWalletIds`.
final class BudgetFromTemplateNeedsTarget extends BudgetFromTemplateResult {
  /// Membuat [BudgetFromTemplateNeedsTarget].
  const BudgetFromTemplateNeedsTarget(this.items);

  /// Pos template yang bentrok, dengan id pos template aslinya.
  final List<BudgetItem> items;
}
