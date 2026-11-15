import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/period_book/presentation/navigation/period_book_route_keys.dart';
import 'package:saldough/features/period_book/presentation/pages/book_cover_page.dart';
import 'package:saldough/features/period_book/presentation/pages/book_report_page.dart';
import 'package:saldough/features/period_book/presentation/pages/ritual_page.dart';
import 'package:saldough/features/period_book/presentation/period_book_read_access.dart';
import 'package:saldough/features/period_book/presentation/period_book_ritual_access.dart';

/// Modul rute fitur `period_book` (ADR-030 §3.3). Gerbang, ingatan, dan sumber
/// data hidup di akar; rute hanya menyediakannya lewat [PeriodBookRitualAccess].
final class PeriodBookRouteModule extends FeatureRouteModule {
  /// Membuat [PeriodBookRouteModule].
  const PeriodBookRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<RitualInput>(
      key: PeriodBookRouteKeys.ritual,
      defaultInput: () => const RitualInput(periodId: ''),
      builder: (context, input) => RitualPage(
        access: ScopeProvider.of(context)<PeriodBookRitualAccess>(),
        periodId: input.periodId,
      ),
    ),
    RouteNode.typed<BookInput>(
      key: PeriodBookRouteKeys.cover,
      defaultInput: () => const BookInput(periodId: ''),
      builder: (context, input) => BookCoverPage(
        access: ScopeProvider.of(context)<PeriodBookReadAccess>(),
        periodId: input.periodId,
      ),
    ),
    RouteNode.typed<BookInput>(
      key: PeriodBookRouteKeys.report,
      defaultInput: () => const BookInput(periodId: ''),
      builder: (context, input) => BookReportPage(
        access: ScopeProvider.of(context)<PeriodBookReadAccess>(),
        periodId: input.periodId,
      ),
    ),
  ];

  @override
  List<DevEntry> get devEntries => [
    // Hanya menu pengembang (build non-rilis): membuka sampul periode Oktober 2026.
    DevEntry.typed<BookInput>(
      label: 'Buku Periode: sampul Okt 2026',
      category: 'period_book',
      key: PeriodBookRouteKeys.cover,
      inputFactory: () => const BookInput(periodId: '2026-10-01'),
    ),
    DevEntry.typed<RitualInput>(
      label: 'Buku Periode: ritual Okt 2026',
      category: 'period_book',
      key: PeriodBookRouteKeys.ritual,
      inputFactory: () => const RitualInput(periodId: '2026-10-01'),
    ),
  ];
}
