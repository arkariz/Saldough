import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/notification_capture/domain/services/budget_item_suggestion.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/capture/capture.dart';

/// Saran pos anggaran untuk pengeluaran bebas (ADR-044 §3.2, E2/B-86).
void main() {
  final date = DateTime(2026, 11, 10);

  BudgetItemOption option(
    String id,
    String name, {
    String wallet = 'bca',
    String? transferTo,
    bool archived = false,
    DateTime? start,
    DateTime? end,
  }) => BudgetItemOption(
    budgetId: 'b1',
    budgetName: 'November',
    itemId: id,
    itemName: name,
    walletId: wallet,
    startDate: start ?? DateTime(2026, 11),
    endDate: end ?? DateTime(2026, 12),
    isArchived: archived,
    transferToWalletId: transferTo,
  );

  RecordDraft draft({DraftKind kind = DraftKind.expense, String? wallet = 'bca'}) =>
      RecordDraft(kind: kind, amountSen: 2500000, walletId: wallet, note: 'KOPI');

  BudgetItemOption? suggest(
    List<BudgetItemOption> options, {
    RecordDraft? d,
    String text = 'Bayar Makan siang Rp25.000',
  }) => suggestBudgetItem(draft: d ?? draft(), date: date, text: text, options: options);

  test('nama pos yang muncul di teks disarankan', () {
    expect(suggest([option('i1', 'Makan'), option('i2', 'Bensin')])?.itemId, 'i1');
  });

  test('lebih dari satu pos cocok: ambigu, tanpa saran', () {
    expect(suggest([option('i1', 'Makan'), option('i2', 'Siang')]), isNull);
  });

  test('pos sama di dua anggaran berbeda id: ambigu; satu pos saja tetap disarankan', () {
    expect(suggest([option('i1', 'Makan'), option('i9', 'Makan')]), isNull);
    expect(suggest([option('i1', 'Makan'), option('i1', 'Makan')])?.itemId, 'i1');
  });

  test('kata utuh saja: "Makanan" tidak cocok dengan pos "Makan"', () {
    expect(suggest([option('i1', 'Makan')], text: 'Makanan Rp25.000'), isNull);
  });

  test('syarat: pengeluaran, dompet sama, belum diarsipkan, bukan transfer, mencakup tanggal', () {
    final base = [option('i1', 'Makan')];
    expect(suggest(base, d: draft(kind: DraftKind.income)), isNull);
    expect(suggest(base, d: draft(wallet: 'bri')), isNull);
    expect(suggest(base, d: draft(wallet: null)), isNull);
    expect(suggest([option('i1', 'Makan', archived: true)]), isNull);
    expect(suggest([option('i1', 'Makan', transferTo: 'bri')]), isNull);
    expect(suggest([option('i1', 'Makan', start: DateTime(2026, 12), end: DateTime(2027))]), isNull);
  });

  test('nama pos terlalu pendek (kurang dari 3 huruf) tidak dipakai', () {
    expect(suggest([option('i1', 'Ke')], text: 'Bayar ke warung Rp25.000'), isNull);
  });
}
