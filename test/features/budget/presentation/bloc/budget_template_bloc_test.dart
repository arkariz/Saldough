import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/budget/data/repositories/budget_template_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_template_bloc.dart';
import 'package:saldough/shared/wallet/wallet.dart';

T _right<T>(Either<Failure, T> result) => result.getOrElse((_) => throw StateError('expected Right'));

/// `BudgetTemplateBloc` (T-7.2, FR-BUD-005) dengan penyimpanan di memori:
/// tambah, sunting (termasuk nonaktif), gandakan, hapus — dan tidak ada satu
/// pun yang mengubah saldo dompet (aturan 5).
void main() {
  late BudgetTemplateRepositoryImpl templates;
  late WalletRepositoryImpl wallets;
  late BudgetTemplateBloc bloc;

  const bca = Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000);
  const items = [
    BudgetItem(id: 'beras', name: 'Beras', quantity: 2, unitPrice: 7500000),
    BudgetItem(
      id: 'tabung',
      name: 'Ke tabungan',
      enteredAmount: 50000000,
      kind: BudgetItemKind.transfer,
      targetWalletId: 'jago',
    ),
  ];

  setUp(() async {
    final storage = InMemoryKeyValueStorage();
    templates = BudgetTemplateRepositoryImpl(storage: storage);
    wallets = WalletRepositoryImpl(storage: storage);
    await wallets.saveWallet(bca);
    bloc = BudgetTemplateBloc(templateRepository: templates, walletRepository: wallets);
  });

  tearDown(() => bloc.close());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('tambah, nonaktifkan, gandakan, lalu hapus template — saldo dompet tidak pernah berubah', () async {
    bloc.add(const BudgetTemplatesStarted());
    await settle();
    expect(bloc.state.wallets, [bca]);

    bloc.add(const BudgetTemplateAdded(name: '  Belanja bulanan ', items: items));
    await settle();
    final added = _right(await templates.listTemplates()).single;
    expect(added.name, 'Belanja bulanan');
    expect(added.plannedAmount, 65000000);
    expect(added.isEnabled, isTrue);

    bloc.add(BudgetTemplateEdited(added.copyWith(isEnabled: false)));
    await settle();
    expect(_right(await templates.listTemplates()).single.isEnabled, isFalse);

    bloc.add(BudgetTemplateDuplicated(added.copyWith(isEnabled: false)));
    await settle();
    final both = _right(await templates.listTemplates());
    expect(both, hasLength(2));
    final copy = both.firstWhere((t) => t.id != added.id);
    expect(copy.name, contains('Belanja bulanan'));
    expect(copy.name, isNot('Belanja bulanan'));
    expect(copy.plannedAmount, added.plannedAmount);
    expect(copy.isEnabled, isFalse);
    // Salinan mandiri: id pos baru, tujuan transfer tetap.
    expect(copy.items.map((i) => i.id).toSet().intersection(items.map((i) => i.id).toSet()), isEmpty);
    expect(copy.items.last.targetWalletId, 'jago');
    expect(bloc.state.templates, hasLength(2));

    bloc.add(BudgetTemplateDeleted(added));
    await settle();
    expect(_right(await templates.listTemplates()).map((t) => t.id), [copy.id]);

    expect(_right(await wallets.listWallets()), [bca]);
  });
}
