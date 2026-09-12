import 'package:di/di.dart';
import 'package:saldough/features/income/domain/repositories/income_worklog_gateway.dart';
import 'package:saldough/features/income/presentation/bloc/income_source_bloc.dart';
import 'package:saldough/shared/income/income.dart';

/// Lingkup dependensi fitur `income`. `IncomeSourceRepository` sudah
/// didaftarkan di `RootModule` sebagai repository bersama (ADR-0009 —
/// `income` dipakai juga oleh fitur `cycle` dan `worklog`), jadi cukup
/// dibawa lewat [bridge], tidak didaftarkan ulang di sini.
final class IncomeScope extends IsolatedScope {
  /// Membuat [IncomeScope] dengan kontainer induk [parentContainer].
  IncomeScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<IncomeSourceRepository>(parent<IncomeSourceRepository>())
      // Implementasi sungguhan dikawat di RootModule (ADR-0009) — lihat
      // catatan di root_module.dart.
      ..registerSingleton<IncomeWorklogGateway>(parent<IncomeWorklogGateway>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<IncomeSourceBloc>(
      () => IncomeSourceBloc(
        repository: c<IncomeSourceRepository>(),
        worklogGateway: c<IncomeWorklogGateway>(),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
