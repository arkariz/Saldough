import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/worklog/domain/entities/billing_book.dart';
import 'package:saldough/features/worklog/domain/repositories/cycle_income_writer.dart';
import 'package:saldough/features/worklog/domain/repositories/worklog_repository.dart';

/// Menyuntikkan gaji bersih sebuah [BillingBook] yang sudah ditutup ke baris
/// pemasukan pada siklus [cycleId] (T-3.9/FR-TIME-003).
final class InjectNetPay {
  /// Membuat [InjectNetPay].
  InjectNetPay({required this._writer, required this._repository});

  final CycleIncomeWriter _writer;
  final WorklogRepository _repository;

  /// Menyuntikkan [book] ke siklus [cycleId], berlabel [sourceLabel].
  ///
  /// `Left(BusinessRuleFailure)` kalau [book] belum ditutup, atau sudah
  /// pernah disuntikkan sebelumnya (tidak pernah menyuntik dua kali).
  Future<Either<Failure, Unit>> call({
    required BillingBook book,
    required String sourceLabel,
    required String cycleId,
  }) async {
    if (!book.isClosed) {
      return left(BusinessRuleFailure(
        code: const FailureCode('BOOK_NOT_CLOSED'),
        message: 'BillingBook ${book.id} belum ditutup.',
        userMessage: 'Tutup buku ini dulu sebelum disuntikkan.',
      ));
    }
    if (book.isInjected) {
      return left(BusinessRuleFailure(
        code: const FailureCode('BOOK_ALREADY_INJECTED'),
        message: 'BillingBook ${book.id} sudah disuntikkan ke ${book.injectedCycleId}.',
        userMessage: 'Buku ini sudah disuntikkan sebelumnya.',
      ));
    }

    final injectResult = await _writer.inject(
      cycleId: cycleId,
      sourceId: book.sourceId,
      sourceLabel: sourceLabel,
      amount: book.netPayAmount!,
    );
    return switch (injectResult) {
      Left(value: final failure) => left(failure),
      Right(value: final lineId) => await _repository.saveBook(
          book.markInjected(cycleId: cycleId, incomeLineId: lineId),
        ),
    };
  }
}
