import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/freelance/data/repositories/freelance_repository_impl.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/repositories/freelance_repository.dart';
import 'package:saldough/features/freelance/domain/usecases/receive_freelance_payment.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

T _right<T>(Either<Failure, T> result) => result.getOrElse((_) => throw StateError('expected Right'));

class _MockFreelanceRepository extends Mock implements FreelanceRepository {}

void main() {
  late WalletRepositoryImpl wallets;
  late TransactionRepositoryImpl transactions;
  late _MockFreelanceRepository freelance;
  // `savePayment` gagal sebanyak ini lebih dulu -- meniru kegagalan penulisan
  // di tengah pencatatan diterima.
  var paymentFailures = 0;
  late ReceiveFreelancePayment receive;

  final payment = FreelancePayment(id: 'pay', projectId: 'p', entryIds: const ['w'], expectedDate: DateTime(2026, 10));

  setUp(() async {
    final storage = InMemoryKeyValueStorage();
    wallets = WalletRepositoryImpl(storage: storage);
    transactions = TransactionRepositoryImpl(storage: storage);
    final inner = FreelanceRepositoryImpl(storage: storage);
    paymentFailures = 0;
    registerFallbackValue(payment);
    freelance = _MockFreelanceRepository();
    when(() => freelance.savePayment(any())).thenAnswer((invocation) async {
      if (paymentFailures > 0) {
        paymentFailures--;
        return left(const SystemFailure(code: FailureCode.unknown, message: 'disk penuh'));
      }
      return inner.savePayment(invocation.positionalArguments.single as FreelancePayment);
    });
    when(freelance.listPayments).thenAnswer((_) => inner.listPayments());
    await wallets.saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    );
    await freelance.savePayment(payment);
    receive = ReceiveFreelancePayment(
      freelanceRepository: freelance,
      recordTransaction: RecordTransaction(
        ledgerChanges: LedgerChanges(),
        transactionRepository: transactions,
        recomputeWalletBalances: RecomputeWalletBalances(
          walletRepository: wallets,
          transactionRepository: transactions,
        ),
      ),
    );
  });

  Future<int> balance() async => _right(await wallets.listWallets()).single.currentBalance;

  test('pembayaran gagal ditulis sesudah transaksinya: pengulangan menimpa transaksi yang sama', () async {
    paymentFailures = 1;
    final first = await receive(payment: payment, netPay: 1000, walletId: 'bca', date: DateTime(2026, 10, 2), note: '');
    expect(first.isLeft(), isTrue);
    expect(_right(await freelance.listPayments()).single.isPaid, isFalse);

    final retry = await receive(payment: payment, netPay: 1000, walletId: 'bca', date: DateTime(2026, 10, 2), note: '');
    expect(retry.isRight(), isTrue);
    expect(_right(await transactions.listAllTransactions()), hasLength(1));
    expect(await balance(), 1000);
    expect(_right(await freelance.listPayments()).single.isPaid, isTrue);
  });

  test('menolak pembayaran yang sudah diterima dan gaji bersih yang tidak positif', () async {
    final paid = payment.markPaid(walletId: 'bca', date: DateTime(2026, 10, 2));
    final again = await receive(payment: paid, netPay: 1000, walletId: 'bca', date: DateTime(2026, 10, 2), note: '');
    expect(again.getLeft().toNullable()?.code, ReceiveFreelancePayment.alreadyPaidCode);

    final zero = await receive(payment: payment, netPay: 0, walletId: 'bca', date: DateTime(2026, 10, 2), note: '');
    expect(zero.getLeft().toNullable()?.code, ReceiveFreelancePayment.nonPositiveNetPayCode);
    expect(_right(await transactions.listAllTransactions()), isEmpty);
    expect(await balance(), 0);
  });

  test('pembatalan gagal ditulis: pembayaran tetap diterima dan transaksinya tetap ada', () async {
    await receive(payment: payment, netPay: 1000, walletId: 'bca', date: DateTime(2026, 10, 2), note: '');
    final paid = _right(await freelance.listPayments()).single;

    paymentFailures = 1;
    final undo = await receive.undo(payment: paid, netPay: 1000);
    expect(undo.isLeft(), isTrue);
    expect(_right(await freelance.listPayments()).single.isPaid, isTrue);
    expect(_right(await transactions.listAllTransactions()), hasLength(1));
    expect(await balance(), 1000);
  });
}
