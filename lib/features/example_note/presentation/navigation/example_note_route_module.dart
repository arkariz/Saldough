import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/features/example_note/di/example_note_scope.dart';
import 'package:saldough/features/example_note/presentation/bloc/example_note_bloc.dart';
import 'package:saldough/features/example_note/presentation/navigation/example_note_route_keys.dart';
import 'package:saldough/features/example_note/presentation/pages/example_note_page.dart';
import 'package:state_management/state_management.dart';

/// Modul rute `example_note`. Memasang [ExampleNoteScope] lewat
/// [ScopeWidget] — kontainer induk diambil lewat [ScopeProvider.of] SEBELUM
/// [ScopeWidget] disisipkan, karena [ScopeProvider] belum ada di pohon saat
/// `create` dijalankan (lihat ARCHITECTURE_OVERVIEW.md bagian "Navigasi").
final class ExampleNoteRouteModule extends FeatureRouteModule {
  /// Membuat [ExampleNoteRouteModule].
  const ExampleNoteRouteModule();

  @override
  List<RouteNode> get routes => [
        RouteNode.typed<EmptyInput>(
          key: ExampleNoteRouteKeys.list,
          defaultInput: EmptyInput.new,
          builder: (context, input) {
            final parentContainer = ScopeProvider.of(context);
            return ScopeWidget<ExampleNoteScope>(
              create: () => ExampleNoteScope(parentContainer: parentContainer),
              builder: (context, scope) => BlocProvider.value(
                value: scope.container<ExampleNoteBloc>(),
                child: const ExampleNotePage(),
              ),
            );
          },
        ),
      ];
}
