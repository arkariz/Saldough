import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:saldough/features/grocery/data/repositories/grocery_plan_repository_impl.dart';
import 'package:saldough/features/grocery/domain/repositories/grocery_plan_repository.dart';
import 'package:saldough/features/grocery/presentation/bloc/grocery_bloc.dart';

/// Lingkup dependensi fitur `grocery`.
final class GroceryScope extends IsolatedScope {
  /// Membuat [GroceryScope] dengan kontainer induk [parentContainer].
  GroceryScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c.registerSingleton<KeyValueStorage>(parent<KeyValueStorage>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<GroceryPlanRepository>(
      () => GroceryPlanRepositoryImpl(storage: c<KeyValueStorage>()),
    );
    c.registerLazySingleton<GroceryBloc>(
      () => GroceryBloc(repository: c<GroceryPlanRepository>()),
      dispose: (bloc) => bloc.close(),
    );
  }
}
