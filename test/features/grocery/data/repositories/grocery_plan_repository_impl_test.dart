import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/grocery/data/repositories/grocery_plan_repository_impl.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_item.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';

void main() {
  late GroceryPlanRepositoryImpl repository;

  setUp(() {
    repository = GroceryPlanRepositoryImpl(storage: InMemoryKeyValueStorage());
  });

  group('GroceryPlanRepositoryImpl', () {
    test('menyimpan lalu membaca plan mengembalikan nilai yang sama untuk id yang sama', () async {
      const plan = GroceryPlan(
        id: '2026-09',
        weeklyItems: [GroceryItem(id: 'w1', name: 'Beras', quantity: 1, unitPrice: 5000000)],
        monthlyItems: [],
        weeksPerMonth: 5,
      );
      final saveResult = await repository.savePlan(plan);
      expect(saveResult.isRight(), isTrue);

      final readResult = await repository.getPlan('2026-09');
      final read = readResult.getOrElse((_) => throw StateError('expected Right'));

      expect(read, plan);
    });

    test('id yang belum pernah disimpan dan tanpa bulan sebelumnya mengembalikan plan kosong', () async {
      final result = await repository.getPlan('2026-09');
      final plan = result.getOrElse((_) => throw StateError('expected Right'));

      expect(plan, GroceryPlan.empty('2026-09'));
    });

    test(
      'id yang belum pernah disimpan DISALIN dari bulan sebelumnya (keputusan pemilik: bukan kosong)',
      () async {
        const august = GroceryPlan(
          id: '2026-08',
          weeklyItems: [GroceryItem(id: 'w1', name: 'Beras', quantity: 1, unitPrice: 5000000)],
          monthlyItems: [GroceryItem(id: 'm1', name: 'Gas', quantity: 1, unitPrice: 2000000)],
          weeksPerMonth: 5,
        );
        await repository.savePlan(august);

        final result = await repository.getPlan('2026-09');
        final september = result.getOrElse((_) => throw StateError('expected Right'));

        expect(september.id, '2026-09', reason: 'id ikut bulan yang DIMINTA, bukan bulan sumber salinan');
        expect(september.weeklyItems, august.weeklyItems);
        expect(september.monthlyItems, august.monthlyItems);
        expect(september.weeksPerMonth, august.weeksPerMonth);
      },
    );

    test('salinan dari bulan sebelumnya TIDAK otomatis tersimpan (tetap lazy sampai savePlan dipanggil)', () async {
      const august = GroceryPlan(
        id: '2026-08',
        weeklyItems: [GroceryItem(id: 'w1', name: 'Beras', quantity: 1, unitPrice: 5000000)],
        monthlyItems: [],
      );
      await repository.savePlan(august);

      await repository.getPlan('2026-09'); // hanya membaca, tidak menulis

      // Ubah bulan Agustus SETELAH "melihat" September -- kalau September
      // sempat ikut tertulis saat dibaca, perubahan ini tidak akan
      // terlihat di baca ulang berikutnya.
      await repository.savePlan(august.copyWith(weeklyItems: const []));

      final result = await repository.getPlan('2026-09');
      final september = result.getOrElse((_) => throw StateError('expected Right'));

      expect(
        september.weeklyItems,
        isEmpty,
        reason: 'September belum pernah benar-benar tersimpan, jadi masih ikut Agustus TERKINI',
      );
    });

    test('Desember membaca salinan dari November tahun yang sama', () async {
      const november = GroceryPlan(id: '2025-11', weeklyItems: [], monthlyItems: []);
      await repository.savePlan(november);

      final result = await repository.getPlan('2025-12');
      expect(result.isRight(), isTrue);
    });

    test('Januari membaca salinan dari Desember TAHUN SEBELUMNYA', () async {
      const december = GroceryPlan(
        id: '2025-12',
        weeklyItems: [GroceryItem(id: 'w1', name: 'Beras', quantity: 1, unitPrice: 5000000)],
        monthlyItems: [],
      );
      await repository.savePlan(december);

      final result = await repository.getPlan('2026-01');
      final january = result.getOrElse((_) => throw StateError('expected Right'));

      expect(january.weeklyItems, december.weeklyItems);
    });
  });
}
