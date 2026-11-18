part of 'investment_bloc.dart';

/// State [InvestmentBloc].
final class InvestmentState extends UiState<InvestmentState> {
  /// Membuat [InvestmentState].
  const InvestmentState({
    required this.summaries,
    required this.valuations,
    required this.trades,
    required this.wallets,
    required this.isLoading,
    this.loadFailed = false,
    this.saveCount = 0,
    this.lastFailure,
    super.effect,
  });

  /// State awal.
  factory InvestmentState.initial() =>
      const InvestmentState(summaries: [], valuations: [], trades: [], wallets: [], isLoading: true);

  /// Ringkasan semua instrumen.
  final List<InstrumentSummary> summaries;

  /// Semua valuasi.
  final List<InstrumentValuation> valuations;

  /// Semua transaksi investasi.
  final List<InvestmentTransaction> trades;

  /// Semua dompet (nama di baris catatan).
  final List<Wallet> wallets;

  /// Memuat pertama kali.
  final bool isLoading;

  /// Pembacaan terakhir gagal.
  final bool loadFailed;

  /// Bertambah tiap simpan/hapus berhasil (penutup formulir).
  final int saveCount;

  /// Kode galat simpan terakhir (formulir menampilkannya di bawah kolom).
  final FailureCode? lastFailure;

  /// Ringkasan instrumen [id], atau `null`.
  InstrumentSummary? summaryOf(String id) => summaries.where((s) => s.instrument.id == id).firstOrNull;

  /// Valuasi [id], terbaru dulu.
  List<InstrumentValuation> valuationsOf(String id) =>
      valuations.where((v) => v.instrumentId == id).toList()..sort((a, b) => b.date.compareTo(a.date));

  /// Catatan beli/jual [id], terbaru dulu.
  List<InvestmentTransaction> tradesOf(String id) =>
      trades.where((t) => t.instrumentId == id).toList()..sort((a, b) => b.date.compareTo(a.date));

  /// Instrumen Aktif.
  List<InstrumentSummary> get active => summaries.where((s) => s.position.isActive).toList();

  @override
  InvestmentState copyWith({
    List<InstrumentSummary>? summaries,
    List<InstrumentValuation>? valuations,
    List<InvestmentTransaction>? trades,
    List<Wallet>? wallets,
    bool? isLoading,
    bool? loadFailed,
    int? saveCount,
    FailureCode? Function()? lastFailure,
    UiEffect? effect,
  }) => InvestmentState(
    summaries: summaries ?? this.summaries,
    valuations: valuations ?? this.valuations,
    trades: trades ?? this.trades,
    wallets: wallets ?? this.wallets,
    isLoading: isLoading ?? this.isLoading,
    loadFailed: loadFailed ?? this.loadFailed,
    saveCount: saveCount ?? this.saveCount,
    lastFailure: lastFailure == null ? null : lastFailure(),
    effect: effect,
  );

  @override
  List<Object?> get props => [summaries, valuations, trades, wallets, isLoading, loadFailed, saveCount, lastFailure];
}
