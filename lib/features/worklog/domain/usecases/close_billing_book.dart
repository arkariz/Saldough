import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/worklog/domain/entities/billing_book.dart';
import 'package:saldough/features/worklog/domain/repositories/worklog_repository.dart';
import 'package:saldough/shared/income/income.dart';

/// Menutup [BillingBook] yang sedang terbuka: menghitung gaji bersih lewat
/// [CalculateNetPay] dan menyimpan hasilnya (FR-TIME-003).
final class CloseBillingBook {
  /// Membuat [CloseBillingBook].
  CloseBillingBook({required this._repository}) : _calculateNetPay = CalculateNetPay();

  final WorklogRepository _repository;
  final CalculateNetPay _calculateNetPay;

  /// Menutup [book] memakai tarif dan potongan dari [source].
  ///
  /// `Left(BusinessRuleFailure)` kalau [book] sudah ditutup sebelumnya, atau
  /// tidak punya entri sama sekali.
  Future<Either<Failure, NetPayBreakdown>> call({required BillingBook book, required IncomeSource source}) async {
    if (book.isClosed) {
      return left(BusinessRuleFailure(
        code: const FailureCode('BOOK_ALREADY_CLOSED'),
        message: 'BillingBook ${book.id} sudah ditutup.',
        userMessage: 'Buku ini sudah ditutup.',
      ));
    }
    if (book.entries.isEmpty) {
      return left(BusinessRuleFailure(
        code: const FailureCode('BOOK_HAS_NO_ENTRIES'),
        message: 'BillingBook ${book.id} tidak punya entri.',
        userMessage: 'Belum ada jam yang dicatat di buku ini.',
      ));
    }

    final breakdown = _calculateNetPay(totalHours: book.totalHours, source: source);
    final saveResult = await _repository.saveBook(book.close(netPayAmount: breakdown.netPay));
    return switch (saveResult) {
      Left(value: final failure) => left(failure),
      Right() => right(breakdown),
    };
  }
}
