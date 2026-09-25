import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/freelance/data/repositories/freelance_repository_impl.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_kind.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/payment_status.dart';
import 'package:saldough/features/freelance/domain/usecases/receive_freelance_payment.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_bloc.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

T _right<T>(Either<Failure, T> result) => result.getOrElse((_) => throw StateError('expected Right'));

/// Uji T-5.7 di atas repository sungguhan dengan penyimpanan di memori, supaya
/// invarian saldo diuji ujung ke ujung: bloc → use case → buku besar → saldo.
void main() {
  const tax = DeductionRule(id: 'pajak', label: 'Pajak', kind: DeductionKind.percentage, value: 25);
  const startBalance = 100000000;

  late FreelanceRepositoryImpl freelance;
  late WalletRepositoryImpl wallets;
  late TransactionRepositoryImpl transactions;
  late FreelanceBloc bloc;

  setUp(() async {
    final storage = InMemoryKeyValueStorage();
    freelance = FreelanceRepositoryImpl(storage: storage);
    wallets = WalletRepositoryImpl(storage: storage);
    transactions = TransactionRepositoryImpl(storage: storage);
    await wallets.saveWallet(
      const Wallet(
        id: 'bca',
        name: 'BCA',
        iconKey: 'walletBank',
        initialBalance: startBalance,
        currentBalance: startBalance,
      ),
    );
    bloc = FreelanceBloc(
      freelanceRepository: freelance,
      walletRepository: wallets,
      receivePayment: ReceiveFreelancePayment(
        freelanceRepository: freelance,
        recordTransaction: RecordTransaction(
          transactionRepository: transactions,
          recomputeWalletBalances: RecomputeWalletBalances(
            walletRepository: wallets,
            transactionRepository: transactions,
          ),
        ),
      ),
    );
    await send(bloc, const FreelanceStarted(), expectEffect: false);
  });

  tearDown(() => bloc.close());

  Future<int> balance() async => _right(await wallets.listWallets()).single.currentBalance;

  Future<List<Transaction>> ledger() async => _right(await transactions.listAllTransactions());

  /// Proyek Rp72.500/jam dengan pajak 2,5% dan satu entri 37 jam — kasus
  /// DOMAIN_MODEL.md.
  Future<void> seedProjectAndEntry() async {
    await send(bloc, const FreelanceProjectAdded(name: 'Studio', hourlyRate: 7250000, deductionRules: [tax]));
    await send(
      bloc,
      FreelanceEntryAdded(
        projectId: bloc.state.projects.single.id,
        date: DateTime(2026, 9, 20),
        hours: 37,
        hourlyRate: 7250000,
      ),
    );
  }

  Future<FreelancePayment> seedPayment() async {
    await seedProjectAndEntry();
    await send(
      bloc,
      FreelancePaymentCreated(
        projectId: bloc.state.projects.single.id,
        entryIds: [bloc.state.entries.single.id],
        expectedDate: DateTime(2026, 10, 5),
      ),
    );
    return bloc.state.payments.single;
  }

  test('mencatat, menyunting, dan menghapus worklog tidak mengubah saldo (aturan 6)', () async {
    await seedProjectAndEntry();
    expect(await balance(), startBalance);

    final entry = bloc.state.entries.single;
    await send(bloc, FreelanceEntryEdited(entry.copyWith(hours: 40)));
    expect(bloc.state.entries.single.hours, 40);
    expect(await balance(), startBalance);

    await send(bloc, FreelanceEntryDeleted(bloc.state.entries.single));
    expect(bloc.state.entries, isEmpty);
    expect(await balance(), startBalance);
    expect(await ledger(), isEmpty);
  });

  test('membuat pembayaran tidak mengubah saldo, dan 37 jam × Rp72.500 − pajak 2,5% = 261.543.750 sen', () async {
    final payment = await seedPayment();

    expect(payment.status, PaymentStatus.pending);
    expect(payment.deductionRules, [tax]);
    expect(bloc.state.entries.single.paymentId, payment.id);
    final breakdown = bloc.state.breakdownOf(payment);
    expect(breakdown.grossPay, 268250000);
    expect(breakdown.deductions.single.amount, 6706250);
    expect(breakdown.netPay, 261543750);
    expect(await balance(), startBalance);
  });

  test('pembayaran yang dicatat diterima menambah saldo tepat satu kali', () async {
    final payment = await seedPayment();

    await send(
      bloc,
      FreelancePaymentReceived(payment: payment, walletId: 'bca', date: DateTime(2026, 10, 6), note: 'Studio'),
    );
    expect(await balance(), startBalance + 261543750);
    final paid = bloc.state.payments.single;
    expect(paid.isPaid, isTrue);
    expect(paid.incomeTransactionId, 'freelance-${payment.id}');
    final income = (await ledger()).single as IncomeTransaction;
    expect(income.id, paid.incomeTransactionId);
    expect(income.amount, 261543750);
    expect(income.freelancePaymentId, payment.id);

    // Dicatat kedua kalinya — dengan salinan lama maupun baru — ditolak.
    await send(
      bloc,
      FreelancePaymentReceived(payment: payment, walletId: 'bca', date: DateTime(2026, 10, 6), note: ''),
    );
    expect((bloc.state.effect! as ShowSnackBarEffect).message, t.freelance.paymentAlreadyPaid);
    expect(await balance(), startBalance + 261543750);
    expect(await ledger(), hasLength(1));
  });

  test('membatalkan penerimaan menghapus transaksinya dan mengembalikan saldo', () async {
    final payment = await seedPayment();
    await send(
      bloc,
      FreelancePaymentReceived(payment: payment, walletId: 'bca', date: DateTime(2026, 10, 6), note: ''),
    );

    await send(bloc, FreelanceReceiptCancelled(bloc.state.payments.single));
    expect(bloc.state.payments.single.status, PaymentStatus.pending);
    expect(bloc.state.payments.single.incomeTransactionId, isNull);
    expect(await ledger(), isEmpty);
    expect(await balance(), startBalance);
  });

  test('entri yang sudah masuk pembayaran tidak bisa disunting atau dihapus', () async {
    await seedPayment();
    final entry = bloc.state.entries.single;

    await send(bloc, FreelanceEntryEdited(entry.copyWith(hours: 1)));
    expect(bloc.state.entries.single.hours, 37);
    await send(bloc, FreelanceEntryDeleted(entry));
    expect(bloc.state.entries, hasLength(1));
  });

  test('menghapus pembayaran tertunda mengembalikan entrinya jadi belum ditagih', () async {
    final payment = await seedPayment();

    await send(bloc, FreelancePaymentDeleted(payment));
    expect(bloc.state.payments, isEmpty);
    expect(bloc.state.entries.single.paymentId, isNull);
    expect(bloc.state.unbilledEntriesOf(payment.projectId), hasLength(1));
    expect(await balance(), startBalance);
  });

  test('mengubah tarif dan potongan proyek tidak mengubah entri dan pembayaran lama (ADR-019)', () async {
    final payment = await seedPayment();
    final project = bloc.state.projects.single;

    await send(bloc, FreelanceProjectEdited(project.copyWith(hourlyRate: 10000000, deductionRules: const [])));
    expect(bloc.state.entries.single.hourlyRate, 7250000);
    expect(bloc.state.breakdownOf(bloc.state.payments.single).netPay, 261543750);
    expect(bloc.state.payments.single.deductionRules, payment.deductionRules);
  });

  test('proyek yang sudah punya entri tidak bisa dihapus', () async {
    await seedProjectAndEntry();
    await send(bloc, FreelanceProjectDeleted(bloc.state.projects.single));
    expect(bloc.state.projects, hasLength(1));
  });

  test('pembayaran hanya bisa dibuat dari entri belum ditagih milik proyek itu', () async {
    final payment = await seedPayment();
    await send(
      bloc,
      FreelancePaymentCreated(
        projectId: payment.projectId,
        entryIds: payment.entryIds,
        expectedDate: DateTime(2026, 11),
      ),
    );
    expect(bloc.state.payments, hasLength(1));
  });

  test('paymentId yang menunjuk pembayaran yang tidak ada dibaca sebagai belum ditagih', () async {
    await seedProjectAndEntry();
    final entry = bloc.state.entries.single;
    await freelance.saveEntries([entry.copyWith(paymentId: () => 'hilang')]);
    await send(bloc, const FreelanceStarted(), expectEffect: false);

    expect(bloc.state.paymentOf(bloc.state.entries.single), isNull);
    expect(bloc.state.unbilledEntriesOf(entry.projectId), hasLength(1));
    expect(bloc.state.summary.unpaid, 268250000);
  });

  test('ringkasan: diterima + belum diterima = diperoleh (kotor)', () async {
    final payment = await seedPayment();
    await send(
      bloc,
      FreelanceEntryAdded(projectId: payment.projectId, date: DateTime(2026, 9, 21), hours: 2, hourlyRate: 7250000),
    );
    await send(
      bloc,
      FreelancePaymentReceived(payment: payment, walletId: 'bca', date: DateTime(2026, 10, 6), note: ''),
    );

    final FreelanceSummary(:totalHours, :earned, :paid, :unpaid) = bloc.state.summary;
    expect(totalHours, 39);
    expect(earned, 39 * 7250000);
    expect(paid, 37 * 7250000);
    expect(unpaid, 2 * 7250000);
    expect(bloc.state.paidNetTotal, 261543750);
    expect(bloc.state.pendingNetTotal, 0);
  });
}

/// Mengirim [event] lalu menunggu bloc selesai memprosesnya: state dengan
/// efek (berhasil atau ditolak), atau — untuk [expectEffect] `false` — state
/// yang tidak sedang memuat.
///
/// Penantiannya dibatasi waktu, supaya event yang tidak menghasilkan state
/// baru tidak menggantung uji.
Future<void> send(FreelanceBloc bloc, FreelanceEvent event, {bool expectEffect = true}) async {
  final next = bloc.stream.firstWhere((s) => expectEffect ? s.effect != null : !s.isLoading);
  bloc.add(event);
  await next.timeout(const Duration(milliseconds: 500), onTimeout: () => bloc.state);
  // Beri kesempatan emisi lanjutan (muat ulang sesudah efek galat).
  await Future<void>.delayed(Duration.zero);
}
