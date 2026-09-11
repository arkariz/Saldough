import 'package:saldough/features/worklog/domain/entities/billing_book.dart';
import 'package:saldough/shared/income/income.dart';
import 'package:state_management/state_management.dart';

/// State [WorklogBloc]. `effect` tidak pernah masuk [props] (ADR-0003).
final class WorklogState extends UiState<WorklogState> {
  /// Membuat [WorklogState].
  const WorklogState({
    required this.sources,
    required this.sourceId,
    required this.books,
    required this.isLoading,
    this.cycleIds = const [],
    super.effect,
  });

  /// State awal sebelum sumber pemasukan freelance dimuat.
  factory WorklogState.initial() =>
      const WorklogState(sources: [], sourceId: '', books: [], isLoading: true);

  /// Seluruh `IncomeSource` bertipe [IncomeSourceKind.hourlyFreelance].
  final List<IncomeSource> sources;

  /// Sumber yang sedang dipilih. Kosong berarti belum ada yang dipilih.
  final String sourceId;

  /// Buku milik [sourceId], terurut dari yang terlama.
  final List<BillingBook> books;

  /// Sedang memuat/menyimpan.
  final bool isLoading;

  /// Seluruh `id` siklus yang sudah dibuat, terurut menaik (UX-09: dasar
  /// pemilih siklus tujuan penyuntikan, bukan input `YYYY-MM` bebas).
  final List<String> cycleIds;

  /// Sumber yang sedang dipilih, atau `null` kalau [sourceId] kosong.
  IncomeSource? get selectedSource => sources.where((s) => s.id == sourceId).firstOrNull;

  /// Buku yang masih terbuka, atau `null` kalau tidak ada (belum ada entri
  /// tercatat, atau buku terakhir sudah ditutup).
  BillingBook? get openBook => books.where((b) => !b.isClosed).firstOrNull;

  /// Buku yang sudah ditutup, terurut dari yang terbaru (FR-TIME-004).
  List<BillingBook> get closedBooks => books.where((b) => b.isClosed).toList().reversed.toList();

  @override
  WorklogState copyWith({
    List<IncomeSource>? sources,
    String? sourceId,
    List<BillingBook>? books,
    bool? isLoading,
    List<String>? cycleIds,
    UiEffect? effect,
  }) {
    return WorklogState(
      sources: sources ?? this.sources,
      sourceId: sourceId ?? this.sourceId,
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      cycleIds: cycleIds ?? this.cycleIds,
      effect: effect,
    );
  }

  /// Helper transisi state — berpindah menampilkan [books] milik [sourceId].
  WorklogState withBooks(List<BillingBook> books, {UiEffect? effect}) =>
      copyWith(books: books, isLoading: false, effect: effect);

  @override
  List<Object?> get props => [sources, sourceId, books, isLoading, cycleIds];
}
