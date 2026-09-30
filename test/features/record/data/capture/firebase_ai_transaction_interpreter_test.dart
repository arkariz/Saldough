import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/data/capture/firebase_ai_transaction_interpreter.dart';
import 'package:saldough/features/record/domain/capture/capture_draft_resolver.dart';
import 'package:saldough/features/record/domain/capture/capture_evidence.dart';
import 'package:saldough/features/record/domain/capture/interpreted_transaction.dart';
import 'package:saldough/features/record/domain/capture/language/capture_language.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
import 'package:saldough/features/record/domain/capture/transaction_interpreter.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Interpreter Firebase AI (T-11.7) dengan model palsu.
void main() {
  final now = DateTime(2026, 9, 30, 12);
  final evidence = CaptureEvidence(
    source: CaptureSource.voice,
    text: 'kemarin makan siang 35 ribu pakai BCA',
    capturedAt: now,
    languageCode: 'id',
  );
  final context = InterpretationContext(
    walletNames: const ['BCA', 'GoPay'],
    expenseCategoryNames: const ['Makan & Minum'],
    incomeCategoryNames: const ['Gaji'],
    today: now,
    currencyCode: 'IDR',
  );

  Future<InterpretedTransaction?> interpret(String? json) async {
    final result = await FirebaseAiTransactionInterpreter(model: (_) async => json).interpret(evidence, context);
    return result.fold((_) => null, (value) => value);
  }

  test('prompt hanya berisi teks, nama, tanggal, dan bahasa', () {
    final prompt = extractionPrompt(evidence, context);
    expect(prompt, contains('TODAY: 2026-09-30'));
    expect(prompt, contains('LANGUAGE: id'));
    expect(prompt, contains('WALLETS: BCA, GoPay'));
    expect(prompt, contains('EXPENSE CATEGORIES: Makan & Minum'));
    expect(prompt, contains('UTTERANCE: "kemarin makan siang 35 ribu pakai BCA"'));
  });

  test('JSON model menjadi kutipan, termasuk tanggal', () async {
    final value = await interpret(
      '{"kind":"expense","amount_text":"35 ribu","wallet_text":"BCA","to_wallet_text":null, '
      '"category":"Makan & Minum","note":"makan siang","date_text":"kemarin","date":"2026-09-29"}',
    );
    expect(
      value,
      InterpretedTransaction(
        kind: DraftKind.expense,
        amountText: '35 ribu',
        walletText: 'BCA',
        categoryName: 'Makan & Minum',
        note: 'makan siang',
        dateText: 'kemarin',
        date: DateTime(2026, 9, 29, 12),
      ),
    );
  });

  test('tanggal yang tidak ada di kalender dibuang; transfer tanpa kategori', () async {
    final value = await interpret(
      '{"kind":"transfer","amount_text":"35 ribu","wallet_text":"BCA","to_wallet_text":"GoPay", '
      '"category":"Makan & Minum","note":"","date_text":"kemarin","date":"2026-02-31"}',
    );
    expect(value!.date, isNull);
    expect(value.categoryName, isNull);
    expect(value.toWalletText, 'GoPay');
  });

  test('JSON rusak, kosong, atau galat jaringan menjadi Left', () async {
    expect(await interpret('bukan json'), isNull);
    expect(await interpret(null), isNull);
    final failing = FirebaseAiTransactionInterpreter(model: (_) async => throw Exception('offline'));
    expect((await failing.interpret(evidence, context)).isLeft(), isTrue);
  });

  test('karangan model tetap ditolak resolver', () async {
    const wallets = [Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0)];
    final value = await interpret(
      '{"kind":"expense","amount_text":"350 ribu","wallet_text":"Mandiri","to_wallet_text":null, '
      '"category":"Kuliner","note":"makan","date_text":"besok","date":"2026-10-01"}',
    );
    final draft = CaptureDraftResolver(
      wallets: wallets,
      categories: const [],
      language: CaptureLanguages.of('id'),
    ).resolve(evidence, value!);
    expect(draft.amountSen, isNull);
    expect(draft.walletId, isNull);
    expect(draft.categoryId, isNull);
    expect(draft.date, isNull);
    expect(draft.issues, {
      DraftIssue.amountMissing,
      DraftIssue.walletUnknown,
      DraftIssue.categoryUnknown,
      DraftIssue.dateUnclear,
    });
  });
}
