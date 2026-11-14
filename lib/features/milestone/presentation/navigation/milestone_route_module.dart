import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/milestone/presentation/navigation/milestone_route_keys.dart';
import 'package:saldough/features/milestone/presentation/pages/stamp_book_page.dart';
import 'package:saldough/features/milestone/presentation/stamp_book_access.dart';

/// Modul rute fitur `milestone` (ADR-030 §3.3). Koordinatornya hidup di akar
/// (Beranda dan Akun memakai keadaan yang sama), jadi rute hanya
/// menyediakannya lewat [MilestoneBookAccess].
final class MilestoneRouteModule extends FeatureRouteModule {
  /// Membuat [MilestoneRouteModule].
  const MilestoneRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<EmptyInput>(
      key: MilestoneRouteKeys.book,
      defaultInput: () => const EmptyInput(),
      builder: (context, _) => StampBookPage(access: ScopeProvider.of(context)<MilestoneBookAccess>()),
    ),
  ];

  @override
  List<DevEntry> get devEntries => [
    DevEntry.typed<EmptyInput>(
      label: 'Buku Stempel',
      category: 'milestone',
      key: MilestoneRouteKeys.book,
      inputFactory: () => const EmptyInput(),
    ),
  ];
}
