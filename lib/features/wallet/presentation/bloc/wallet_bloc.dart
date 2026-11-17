import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'wallet_effect.dart';
part 'wallet_event.dart';

/// Bloc layar Dompet (FR-WAL-001..003): memuat dompet, menambah, menyunting
/// (nama, ikon, status aktif, saldo saat ini), dan menghapus dompet yang belum
/// punya transaksi.
///
/// ⚠ Saldo awal adalah PERNYATAAN KEADAAN, bukan transaksi setoran (FR-WAL-002)
/// -- dompet baru disimpan dengan `currentBalance == initialBalance` dan tidak
/// ada `Transaction` yang dibuat. Menyunting saldo saat ini menggeser saldo awal
/// (saldo awal = angka yang diisi - netto transaksi dompet), lalu menghitung
/// ulang saldo tercatat lewat [RecomputeWalletBalances], satu-satunya
/// penyeimbang saldo tersimpan (ADR-012).
final class WalletBloc extends Bloc<WalletEvent, WalletState> {
  /// Membuat [WalletBloc].
  WalletBloc({
    required this._walletRepository,
    required this._transactionRepository,
    required this._recordTransaction,
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
  /// Mencatat penyesuaian saldo saat saldo dompet diubah (ADR-047 §3.2).
  final RecordTransaction _recordTransaction;

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
    final result = await _walletRepository.saveWallet(wallet);
    if (result.isRight()) AppAnalytics.log(ActivationEvents.walletCreated);
    await _afterWrite(result, t.wallet.savedMessage, emit);
  }

  /// Menyimpan nama, ikon, dan status aktif. Bila saldo diisi dan berbeda
  /// dari saldo terhitung, selisihnya dicatat sebagai satu
  /// [BalanceAdjustmentTransaction] bertanggal hari ini; `initialBalance`
  /// tidak pernah digeser (ADR-047 §3.2, KT-W1 = B).
  Future<void> _onEdited(WalletEdited event, Emitter<WalletState> emit) async {
    final target = event.currentBalance;
    var difference = 0;
    // Angka yang sama dengan yang ditampilkan berarti saldo tidak diubah.
    if (target != null && target != event.original.currentBalance) {
      switch (await _transactionRepository.listAllTransactions()) {
        case Left(value: final failure):
          emit(state.copyWith(effect: _effectError(failure)));
          return;
        case Right(value: final transactions):
          // Dari transaksi, bukan cache `currentBalance` yang bisa basi.
          difference = target - const CalculateWalletBalance()(event.original, transactions);
      }
    }
    final updated = event.original.copyWith(
      name: event.name.trim(),
      iconKey: event.iconKey,
      isActive: event.isActive,
    );
    var result = await _walletRepository.saveWallet(updated);
    if (result.isRight() && difference != 0) {
      final direction = difference > 0 ? AdjustmentDirection.increase : AdjustmentDirection.decrease;
      result = await _recordTransaction(
        BalanceAdjustmentTransaction(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          date: DateTime.now(),
          amount: difference.abs(),
          note: '',
          walletId: updated.id,
          direction: direction,
        ),
        source: this,
      );
      if (result.isRight()) AppAnalytics.log(WealthEvents.balanceAdjusted(direction.name));
    }
    final message = difference == 0
        ? t.wallet.updatedMessage
        : t.assets.adjust.savedMessage(amount: signedAdjustmentText(difference));
    await _afterWrite(result, message, emit);
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
