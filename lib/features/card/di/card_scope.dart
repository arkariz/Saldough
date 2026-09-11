import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:saldough/features/card/data/repositories/card_statement_repository_impl.dart';
import 'package:saldough/features/card/data/repositories/credit_card_repository_impl.dart';
import 'package:saldough/features/card/data/repositories/recurring_subscription_repository_impl.dart';
import 'package:saldough/features/card/domain/repositories/card_statement_repository.dart';
import 'package:saldough/features/card/domain/repositories/credit_card_repository.dart';
import 'package:saldough/features/card/domain/repositories/recurring_subscription_repository.dart';
import 'package:saldough/features/card/domain/usecases/close_card_statement.dart';
import 'package:saldough/features/card/presentation/bloc/card_bloc.dart';

/// Lingkup dependensi fitur `card`. Membawa [KeyValueStorage] dari induk
/// (root-level, ADR-0009).
final class CardScope extends IsolatedScope {
  /// Membuat [CardScope] dengan kontainer induk [parentContainer].
  CardScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c.registerSingleton<KeyValueStorage>(parent<KeyValueStorage>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<CreditCardRepository>(
      () => CreditCardRepositoryImpl(storage: c<KeyValueStorage>()),
    );
    c.registerLazySingleton<CardStatementRepository>(
      () => CardStatementRepositoryImpl(storage: c<KeyValueStorage>()),
    );
    c.registerLazySingleton<RecurringSubscriptionRepository>(
      () => RecurringSubscriptionRepositoryImpl(storage: c<KeyValueStorage>()),
    );
    c.registerLazySingleton<CloseCardStatement>(
      () => CloseCardStatement(
        statementRepository: c<CardStatementRepository>(),
        subscriptionRepository: c<RecurringSubscriptionRepository>(),
      ),
    );
    c.registerLazySingleton<CardBloc>(
      () => CardBloc(
        cardRepository: c<CreditCardRepository>(),
        statementRepository: c<CardStatementRepository>(),
        subscriptionRepository: c<RecurringSubscriptionRepository>(),
        closeCardStatement: c<CloseCardStatement>(),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
