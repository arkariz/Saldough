import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'wallet_effect.dart';
part 'wallet_event.dart';

/// Bloc layar Dompet (FR-WAL-001..003): memuat dompet, menambah, menyunting
/// (nama, ikon, status aktif, saldo awal), dan menghapus dompet yang belum
/// punya transaksi.
///
/// ⚠ Saldo awal adalah PERNYATAAN KEADAAN, bukan transaksi setoran (FR-WAL-002)
/// -- dompet baru disimpan dengan `currentBalance == initialBalance` dan tidak
/// ada `Transaction` yang dibuat. Menyunting saldo awal menghitung ulang saldo
/// tercatat lewat [RecomputeWalletBalances], satu-satunya penyeimbang saldo
/// tersimpan (ADR-012).
final class WalletBloc extends Bloc<WalletEvent, WalletState> {
  /// Membuat [WalletBloc].
  WalletBloc({
    required this._walletRepository,
    required this._transactionRepository,
    required this._recomputeWalletBalances,
    required this._ledgerChanges,
  }) : super(WalletState.initial()) {
    on<WalletStarted>(_onStarted);
    on<WalletRefreshed>(_onRefreshed);
    // ADR-030 §3.4: transaksi/saldo berubah di layar lain -> muat ulang
    // tanpa kerangka.
    _ledgerSubscription = _ledgerChanges.from(this).listen((_) => add(const WalletRefreshed()));
    on<WalletAdded>(_onAdded);
    on<WalletEdited>(_onEdited);
    on<WalletDeleted>(_onDeleted);
    on<WalletsReordered>(_onReordered);
  }

  final LedgerChanges _ledgerChanges;
  late final StreamSubscription<void> _ledgerSubscription;
  final WalletRepository _walletRepository;
  final TransactionRepository _transactionRepository;
  final RecomputeWalletBalances _recomputeWalletBalances;

  Future<void> _onStarted(WalletStarted event, Emitter<WalletState> emit) async {
    emit(state.copyWith(isLoading: true, loadFailed: false));
    switch (await _walletRepository.listWallets()) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, loadFailed: true, effect: _effectError(failure)));
      case Right(value: final wallets):
        emit(state.copyWith(wallets: wallets, isLoading: false, loadFailed: false));
    }
  }

  Future<void> _onRefreshed(WalletRefreshed event, Emitter<WalletState> emit) async {
    switch (await _walletRepository.listWallets()) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right(value: final wallets):
        emit(state.copyWith(wallets: wallets, isLoading: false, loadFailed: false));
    }
  }

  Future<void> _onAdded(WalletAdded event, Emitter<WalletState> emit) async {
    final wallet = Wallet(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: event.name.trim(),
      iconKey: event.iconKey,
      initialBalance: event.initialBalance,
      currentBalance: event.initialBalance,
    );
    await _afterWrite(await _walletRepository.saveWallet(wallet), t.wallet.savedMessage, emit);
  }

  Future<void> _onEdited(WalletEdited event, Emitter<WalletState> emit) async {
    final newInitial = event.initialBalance;
    final updated = event.original.copyWith(
      name: event.name.trim(),
      iconKey: event.iconKey,
      isActive: event.isActive,
      initialBalance: newInitial,
    );
    var result = await _walletRepository.saveWallet(updated);
    // Saldo tercatat berubah HANYA kalau saldo awalnya berubah.
    if (result.isRight() && newInitial != null && newInitial != event.original.initialBalance) {
      result = await _recomputeWalletBalances.forWallets({updated.id});
    }
    await _afterWrite(result, t.wallet.updatedMessage, emit);
  }

  Future<void> _onDeleted(WalletDeleted event, Emitter<WalletState> emit) async {
    switch (await _transactionRepository.listAllTransactions()) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right(value: final transactions):
        if (transactions.any((transaction) => _touches(transaction, event.wallet.id))) {
          emit(state.copyWith(effect: _effectMessage(t.wallet.deleteBlockedMessage)));
          return;
        }
        await _afterWrite(await _walletRepository.deleteWallet(event.wallet.id), t.wallet.deletedMessage, emit);
    }
  }

  /// Urutan baru juga memancarkan `LedgerChanges` lewat [_afterWrite] supaya
  /// Beranda dan pemilih dompet ikut urutan yang sama (B-34).
  Future<void> _onReordered(WalletsReordered event, Emitter<WalletState> emit) async {
    await _afterWrite(await _walletRepository.reorderWallets(event.orderedIds), t.wallet.reorderedMessage, emit);
  }

  /// Apakah [transaction] memakai dompet ber-`id` [walletId] -- sebagai dompet
  /// pemasukan/pengeluaran, atau sebagai asal/tujuan transfer.
  bool _touches(Transaction transaction, String walletId) => walletIdsOf(transaction).contains(walletId);

  /// Sesudah menulis: kalau gagal, pertahankan layar dan tampilkan galat;
  /// kalau berhasil, muat ulang dompet TANPA `isLoading` (daftar tidak
  /// berkedip jadi kerangka) lalu tampilkan pesan berhasil.
  Future<void> _afterWrite(Either<Failure, Unit> result, String successMessage, Emitter<WalletState> emit) async {
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        // Unit kerja dompet selesai (termasuk hitung ulang saldo saat
        // disunting) -- baru sekarang layar lain boleh memuat ulang.
        _ledgerChanges.notifyChanged(source: this);
        switch (await _walletRepository.listWallets()) {
          case Left(value: final failure):
            emit(state.copyWith(effect: _effectError(failure)));
          case Right(value: final wallets):
            emit(state.copyWith(wallets: wallets, effect: _effectSaved(successMessage)));
        }
    }
  }

  @override
  Future<void> close() async {
    await _ledgerSubscription.cancel();
    return super.close();
  }
}
