import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_activity_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_activity_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';

import '../../../../helpers/mocks.dart';

/// Riwayat rincian dompet (ADR-030 §3.3): bulan berjalan, hanya transaksi
/// yang menyentuh dompetnya, dan ikut `LedgerChanges`.
void main() {
  late MockTransactionRepository repository;
  late LedgerChanges ledgerChanges;
  final now = DateTime(2026, 9, 30, 12);

  final gaji = IncomeTransaction(id: 'gaji', date: DateTime(2026, 9, 25), amount: 261543800, note: '', walletId: 'bca');
  final kopi = ExpenseTransaction(id: 'kopi', date: DateTime(2026, 9, 27), amount: 3500000, note: '', walletId: 'gopay');
  final isi = TransferTransaction(
    id: 'isi',
    date: DateTime(2026, 9, 28),
    amount: 10000000,
    note: '',
    fromWalletId: 'bca',
    toWalletId: 'gopay',
  );

  setUp(() {
    repository = MockTransactionRepository();
    ledgerChanges = LedgerChanges();
  });

  WalletActivityBloc build() =>
      WalletActivityBloc(transactionRepository: repository, ledgerChanges: ledgerChanges, now: () => now);

  blocTest<WalletActivityBloc, WalletActivityState>(
    'memuat bulan berjalan, hanya transaksi dompet ini (termasuk transfer), terbaru dulu',
    setUp: () => when(
      () => repository.listTransactionsInMonth(DateTime(2026, 9)),
    ).thenAnswer((_) async => Right([gaji, kopi, isi])),
    build: build,
    act: (bloc) => bloc.add(const WalletActivityStarted('gopay')),
    expect: () => [
      const WalletActivityState(transactions: [], isLoading: true),
      WalletActivityState(transactions: [isi, kopi], isLoading: false),
    ],
  );

  blocTest<WalletActivityBloc, WalletActivityState>(
    'LedgerChanges dari tempat lain memuat ulang tanpa kerangka',
    setUp: () {
      var calls = 0;
      when(
        () => repository.listTransactionsInMonth(DateTime(2026, 9)),
      ).thenAnswer((_) async => Right(calls++ == 0 ? [gaji] : [gaji, isi]));
    },
    build: build,
    act: (bloc) async {
      bloc.add(const WalletActivityStarted('bca'));
      await pumpEventQueue();
      ledgerChanges.notifyChanged();
    },
    expect: () => [
      const WalletActivityState(transactions: [], isLoading: true),
      WalletActivityState(transactions: [gaji], isLoading: false),
      WalletActivityState(transactions: [isi, gaji], isLoading: false),
    ],
  );

  blocTest<WalletActivityBloc, WalletActivityState>(
    'gagal dibaca tampil sebagai kosong, bukan kerangka selamanya',
    setUp: () => when(
      () => repository.listTransactionsInMonth(DateTime(2026, 9)),
    ).thenAnswer((_) async => const Left(SystemFailure(code: FailureCode.unknown, message: 'disk rusak'))),
    build: build,
    act: (bloc) => bloc.add(const WalletActivityStarted('bca')),
    expect: () => [
      const WalletActivityState(transactions: [], isLoading: true),
      const WalletActivityState(transactions: [], isLoading: false),
    ],
  );
}
