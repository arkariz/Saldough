import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/budget/data/models/budget_model.dart';

void main() {
  group('BudgetModel (ADR-017)', () {
    test('dokumen skema 1 yang masih membawa plannedAmount tetap terbaca; rencana = jumlah pos', () {
      final model = BudgetModel.fromJson({
        'id': 'b1',
        'name': 'Rumah tangga',
        'walletId': 'bca',
        'period': 'monthly',
        'startDate': '2026-09-01T00:00:00.000',
        'plannedAmount': 306850000,
        'items': [
          {'id': 'beras', 'name': 'Beras', 'enteredAmount': null, 'quantity': 2, 'unitPrice': 7500000},
        ],
        'isArchived': false,
      });

      expect(model.toEntity().plannedAmount, 15000000);
    });

    test('toJson tidak lagi menulis plannedAmount tingkat anggaran', () {
      final json = BudgetModel.fromJson({
        'id': 'b1',
        'name': 'x',
        'walletId': 'bca',
        'period': 'weekly',
        'startDate': '2026-09-01T00:00:00.000',
        'items': <Object>[],
        'isArchived': false,
      }).toJson();

      expect(json.containsKey('plannedAmount'), isFalse);
    });
  });
}
