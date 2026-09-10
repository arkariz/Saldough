import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:saldough/features/cycle/data/repositories/cycle_repository_impl.dart';
import 'package:saldough/features/cycle/data/repositories/cycle_template_repository_impl.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_template_repository.dart';
import 'package:saldough/features/cycle/domain/repositories/roll_up_resolver.dart';
import 'package:saldough/features/cycle/domain/usecases/roll_over_cycle.dart';
import 'package:saldough/features/cycle/presentation/bloc/cycle_bloc.dart';
import 'package:saldough/shared/income/income.dart';

/// Lingkup dependensi fitur `cycle`.
final class CycleScope extends IsolatedScope {
  /// Membuat [CycleScope] dengan kontainer induk [parentContainer].
  CycleScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<KeyValueStorage>(parent<KeyValueStorage>())
      ..registerSingleton<IncomeSourceRepository>(parent<IncomeSourceRepository>())
      // Implementasi sungguhan (grocery) dikawat di RootModule sejak
      // Fase 4 — lihat catatan di root_module.dart.
      ..registerSingleton<RollUpResolver>(parent<RollUpResolver>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<CycleRepository>(
      () => CycleRepositoryImpl(storage: c<KeyValueStorage>(), resolver: c<RollUpResolver>()),
    );
    c.registerLazySingleton<CycleTemplateRepository>(
      () => CycleTemplateRepositoryImpl(storage: c<KeyValueStorage>()),
    );
    c.registerLazySingleton<RollOverCycle>(
      () => RollOverCycle(
        cycleRepository: c<CycleRepository>(),
        templateRepository: c<CycleTemplateRepository>(),
      ),
    );
    c.registerLazySingleton<CycleBloc>(
      () => CycleBloc(
        cycleRepository: c<CycleRepository>(),
        templateRepository: c<CycleTemplateRepository>(),
        rollOverCycle: c<RollOverCycle>(),
        sourceRepository: c<IncomeSourceRepository>(),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
