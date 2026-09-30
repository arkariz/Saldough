import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/record/data/capture/rule_based_transaction_interpreter.dart';
import 'package:saldough/features/record/domain/capture/capture_draft_composer.dart';
import 'package:saldough/features/record/domain/capture/capture_evidence.dart';
import 'package:saldough/features/record/domain/capture/interpreted_transaction.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
import 'package:saldough/features/record/domain/capture/transaction_interpreter.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

class _MockInterpreter extends Mock implements TransactionInterpreter {}

/// Interpreter cloud yang menjawab dengan [answer].
_MockInterpreter _cloud(Future<Either<Failure, InterpretedTransaction>> Function() answer) {
  final cloud = _MockInterpreter();
  when(() => cloud.interpret(any(), any())).thenAnswer((_) => answer());
  return cloud;
}

int _calls(_MockInterpreter cloud) => verify(() => cloud.interpret(any(), any())).callCount;

/// Penyusun draf (ADR-029 §3.4): aturan dulu, cloud bila ragu atau bahasa
/// tanpa paket, tidak pernah gagal.
void main() {
  setUpAll(() {
    registerFallbackValue(
      CaptureEvidence(source: CaptureSource.voice, text: '', capturedAt: DateTime(2026), languageCode: 'id'),
    );
    registerFallbackValue(
      InterpretationContext(
        walletNames: const [],
        expenseCategoryNames: const [],
        incomeCategoryNames: const [],
        today: DateTime(2026),
        currencyCode: 'IDR',
      ),
    );
  });

  const wallets = [Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0)];
  const food = Category(id: 'food', kind: CategoryKind.expense, name: 'Makan', builtInKey: 'food');
  final now = DateTime(2026, 9, 30, 12);

  CaptureEvidence evidence(String text, {String languageCode = 'id'}) =>
      CaptureEvidence(source: CaptureSource.voice, text: text, capturedAt: now, languageCode: languageCode);

  var ruleCalls = 0;
  CaptureDraftComposer composer({TransactionInterpreter? cloud, Duration timeout = const Duration(seconds: 5)}) {
    ruleCalls = 0;
    return CaptureDraftComposer(
      ruleInterpreterFor: (language) {
        ruleCalls++;
        return RuleBasedTransactionInterpreter(language: language, categories: () => const [food]);
      },
      cloudInterpreter: cloud,
      cloudTimeout: timeout,
    );
  }

  Future<RecordDraft> compose(CaptureDraftComposer composer, CaptureEvidence evidence) =>
      composer.compose(evidence, wallets: wallets, categories: const [food], currencyCode: 'IDR');

  _MockInterpreter answering(InterpretedTransaction value) => _cloud(() async => right(value));

  test('draf aturan yakin: cloud tidak dipanggil', () async {
    final cloud = answering(const InterpretedTransaction(amountText: '1 ribu'));
    final draft = await compose(composer(cloud: cloud), evidence('makan 35 ribu pakai BCA'));
    expect(draft.amountSen, 3500000);
    expect(draft.walletId, 'bca');
    verifyNever(() => cloud.interpret(any(), any()));
  });

  test('draf aturan ragu: jawaban cloud dipakai, tetap lewat resolver', () async {
    final cloud = answering(const InterpretedTransaction(kind: DraftKind.expense, amountText: '35 ribu'));
    final draft = await compose(composer(cloud: cloud), evidence('kopi 35 ribu tadi, roti 15 ribu itu salah'));
    expect(_calls(cloud), 1);
    expect(draft.amountSen, 3500000);
    expect(draft.issues, isEmpty);
  });

  test('cloud galat: draf aturan apa adanya', () async {
    final cloud = _cloud(() async => left(const SystemFailure(code: FailureCode.unknown, message: 'kuota habis')));
    final draft = await compose(composer(cloud: cloud), evidence('kopi 25 ribu roti 15 ribu'));
    expect(_calls(cloud), 1);
    expect(draft.amountSen, isNull);
    expect(draft.issues, {DraftIssue.amountMultiple});
  });

  test('cloud melempar: draf aturan apa adanya', () async {
    final cloud = _cloud(() async => throw Exception('offline'));
    final draft = await compose(composer(cloud: cloud), evidence('parkir 5'));
    expect(draft.issues, {DraftIssue.amountWithoutUnit});
  });

  test('cloud melempar Error (bukan Exception): draf aturan, tidak tertahan', () async {
    final cloud = _cloud(() async => throw StateError('sdk'));
    final draft = await compose(composer(cloud: cloud), evidence('parkir 5'));
    expect(_calls(cloud), 1);
    expect(draft.issues, {DraftIssue.amountWithoutUnit});
  });

  test('cloud tidak pernah menjawab: draf aturan sesudah batas waktu', () async {
    final cloud = _cloud(() => Completer<Either<Failure, InterpretedTransaction>>().future);
    final draft = await compose(
      composer(cloud: cloud, timeout: const Duration(milliseconds: 20)),
      evidence('parkir 5'),
    );
    expect(draft.issues, {DraftIssue.amountWithoutUnit});
  });

  test('bahasa tanpa paket: aturan dilewati, langsung ke cloud', () async {
    final cloud = answering(const InterpretedTransaction(kind: DraftKind.expense, amountText: '500'));
    final c = composer(cloud: cloud);
    final draft = await compose(c, evidence('コーヒー 500 ルピア', languageCode: 'ja'));
    expect(ruleCalls, 0);
    expect(_calls(cloud), 1);
    expect(draft.amountSen, 50000);
  });

  test('bahasa tanpa paket dan tanpa cloud: draf kosong dengan transkrip', () async {
    final c = composer();
    final draft = await compose(c, evidence('コーヒー 500 ルピア', languageCode: 'ja'));
    expect(ruleCalls, 0);
    expect(draft.sourceText, 'コーヒー 500 ルピア');
    expect(draft.amountSen, isNull);
    expect(draft.issues, {DraftIssue.amountMissing});
  });

  test('kode locale lengkap memilih paket bahasanya', () async {
    final draft = await compose(composer(), evidence('lunch 35 thousand using BCA', languageCode: 'en_US'));
    expect(draft.amountSen, 3500000);
    expect(draft.walletId, 'bca');
  });
}
