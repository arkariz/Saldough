import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/card/domain/entities/card_statement.dart';
import 'package:saldough/features/card/domain/entities/card_statement_period.dart';
import 'package:saldough/features/card/domain/entities/card_transaction.dart';
import 'package:saldough/features/card/domain/repositories/card_statement_repository.dart';
import 'package:saldough/features/card/domain/repositories/recurring_subscription_repository.dart';

/// Menutup siklus tagihan kartu [cardId] yang sedang terbuka, dan membuka
/// siklus berikutnya — langsung disiapkan transaksi langganan aktifnya
/// sebagai belum terkonfirmasi (FR-CARD-003, FR-CARD-004).
final class CloseCardStatement {
  /// Membuat [CloseCardStatement].
  CloseCardStatement({required this._statementRepository, required this._subscriptionRepository});

  final CardStatementRepository _statementRepository;
  final RecurringSubscriptionRepository _subscriptionRepository;

  /// Menutup siklus terbuka kartu [cardId] (tanggal cetak
  /// [statementDayOfMonth]) dan mengembalikan siklus berikutnya yang baru
  /// dibuka.
  ///
  /// `Left(BusinessRuleFailure)` kalau kartu ini tidak sedang punya siklus
  /// terbuka.
  Future<Either<Failure, CardStatement>> call({
    required String cardId,
    required int statementDayOfMonth,
  }) async {
    final openResult = await _statementRepository.getOpenStatement(cardId);
    if (openResult case Left(value: final failure)) return left(failure);
    if (openResult case Right(value: null)) {
      return left(BusinessRuleFailure(
        code: const FailureCode('NO_OPEN_STATEMENT'),
        message: 'Kartu $cardId tidak punya siklus tagihan terbuka.',
        userMessage: 'Belum ada siklus tagihan yang bisa ditutup.',
      ));
    }
    final open = switch (openResult) { Right(value: final s?) => s, _ => throw StateError('unreachable') };

    final closeResult = await _statementRepository.saveStatement(open.close());
    if (closeResult case Left(value: final failure)) return left(failure);

    final subsResult = await _subscriptionRepository.listSubscriptions();
    if (subsResult case Left(value: final failure)) return left(failure);
    final subs = switch (subsResult) { Right(value: final s) => s, _ => throw StateError('unreachable') };
    final activeSubs = subs.where((s) => s.cardId == cardId && s.isActive);

    final nextPeriod = CardStatementPeriod(start: open.periodStart, end: open.periodEnd).next(statementDayOfMonth);
    var counter = 0;
    final pendingTransactions = [
      for (final sub in activeSubs)
        CardTransaction(
          id: '${nextPeriod.start.millisecondsSinceEpoch}-${counter++}',
          // Tanggal langganan disiapkan di bulan akhir periode (dekat tanggal
          // cetak) — pendekatan yang wajar untuk pembayaran otomatis
          // bulanan, tidak literal dari DOMAIN_MODEL.md.
          date: DateTime(nextPeriod.end.year, nextPeriod.end.month, sub.dayOfMonth),
          merchant: sub.merchant,
          amount: sub.amount,
          isConfirmed: false,
        ),
    ];

    final nextStatement = CardStatement(
      id: '${cardId}_${nextPeriod.start.toIso8601String()}',
      cardId: cardId,
      periodStart: nextPeriod.start,
      periodEnd: nextPeriod.end,
      transactions: pendingTransactions,
    );
    final saveNextResult = await _statementRepository.saveStatement(nextStatement);
    return switch (saveNextResult) {
      Left(value: final failure) => left(failure),
      Right() => right(nextStatement),
    };
  }
}
