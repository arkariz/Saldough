import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
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
    required this._goalRepository,
    required this._ledgerChanges,
    this._investmentRepository,
    this._sheetPrices,
    this._sheetLinks,
    this._connectSheet,
    bool Function()? isPlus,
    bool Function()? isGoogleUser,
  }) : _isPlus = isPlus ?? (() => false),
       _isGoogleUser = isGoogleUser ?? (() => false),
       super(WalletState.initial()) {
    on<InvestmentPricesRefreshed>(_onPricesRefreshed);
    on<PriceSheetConnected>(_onSheetConnected);
    on<PriceSheetDisconnected>(_onSheetDisconnected);
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

  /// Tujuan tabungan untuk bagian Tujuan di tab Dompet (ADR-048 §3.8).
  final SavingsGoalRepository _goalRepository;

  /// Tujuan terbaru, `const []` bila gagal dibaca (bagian Tujuan bukan inti).
  Future<List<SavingsGoal>> _loadGoals() async => (await _goalRepository.listGoals()).getOrElse((_) => const []);

  /// Instrumen dan valuasi (ADR-049 §3.10); `null` di lingkup tanpa investasi.
  final InvestmentRepository? _investmentRepository;

  /// Pengambil harga Sheet (ADR-051 §3.4); `null` di lingkup tanpanya.
  final RefreshSheetPrices? _sheetPrices;

  /// Tautan Sheet, untuk penanda dan tombol Segarkan.
  final PriceSheetLinkStore? _sheetLinks;

  /// Paket Plus aktif (fitur Sheet khusus Plus, KT-A4).
  final bool Function() _isPlus;

  /// Masuk dengan Google: syarat Google Sheet (ADR-051 §3.2).
  final bool Function() _isGoogleUser;

  /// Alur Hubungkan Google Sheet (ADR-051 §3.2).
  final ConnectPriceSheet? _connectSheet;

  /// Pintu Google Sheet boleh tampil.
  bool get _sheetAvailable => _connectSheet != null && _isGoogleUser();

  Future<void> _onPricesRefreshed(InvestmentPricesRefreshed event, Emitter<WalletState> emit) async {
    final refresh = _sheetPrices;
    if (refresh == null || !_isPlus() || state.sheetRefreshing) return;
    emit(state.copyWith(sheetRefreshing: true));
    switch (await refresh(force: event.force)) {
      case Left(value: final failure):
        // Izin dicabut dan Sheet hilang selalu diberitahukan (perlu tindakan);
        // galat jaringan hanya saat pengguna sendiri menekan Segarkan.
        final actionable =
            failure.code == PriceSheetFailures.notAuthorized || failure.code == PriceSheetFailures.notFound;
        await _applySheetFailure(failure, emit, announce: event.force || actionable);
      case Right(value: final result):
        await _afterSheetFetch(result, emit);
        emit(state.copyWith(sheetRefreshing: false));
    }
  }

  Future<void> _onSheetConnected(PriceSheetConnected event, Emitter<WalletState> emit) async {
    final connect = _connectSheet;
    if (connect == null || !_isPlus() || state.sheetConnecting) return;
    emit(state.copyWith(sheetConnecting: true));
    final result = await connect();
    if (result case Left(value: final failure)) {
      await _applySheetFailure(failure, emit, connecting: true);
      return;
    }
    AppAnalytics.log(WealthEvents.sheetLinked);
    await _afterSheetFetch(result.getOrElse((_) => (outcome: SheetRefreshOutcome.notLinked, saved: 0)), emit);
    emit(state.copyWith(sheetConnecting: false, effect: _effectSaved(t.assets.invest.sheet.connected)));
  }

  Future<void> _onSheetDisconnected(PriceSheetDisconnected event, Emitter<WalletState> emit) async {
    await _sheetLinks?.clear();
    emit(
      state.copyWith(
        sheetLinked: false,
        sheetId: () => null,
        sheetFetchedAt: () => null,
        sheetProblem: PriceSheetProblem.none,
        // Putuskan berhasil dilakukan, bukan galat.
        effect: _effectSaved(t.assets.invest.sheet.disconnected),
      ),
    );
  }

  /// Sesudah pengambilan: muat ulang instrumen bila ada harga baru, perbarui
  /// penanda tautan.
  Future<void> _afterSheetFetch(SheetRefreshResult result, Emitter<WalletState> emit) async {
    if (result.outcome == SheetRefreshOutcome.updated) {
      AppAnalytics.log(WealthEvents.valuationSheetSynced(result.saved));
      // Lapis Investasi berubah: Beranda dan layar lain ikut segar.
      _ledgerChanges.notifyChanged(source: this);
      final investments = await _loadInstruments();
      emit(state.copyWith(instruments: investments.items, investmentsFailed: investments.failed));
    }
    final link = (await _sheetLinks?.read())?.getOrElse((_) => null);
    emit(
      state.copyWith(
        sheetLinked: link != null,
        sheetId: () => link?.sheetId,
        sheetFetchedAt: () => link?.lastFetchedAt,
        sheetProblem: PriceSheetProblem.none,
      ),
    );
  }

  /// Galat Sheet (ADR-051 §3.6): izin dicabut tetap terhubung dengan ajakan
  /// menghubungkan lagi; Sheet hilang melupakan tautan.
  Future<void> _applySheetFailure(
    Failure failure,
    Emitter<WalletState> emit, {
    bool connecting = false,
    bool announce = true,
  }) async {
    final problem = switch (failure.code) {
      PriceSheetFailures.notAuthorized => PriceSheetProblem.notAuthorized,
      PriceSheetFailures.notFound => PriceSheetProblem.notFound,
      _ => PriceSheetProblem.none,
    };
    if (problem == PriceSheetProblem.notFound) await _sheetLinks?.clear();
    final link = (await _sheetLinks?.read())?.getOrElse((_) => null);
    final message = switch (problem) {
      PriceSheetProblem.notAuthorized when connecting => t.assets.invest.sheet.denied,
      PriceSheetProblem.notAuthorized => t.assets.invest.sheet.notAuthorized,
      PriceSheetProblem.notFound => t.assets.invest.sheet.notFound,
      PriceSheetProblem.none => t.assets.invest.sheet.refreshFailed,
    };
    emit(
      state.copyWith(
        sheetConnecting: false,
        sheetRefreshing: false,
        sheetLinked: link != null,
        sheetId: () => link?.sheetId,
        sheetProblem: connecting ? state.sheetProblem : problem,
        effect: announce ? _effectMessage(message) : null,
      ),
    );
  }

  /// Ringkasan instrumen; gagal dibaca → `failed` (lapis Investasi tidak
  /// ditebak 0, rupa B-97 §1.3).
  Future<({List<InstrumentSummary> items, bool failed})> _loadInstruments() async {
    final repository = _investmentRepository;
    if (repository == null) return (items: const <InstrumentSummary>[], failed: false);
    final result = await LoadInstrumentSummaries(investments: repository, transactions: _transactionRepository)();
    return switch (result) {
      Left() => (items: state.instruments, failed: true),
      Right(value: final items) => (items: items, failed: false),
    };
  }

  Future<void> _onStarted(WalletStarted event, Emitter<WalletState> emit) async {
    emit(state.copyWith(isLoading: true, loadFailed: false));
    switch (await _walletRepository.listWallets()) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, loadFailed: true, effect: _effectError(failure)));
      case Right(value: final wallets):
        final investments = await _loadInstruments();
        final link = (await _sheetLinks?.read())?.getOrElse((_) => null);
        emit(
          state.copyWith(
            wallets: wallets,
            goals: await _loadGoals(),
            instruments: investments.items,
            investmentsFailed: investments.failed,
            sheetLinked: link != null,
            sheetId: () => link?.sheetId,
            sheetFetchedAt: () => link?.lastFetchedAt,
            sheetAvailable: _sheetAvailable,
            isLoading: false,
            loadFailed: false,
          ),
        );
    }
  }

  /// Buku besar berubah: muat ulang, lalu tandai tujuan yang baru tercapai
  /// (ADR-048 §3.3, §3.9) dengan satu pesan singkat.
  Future<void> _onRefreshed(WalletRefreshed event, Emitter<WalletState> emit) async {
    final reached = (await SyncSavingsGoalStatus(goalRepository: _goalRepository, walletRepository: _walletRepository)())
        .getOrElse((_) => const []);
    for (final _ in reached) {
      AppAnalytics.log(WealthEvents.goalCompleted);
    }
    switch (await _walletRepository.listWallets()) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right(value: final wallets):
        final investments = await _loadInstruments();
        emit(
          state.copyWith(
            wallets: wallets,
            goals: await _loadGoals(),
            instruments: investments.items,
            investmentsFailed: investments.failed,
            // Masuk atau keluar akun Google bisa terjadi di Akun.
            sheetAvailable: _sheetAvailable,
            isLoading: false,
            loadFailed: false,
            effect: reached.isEmpty ? null : _effectSaved(t.assets.goal.reachedMessage(name: reached.first.name)),
          ),
        );
    }
  }


  Future<void> _onAdded(WalletAdded event, Emitter<WalletState> emit) async {
    final wallet = Wallet(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: event.name.trim(),
      iconKey: event.iconKey,
      initialBalance: event.initialBalance,
      currentBalance: event.initialBalance,
      createdAt: DateTime.now(),
      colorKey: event.colorKey,
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
      colorKey: event.colorKey,
      clearColor: event.colorKey == null,
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
        // Dompet milik tujuan hanya dihapus bersama tujuannya (ADR-048 §8.2).
        final owner = (await _loadGoals()).where((g) => g.walletId == event.wallet.id).firstOrNull;
        if (owner != null) {
          emit(state.copyWith(effect: _effectMessage(t.assets.goal.walletOwnedMessage(name: owner.name))));
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
            emit(state.copyWith(wallets: wallets, goals: await _loadGoals(), effect: _effectSaved(successMessage)));
        }
    }
  }

  @override
  Future<void> close() async {
    await _ledgerSubscription.cancel();
    return super.close();
  }
}
