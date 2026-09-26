import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/domain/usecases/create_budget_from_template.dart';

void main() {
  const create = CreateBudgetFromTemplate();

  // Rp576.600 × 4 + Rp762.100 = Rp3.068.500, ditambah Rp500.000 ke tabungan.
  const template = BudgetTemplate(
    id: 't1',
    name: 'Belanja bulanan',
    items: [
      BudgetItem(id: 'mingguan', name: 'Belanja mingguan', quantity: 4, unitPrice: 57660000),
      BudgetItem(id: 'bulanan', name: 'Belanja bulanan', enteredAmount: 76210000),
      BudgetItem(
        id: 'tabungan',
        name: 'Ke tabungan',
        enteredAmount: 50000000,
        kind: BudgetItemKind.transfer,
        targetWalletId: 'jago',
      ),
    ],
  );

  late int counter;
  String newItemId() => 'pos-${counter++}';

  setUp(() => counter = 0);

  BudgetFromTemplateResult run({
    String walletId = 'bca',
    Map<String, String> targetWalletIds = const {},
    String? name,
  }) => create(
    template,
    id: 'b1',
    walletId: walletId,
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 10),
    newItemId: newItemId,
    name: name,
    targetWalletIds: targetWalletIds,
  );

  test('menyalin nama, pos, dan rencana template ke anggaran untuk dompet yang dipilih', () {
    final budget = (run() as BudgetFromTemplateReady).budget;

    expect(budget.id, 'b1');
    expect(budget.name, 'Belanja bulanan');
    expect(budget.walletId, 'bca');
    expect(budget.period, BudgetPeriod.monthly);
    expect(budget.startDate, DateTime(2026, 10));
    expect(budget.isArchived, isFalse);
    expect(budget.plannedAmount, 356850000);
    expect(budget.plannedAmount, template.plannedAmount);
    expect(budget.items.map((i) => i.name), ['Belanja mingguan', 'Belanja bulanan', 'Ke tabungan']);
    expect(budget.items.first.quantity, 4);
    expect(budget.items.first.unitPrice, 57660000);
    expect(budget.items.last.kind, BudgetItemKind.transfer);
    expect(budget.items.last.targetWalletId, 'jago');
  });

  test('setiap pos mendapat id baru, tidak memakai ulang id pos template', () {
    final first = (run() as BudgetFromTemplateReady).budget;
    final second = (run() as BudgetFromTemplateReady).budget;

    final ids = [...first.items, ...second.items].map((i) => i.id).toList();
    expect(ids, ['pos-0', 'pos-1', 'pos-2', 'pos-3', 'pos-4', 'pos-5']);
    expect(ids.toSet().intersection(template.items.map((i) => i.id).toSet()), isEmpty);
  });

  test('nama anggaran boleh diganti tanpa mengubah templatenya', () {
    final budget = (run(name: 'Belanja Oktober') as BudgetFromTemplateReady).budget;
    expect(budget.name, 'Belanja Oktober');
    expect(template.name, 'Belanja bulanan');
  });

  test('dompet anggaran sama dengan dompet tujuan pos transfer: pemilik diminta menyesuaikan', () {
    final result = run(walletId: 'jago');

    expect(result, isA<BudgetFromTemplateNeedsTarget>());
    expect((result as BudgetFromTemplateNeedsTarget).items.map((i) => i.id), ['tabungan']);
    expect(counter, 0, reason: 'tidak ada anggaran yang dibuat setengah jadi');
  });

  test('dompet tujuan pengganti dari pemilik dipakai untuk pos transfer yang bentrok', () {
    final budget = (run(walletId: 'jago', targetWalletIds: {'tabungan': 'bca'}) as BudgetFromTemplateReady).budget;

    expect(budget.walletId, 'jago');
    expect(budget.items.last.targetWalletId, 'bca');
    expect(template.items.last.targetWalletId, 'jago', reason: 'template tidak ikut berubah');
  });

  test('dompet tujuan pengganti yang masih sama dengan dompet anggaran tetap ditolak', () {
    expect(run(walletId: 'jago', targetWalletIds: {'tabungan': 'jago'}), isA<BudgetFromTemplateNeedsTarget>());
  });
}
