import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_card_class.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

void main() {
  CaptureInboxEntry entry({
    DraftKind kind = DraftKind.expense,
    int? amount = 2500000,
    String? walletId = 'bri',
    String? toWalletId,
    String? categoryId = 'builtin.food',
    Set<DraftIssue> issues = const {},
    bool flagged = false,
  }) => CaptureInboxEntry(
    id: 'a',
    packageName: 'id.contoh',
    appLabel: 'Contoh',
    text: 'teks',
    capturedAt: DateTime(2026, 11, 4),
    draft: RecordDraft(
      kind: kind,
      amountSen: amount,
      walletId: walletId,
      toWalletId: toWalletId,
      categoryId: categoryId,
      issues: issues,
    ),
    possibleDuplicate: flagged,
  );

  OccurrenceMatch match({bool exact = true}) => OccurrenceMatch(
    rule: RecurringRule(
      id: 'kopi',
      kind: RecurringKind.expense,
      amount: 2500000,
      walletId: 'bri',
      note: 'Kopi',
      schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 10, 4)),
    ),
    date: DateTime(2026, 11, 4),
    exact: exact,
  );

  group('cardClassOf', () {
    test('draf lengkap dengan kategori: dikenali', () {
      expect(cardClassOf(entry()), CaptureCardClass.recognized);
    });

    test('cocok kemunculan rutin: cocok rencana', () {
      expect(cardClassOf(entry(), match: match()), CaptureCardClass.planned);
    });

    test('transfer dengan kedua dompet terpetakan: dikenali tanpa kategori', () {
      expect(
        cardClassOf(entry(kind: DraftKind.transfer, toWalletId: 'bca', categoryId: null)),
        CaptureCardClass.recognized,
      );
    });

    test('transfer tanpa dompet tujuan: perlu diisi', () {
      expect(cardClassOf(entry(kind: DraftKind.transfer, categoryId: null)), CaptureCardClass.needsInput);
    });

    test('tanpa kategori dan tanpa rencana: perlu diisi', () {
      expect(cardClassOf(entry(categoryId: null)), CaptureCardClass.needsInput);
    });

    test('nominal atau dompet kosong: perlu diisi', () {
      expect(cardClassOf(entry(amount: null)), CaptureCardClass.needsInput);
      expect(cardClassOf(entry(walletId: null)), CaptureCardClass.needsInput);
    });

    test('ada masalah pada draf (jenis belum jelas): perlu diisi walau cocok rutin', () {
      expect(cardClassOf(entry(issues: {DraftIssue.kindUnclear}), match: match()), CaptureCardClass.needsInput);
    });

    test('duplikat (ditandai atau catatan sudah ada): perlu diputuskan pengguna', () {
      expect(cardClassOf(entry(flagged: true), match: match()), CaptureCardClass.needsInput);
      final existing = ExpenseTransaction(
        id: 'm',
        date: DateTime(2026, 11, 4),
        amount: 2500000,
        note: '',
        walletId: 'bri',
      );
      expect(cardClassOf(entry(), existing: existing), CaptureCardClass.needsInput);
    });
  });

  group('oneTapAllowed (garis Gratis/Plus, ADR-044 §3.8)', () {
    test('perlu diisi: tidak pernah', () {
      expect(
        oneTapAllowed(cardClass: CaptureCardClass.needsInput, match: null, isPlus: true),
        isFalse,
      );
    });

    test('rutin tetap yang persis: Gratis juga (aksi yang sama gratis di segmen Rutin, ADR-041 §3.8)', () {
      expect(oneTapAllowed(cardClass: CaptureCardClass.planned, match: match(), isPlus: false), isTrue);
    });

    test('rutin kira-kira: Plus saja', () {
      expect(oneTapAllowed(cardClass: CaptureCardClass.planned, match: match(exact: false), isPlus: false), isFalse);
      expect(oneTapAllowed(cardClass: CaptureCardClass.planned, match: match(exact: false), isPlus: true), isTrue);
    });

    test('dikenali: Plus saja', () {
      expect(oneTapAllowed(cardClass: CaptureCardClass.recognized, match: null, isPlus: false), isFalse);
      expect(oneTapAllowed(cardClass: CaptureCardClass.recognized, match: null, isPlus: true), isTrue);
    });
  });
}
