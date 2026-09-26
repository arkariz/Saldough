import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_template_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late BudgetTemplateRepositoryImpl repository;

  // Daftar belanja nyata pemilik: Rp576.600 per minggu × 4 ditambah
  // Rp762.100 bulanan = Rp3.068.500 (DOMAIN_MODEL.md bagian "Pos anggaran").
  const template = BudgetTemplate(
    id: 't1',
    name: 'Belanja bulanan',
    items: [
      BudgetItem(
        id: 'mingguan',
        name: 'Belanja mingguan',
        quantity: 4,
        unitPrice: 57660000,
      ),
      BudgetItem(
        id: 'bulanan',
        name: 'Belanja bulanan',
        enteredAmount: 76210000,
      ),
      BudgetItem(
        id: 'tabungan',
        name: 'Ke tabungan',
        enteredAmount: 50000000,
        kind: BudgetItemKind.transfer,
        targetWalletId: 'jago',
      ),
    ],
  );

  T read<T>(Either<Failure, T> result) => result.getOrElse((_) => throw StateError('expected Right'));

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = BudgetTemplateRepositoryImpl(storage: storage);
  });

  group('BudgetTemplate', () {
    test('rencana template adalah jumlah posnya, dan template baru aktif', () {
      expect(template.plannedAmount, 306850000 + 50000000);
      expect(template.isEnabled, isTrue);
    });
  });

  group('BudgetTemplateRepositoryImpl', () {
    test('daftar template kosong sebelum ada yang disimpan', () async {
      expect(read(await repository.listTemplates()), isEmpty);
    });

    test(
      'menyimpan lalu membaca mengembalikan nilai yang sama, termasuk pos dirinci dan pos transfer',
      () async {
        await repository.saveTemplate(template);
        final saved = read(await repository.listTemplates()).single;
        expect(saved, template);
        expect(saved.items.first.plannedAmount, 230640000);
        expect(saved.items.last.targetWalletId, 'jago');
      },
    );

    test(
      'menyimpan ulang id sama menimpa di posisi semula, bukan menambah',
      () async {
        await repository.saveTemplate(template);
        await repository.saveTemplate(
          const BudgetTemplate(id: 't2', name: 'Mingguan'),
        );
        await repository.saveTemplate(template.copyWith(isEnabled: false));

        final templates = read(await repository.listTemplates());
        expect(templates.map((t) => t.id), ['t1', 't2']);
        expect(templates.first.isEnabled, isFalse);
      },
    );

    test(
      'menghapus hanya template yang dimaksud; id tak dikenal tidak berefek',
      () async {
        await repository.saveTemplate(template);
        await repository.saveTemplate(
          const BudgetTemplate(id: 't2', name: 'Mingguan'),
        );
        await repository.deleteTemplate('tidak-ada');
        await repository.deleteTemplate('t1');

        expect(read(await repository.listTemplates()).map((t) => t.id), ['t2']);
      },
    );

    test(
      'template dan anggaran tersimpan di kunci terpisah, tidak saling menimpa',
      () async {
        final budgets = BudgetRepositoryImpl(storage: storage);
        final budget = Budget(
          id: 'b1',
          name: 'Belanja',
          walletId: 'bca',
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 9),
          items: template.items,
        );
        await budgets.saveBudget(budget);
        await repository.saveTemplate(template);
        await repository.saveTemplate(
          template.copyWith(name: 'Belanja (disunting)', items: const []),
        );

        expect(read(await budgets.listBudgets()).single, budget);
        expect(
          read(await repository.listTemplates()).single.name,
          'Belanja (disunting)',
        );
      },
    );
  });
}
