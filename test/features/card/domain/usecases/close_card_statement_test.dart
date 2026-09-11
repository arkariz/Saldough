import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/card/domain/entities/card_statement.dart';
import 'package:saldough/features/card/domain/entities/recurring_subscription.dart';
import 'package:saldough/features/card/domain/repositories/card_statement_repository.dart';
import 'package:saldough/features/card/domain/repositories/recurring_subscription_repository.dart';
import 'package:saldough/features/card/domain/usecases/close_card_statement.dart';

class MockCardStatementRepository extends Mock implements CardStatementRepository {}

class MockRecurringSubscriptionRepository extends Mock implements RecurringSubscriptionRepository {}

void main() {
  late MockCardStatementRepository statementRepository;
  late MockRecurringSubscriptionRepository subscriptionRepository;

  setUpAll(() {
    registerFallbackValue(
      CardStatement(
        id: 's',
        cardId: 'c',
        periodStart: DateTime(2026),
        periodEnd: DateTime(2026),
        transactions: const [],
      ),
    );
  });

  setUp(() {
    statementRepository = MockCardStatementRepository();
    subscriptionRepository = MockRecurringSubscriptionRepository();
    when(() => statementRepository.saveStatement(any())).thenAnswer((_) async => right(unit));
  });

  CloseCardStatement buildUseCase() => CloseCardStatement(
        statementRepository: statementRepository,
        subscriptionRepository: subscriptionRepository,
      );

  group('CloseCardStatement', () {
    test(
      'menutup siklus terbuka dan membuka siklus berikutnya diisi transaksi '
      'langganan aktif kartu ini, belum terkonfirmasi (FR-CARD-003, FR-CARD-004)',
      () async {
        final open = CardStatement(
          id: 's1',
          cardId: 'cc1',
          periodStart: DateTime(2026, 8, 16),
          periodEnd: DateTime(2026, 9, 15),
          transactions: const [],
        );
        when(() => statementRepository.getOpenStatement('cc1')).thenAnswer((_) async => right(open));
        when(() => subscriptionRepository.listSubscriptions()).thenAnswer(
          (_) async => right(const [
            RecurringSubscription(id: 'sub1', cardId: 'cc1', merchant: 'Claude AI', amount: 3500000, dayOfMonth: 20),
            RecurringSubscription(
              id: 'sub2',
              cardId: 'cc1',
              merchant: 'Nonaktif',
              amount: 1000000,
              dayOfMonth: 5,
              isActive: false,
            ),
            RecurringSubscription(id: 'sub3', cardId: 'cc2', merchant: 'Kartu lain', amount: 500000, dayOfMonth: 1),
          ]),
        );

        final result = await buildUseCase().call(cardId: 'cc1', statementDayOfMonth: 15);

        expect(result.isRight(), isTrue);
        final next = result.getOrElse((_) => throw StateError('expected Right'));
        expect(next.periodStart, DateTime(2026, 9, 16));
        expect(next.periodEnd, DateTime(2026, 10, 15));
        expect(next.transactions, hasLength(1));
        expect(next.transactions.single.merchant, 'Claude AI');
        expect(next.transactions.single.isConfirmed, isFalse);

        final calls = verify(() => statementRepository.saveStatement(captureAny())).captured;
        expect(calls, hasLength(2));
        final closedSaved = calls.first as CardStatement;
        expect(closedSaved.isClosed, isTrue);
      },
    );

    test('menolak menutup kalau kartu tidak punya siklus tagihan terbuka', () async {
      when(() => statementRepository.getOpenStatement('cc1')).thenAnswer((_) async => right(null));

      final result = await buildUseCase().call(cardId: 'cc1', statementDayOfMonth: 15);

      expect(result.isLeft(), isTrue);
      verifyNever(() => statementRepository.saveStatement(any()));
    });
  });
}
