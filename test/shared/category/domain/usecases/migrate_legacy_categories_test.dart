import 'dart:convert';

import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Migrasi label kategori teks bebas ke `categoryId` (ADR-026 §3.4).
void main() {
  late InMemoryKeyValueStorage storage;
  late CategoryRepositoryImpl categories;
  late TransactionRepositoryImpl transactions;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    categories = CategoryRepositoryImpl(storage: storage);
    transactions = TransactionRepositoryImpl(storage: storage);
    addTearDown(() => ActiveCategories.notifier.value = const []);
  });

  /// Menulis dokumen bulan skema 1 (dengan `categoryKey`) apa adanya.
  Future<void> seedLegacyMonth(String month, List<Map<String, dynamic>> items) async {
    await storage.write(
      StorageKey(namespace: 'transaction', name: month).value,
      jsonEncode({'schemaVersion': 1, 'items': items}),
    );
    await storage.write(
      const StorageKey(namespace: 'transaction', name: '_index').value,
      jsonEncode({
        'months': [month],
      }),
    );
  }

  Map<String, dynamic> legacy(String id, String type, String? label) => {
    'id': id,
    'type': type,
    'date': '2026-09-10T08:00:00.000',
    'amount': 100000,
    'note': '',
    'categoryKey': label,
    'walletId': type == 'transfer' ? null : 'bca',
    'budgetItemId': null,
    'fromWalletId': type == 'transfer' ? 'bca' : null,
    'toWalletId': type == 'transfer' ? 'gopay' : null,
  };

  MigrateLegacyCategories migrate() =>
      MigrateLegacyCategories(categoryRepository: categories, legacyLabels: transactions);

  Future<Either<Object, Unit>> run() => migrate()(builtInName: (key) => 'nama:$key');

  Future<Map<String, String?>> categoryIdsById() async {
    final all = (await transactions.listAllTransactions()).getOrElse((_) => const []);
    return {for (final t in all) t.id: t.categoryId};
  }

  test('pemasangan baru: seluruh kategori bawaan dibuat dengan nama i18n dan penanda ditulis', () async {
    expect(await run(), const Right<Object, Unit>(unit));

    final stored = (await categories.listCategories()).getOrElse((_) => const []);
    expect(stored.map((c) => c.id), BuiltInCategories.all.map((b) => b.id));
    expect(stored.firstWhere((c) => c.id == 'builtin.food').name, 'nama:food');
    expect((await categories.isLegacyMigrationDone()).getOrElse((_) => false), isTrue);
    expect(ActiveCategories.notifier.value, hasLength(BuiltInCategories.all.length));
  });

  test('label lama: cocok nama/alias bawaan dipakai ulang, sisanya jadi kategori legacy, transfer dibuang', () async {
    await seedLegacyMonth('2026-09', [
      legacy('e1', 'expense', 'Makan Siang'), // alias "makan siang" -> food
      legacy('e2', 'expense', 'nama:transport'), // sama dengan nama bawaan
      legacy('e3', 'expense', 'Arisan'),
      legacy('e4', 'expense', '  arisan '), // ejaan lain, kategori yang sama
      legacy('i1', 'income', 'Gaji'),
      legacy('i2', 'income', 'Makan Siang'), // jenis lain: tidak ikut kategori pengeluaran
      legacy('t1', 'transfer', 'Tabungan'),
      legacy('e5', 'expense', null),
    ]);

    await run();

    expect(await categoryIdsById(), {
      'e1': 'builtin.food',
      'e2': 'builtin.transport',
      'e3': 'legacy.expense.arisan',
      'e4': 'legacy.expense.arisan',
      'i1': 'builtin.salary',
      'i2': 'legacy.income.makan siang',
      't1': null,
      'e5': null,
    });
    final stored = (await categories.listCategories()).getOrElse((_) => const []);
    final arisan = stored.firstWhere((c) => c.id == 'legacy.expense.arisan');
    expect(arisan.name, 'Arisan');
    expect(arisan.kind, CategoryKind.expense);
    expect(stored.where((c) => c.name.toLowerCase() == 'tabungan'), isEmpty);

    final raw = await storage.read(const StorageKey(namespace: 'transaction', name: '2026-09').value);
    expect(raw, isNot(contains('categoryKey')));
    expect(raw, contains('"schemaVersion":2'));
  });

  test('aman diulang: penanda sudah ada berarti tidak ada yang disentuh', () async {
    await run();
    await categories.saveCategory(
      (await categories.listCategories()).getOrElse((_) => const []).first.copyWith(name: 'Diganti pengguna'),
    );

    await run();

    final stored = (await categories.listCategories()).getOrElse((_) => const []);
    expect(stored.first.name, 'Diganti pengguna');
    expect(stored, hasLength(BuiltInCategories.all.length));
  });

  test('terhenti sebelum penanda: diulang menghasilkan id yang sama tanpa kategori ganda', () async {
    await seedLegacyMonth('2026-09', [legacy('e1', 'expense', 'Arisan')]);
    // Simulasi pembukaan pertama yang berhenti sesudah kategori ditulis.
    await categories.saveCategory(
      const Category(id: 'legacy.expense.arisan', kind: CategoryKind.expense, name: 'Arisan', sortOrder: 99),
    );

    await run();

    final stored = (await categories.listCategories()).getOrElse((_) => const []);
    expect(stored.where((c) => c.name == 'Arisan'), hasLength(1));
    expect((await categoryIdsById())['e1'], 'legacy.expense.arisan');
  });

  test('menyunting transaksi skema 1 sebelum migrasi tidak menghapus labelnya', () async {
    await seedLegacyMonth('2026-09', [legacy('e1', 'expense', 'Arisan')]);
    final original = (await transactions.listAllTransactions()).getOrElse((_) => const []).single as ExpenseTransaction;

    await transactions.saveTransaction(original.copyWith(note: 'disunting'));
    await run();

    expect((await categoryIdsById())['e1'], 'legacy.expense.arisan');
  });
}
