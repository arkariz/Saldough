import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/budget/data/models/budget_model.dart';
import 'package:saldough/features/budget/data/models/budget_template_model.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_schedule.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';

/// Template berjadwal (ADR-036 §3.1, T-16.1).
void main() {
  group('BudgetSchedule', () {
    final monthly = BudgetSchedule(walletId: 'bca', period: BudgetPeriod.monthly, anchorDate: DateTime(2026, 9, 25));

    test('bulanan: periode ke-n dan periode yang mencakup suatu tanggal', () {
      expect(monthly.startOf(0), DateTime(2026, 9, 25));
      expect(monthly.startOf(4), DateTime(2027, 1, 25));
      expect(monthly.startAt(DateTime(2026, 10, 24, 23)), DateTime(2026, 9, 25));
      expect(monthly.startAt(DateTime(2026, 10, 25)), DateTime(2026, 10, 25));
      expect(monthly.startAt(DateTime(2027, 2, 3)), DateTime(2027, 1, 25));
      expect(monthly.startAt(DateTime(2026, 9, 24)), isNull);
    });

    test('bulanan: akhir periode tepat di awal periode berikutnya, Februari juga', () {
      final s = BudgetSchedule(walletId: 'bca', period: BudgetPeriod.monthly, anchorDate: DateTime(2026, 12, 28));
      for (var n = 0; n < 14; n++) {
        expect(BudgetPeriod.monthly.endFrom(s.startOf(n)), s.startOf(n + 1));
      }
    });

    test('mingguan: tiap tujuh hari', () {
      final weekly = BudgetSchedule(walletId: 'bca', period: BudgetPeriod.weekly, anchorDate: DateTime(2026, 10, 5));
      expect(weekly.startAt(DateTime(2026, 10, 11)), DateTime(2026, 10, 5));
      expect(weekly.startAt(DateTime(2026, 10, 12)), DateTime(2026, 10, 12));
      expect(weekly.startAt(DateTime(2027)), DateTime(2026, 12, 28));
    });

    test('periode yang beririsan dengan sebuah rentang', () {
      expect(monthly.startsBetween(DateTime(2026, 11), DateTime(2026, 12)), [
        DateTime(2026, 10, 25),
        DateTime(2026, 11, 25),
      ]);
    });

    test('bulanan hanya boleh tanggal 1–28', () {
      expect(BudgetSchedule.canRepeat(BudgetPeriod.monthly, DateTime(2026, 10, 28)), isTrue);
      expect(BudgetSchedule.canRepeat(BudgetPeriod.monthly, DateTime(2026, 10, 29)), isFalse);
      expect(BudgetSchedule.canRepeat(BudgetPeriod.weekly, DateTime(2026, 10, 31)), isTrue);
    });
  });

  group('model skema baru (ADR-036)', () {
    const item = BudgetItem(id: 'kos-okt', name: 'Kos', enteredAmount: 190000000, templateItemId: 'kos');

    test('anggaran dan pos membawa templateId dan templateItemId', () {
      final budget = Budget(
        id: 'b1',
        name: 'Bulanan',
        walletId: 'bca',
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 10),
        items: const [item],
        templateId: 't1',
      );
      expect(BudgetModel.fromJson(BudgetModel.fromEntity(budget).toJson()).toEntity(), budget);
    });

    test('template berjadwal tersimpan dan terbaca utuh', () {
      final template = BudgetTemplate(
        id: 't1',
        name: 'Bulanan',
        items: const [BudgetItem(id: 'kos', name: 'Kos', enteredAmount: 190000000, templateItemId: 'kos')],
        schedule: BudgetSchedule(walletId: 'bca', period: BudgetPeriod.monthly, anchorDate: DateTime(2026, 10)),
      );
      expect(BudgetTemplateModel.fromJson(BudgetTemplateModel.fromEntity(template).toJson()).toEntity(), template);
    });

    test('dokumen lama tanpa kunci baru terbaca sebagai tidak rutin', () {
      final template = BudgetTemplateModel.fromJson({
        'id': 't1',
        'name': 'Bulanan',
        'items': <Object>[],
        'isEnabled': true,
      }).toEntity();
      expect(template.schedule, isNull);
      expect(template.isScheduled, isFalse);
      final budget = BudgetModel.fromJson({
        'id': 'b1',
        'name': 'x',
        'walletId': 'bca',
        'period': 'monthly',
        'startDate': '2026-09-01T00:00:00.000',
        'items': [
          {'id': 'a', 'name': 'A', 'enteredAmount': 1},
        ],
        'isArchived': false,
      }).toEntity();
      expect(budget.templateId, isNull);
      expect(budget.items.single.templateItemId, isNull);
    });
  });
}
