import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/shared/wealth/wealth.dart';
import 'package:state_management/state_management.dart';

/// Satu titik grafik Riwayat kekayaan: periode, nilai di akhirnya, dan
/// pecahan perubahannya dari periode sebelumnya (`null` untuk titik pertama).
typedef WealthPeriodPoint = ({FinancialPeriod period, WealthPoint point, WealthChange? change});

/// State `WealthHistoryBloc`.
final class WealthHistoryState extends UiState<WealthHistoryState> {
  /// Membuat [WealthHistoryState].
  const WealthHistoryState({
    required this.isLoading,
    required this.failed,
    required this.points,
    required this.selected,
    required this.hasLockedOlder,
    super.effect,
  });

  /// State awal.
  factory WealthHistoryState.initial() =>
      const WealthHistoryState(isLoading: true, failed: false, points: [], selected: 0, hasLockedOlder: false);

  /// Sedang memuat.
  final bool isLoading;

  /// Gagal memuat.
  final bool failed;

  /// Titik per periode, terlama dulu; hanya yang boleh dilihat paket aktif.
  final List<WealthPeriodPoint> points;

  /// Indeks titik terpilih di [points].
  final int selected;

  /// Gratis: ada periode yang lebih tua dari batas (disembunyikan).
  final bool hasLockedOlder;

  /// Titik terpilih, atau `null` bila belum ada.
  WealthPeriodPoint? get current => selected >= 0 && selected < points.length ? points[selected] : null;

  /// Cukup titik untuk menggambar grafik (minimal dua).
  bool get hasChart => points.length >= 2;

  @override
  WealthHistoryState copyWith({
    bool? isLoading,
    bool? failed,
    List<WealthPeriodPoint>? points,
    int? selected,
    bool? hasLockedOlder,
    UiEffect? effect,
  }) => WealthHistoryState(
    isLoading: isLoading ?? this.isLoading,
    failed: failed ?? this.failed,
    points: points ?? this.points,
    selected: selected ?? this.selected,
    hasLockedOlder: hasLockedOlder ?? this.hasLockedOlder,
    effect: effect,
  );

  @override
  List<Object?> get props => [isLoading, failed, points, selected, hasLockedOlder];
}
