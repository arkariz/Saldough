import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../helpers/fake_entitlements.dart';

class _MockInterpreter extends Mock implements TransactionInterpreter {}

/// Jatah tafsir cerdas (ADR-041 §3.7, KT-P14): habis = aturan saja, tidak ada
/// yang gagal; hanya tafsir yang berhasil menghabiskan jatah.
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

  final evidence = CaptureEvidence(
    source: CaptureSource.voice,
    text: 'kopi 35 ribu tadi, roti 15 ribu itu salah',
    capturedAt: DateTime(2026, 9, 30, 12),
    languageCode: 'id',
  );
  final context = InterpretationContext(
    walletNames: const ['BCA'],
    expenseCategoryNames: const ['Makan'],
    incomeCategoryNames: const [],
    today: DateTime(2026, 9, 30),
    currencyCode: 'IDR',
  );

  late _MockInterpreter inner;
  late FakeEntitlements entitlements;
  late QuotaGatedInterpreter gated;

  setUp(() {
    inner = _MockInterpreter();
    when(() => inner.interpret(any(), any())).thenAnswer(
      (_) async => right(const InterpretedTransaction(kind: DraftKind.expense, amountText: '35 ribu')),
    );
    entitlements = FakeEntitlements(limits: EntitlementLimits.fromValues(const {'free_smart_interpretations': '2'}));
    gated = QuotaGatedInterpreter(inner: inner, entitlements: entitlements);
  });

  test('di bawah jatah: diteruskan dan menghabiskan satu jatah', () async {
    expect((await gated.interpret(evidence, context)).isRight(), isTrue);
    expect(entitlements.used[PlusFeature.smartInterpretation], 1);
    verify(() => inner.interpret(any(), any())).called(1);
  });

  test('jatah habis: Left dengan kode khusus dan penafsir cloud tidak dipanggil', () async {
    await gated.interpret(evidence, context);
    await gated.interpret(evidence, context);
    final result = await gated.interpret(evidence, context);
    expect(result.fold((f) => f.code, (_) => null), quotaExhaustedCode);
    verify(() => inner.interpret(any(), any())).called(2);
  });

  test('hasil galat mengembalikan jatah', () async {
    when(() => inner.interpret(any(), any())).thenAnswer(
      (_) async => left(const SystemFailure(code: FailureCode.unknown, message: 'cloud: gagal')),
    );
    expect((await gated.interpret(evidence, context)).isLeft(), isTrue);
    expect(entitlements.used[PlusFeature.smartInterpretation], 0);
  });

  test('melempar mengembalikan jatah dan meneruskan galatnya', () async {
    when(() => inner.interpret(any(), any())).thenThrow(StateError('SDK'));
    await expectLater(gated.interpret(evidence, context), throwsStateError);
    expect(entitlements.used[PlusFeature.smartInterpretation], 0);
  });

  test('Plus: batas wajar, bukan jatah Gratis', () async {
    entitlements = FakeEntitlements.plus();
    gated = QuotaGatedInterpreter(inner: inner, entitlements: entitlements);
    for (var i = 0; i < 5; i++) {
      expect((await gated.interpret(evidence, context)).isRight(), isTrue);
    }
    verify(() => inner.interpret(any(), any())).called(5);
  });

  test('penyusun draf: jatah habis jatuh ke hasil aturan, tidak gagal, dan cloud tidak dipanggil', () async {
    entitlements = FakeEntitlements(limits: EntitlementLimits.fromValues(const {'free_smart_interpretations': '0'}));
    const food = Category(id: 'food', kind: CategoryKind.expense, name: 'Makan', builtInKey: 'food');
    const wallets = [Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0)];
    final composer = CaptureDraftComposer(
      ruleInterpreterFor: (language) => RuleBasedTransactionInterpreter(language: language, categories: () => const [food]),
      cloudInterpreter: QuotaGatedInterpreter(inner: inner, entitlements: entitlements),
    );
    final draft = await composer.compose(evidence, wallets: wallets, categories: const [food], currencyCode: 'IDR');
    expect(draft, isNotNull);
    verifyNever(() => inner.interpret(any(), any()));
  });
}
