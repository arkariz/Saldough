import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_activity_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:state_management/state_management.dart';

part 'wallet_activity_event.dart';

/// Transaksi bulan berjalan yang menyentuh satu dompet, untuk rincian dompet
/// (T-2.8, FR-WAL-004). Dulu layar itu meminjam `TransactionBloc` tab
/// Riwayat -- ikut bulan dan penyaring yang sedang dipilih di sana; kini
/// fitur `wallet` membaca buku besar sendiri lewat `shared/transaction`
/// (ADR-030 §3.3).
///
/// ⚠ HANYA bulan berjalan (ADR-012: buku besar dipartisi per bulan;
/// `listAllTransactions` untuk hitung ulang saldo, bukan untuk layar).
final class WalletActivityBloc extends Bloc<WalletActivityEvent, WalletActivityState> {
  /// Membuat [WalletActivityBloc]; [now] disuntikkan untuk uji.
  WalletActivityBloc({
    required this._transactionRepository,
    required LedgerChanges ledgerChanges,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(WalletActivityState.initial()) {
    on<WalletActivityStarted>(_onStarted);
    on<_WalletActivityRefreshed>(_onRefreshed);
    // ADR-030 §3.4: transaksi berubah di layar lain -> muat ulang tanpa
    // kerangka.
    _ledgerSubscription = ledgerChanges.from(this).listen((_) => add(const _WalletActivityRefreshed()));
  }

  late final StreamSubscription<void> _ledgerSubscription;
  final TransactionRepository _transactionRepository;
  final DateTime Function() _now;

  String? _walletId;

  Future<void> _onStarted(WalletActivityStarted event, Emitter<WalletActivityState> emit) async {
    _walletId = event.walletId;
    emit(state.copyWith(isLoading: true));
    await _load(emit);
  }

  Future<void> _onRefreshed(_WalletActivityRefreshed event, Emitter<WalletActivityState> emit) async {
    if (_walletId != null) await _load(emit);
  }

  Future<void> _load(Emitter<WalletActivityState> emit) async {
    final walletId = _walletId!;
    final now = _now();
    switch (await _transactionRepository.listTransactionsInMonth(DateTime(now.year, now.month))) {
      case Left():
        // Riwayat di sini data sekunder: gagal dibaca tampil sebagai kosong,
        // saldo dompet tetap dari `WalletBloc`.
        emit(state.copyWith(isLoading: false, transactions: const []));
      case Right(value: final transactions):
        final touched = [
          for (final transaction in transactions)
            if (walletIdsOf(transaction).contains(walletId)) transaction,
        ]..sort((a, b) => b.date.compareTo(a.date));
        emit(state.copyWith(isLoading: false, transactions: touched));
    }
  }

  @override
  Future<void> close() async {
    await _ledgerSubscription.cancel();
    return super.close();
  }
}
