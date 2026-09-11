import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:saldough/features/worklog/data/repositories/worklog_repository_impl.dart';
import 'package:saldough/features/worklog/domain/repositories/cycle_income_writer.dart';
import 'package:saldough/features/worklog/domain/repositories/worklog_repository.dart';
import 'package:saldough/features/worklog/domain/usecases/close_billing_book.dart';
import 'package:saldough/features/worklog/domain/usecases/inject_net_pay.dart';
import 'package:saldough/features/worklog/presentation/bloc/worklog_bloc.dart';
import 'package:saldough/shared/income/income.dart';

/// Lingkup dependensi fitur `worklog`. Membawa [KeyValueStorage] dan
/// [IncomeSourceRepository] dari induk (keduanya sudah root-level — lihat
/// ADR-0009), dan [CycleIncomeWriter] yang juga dikawat di `RootModule`
/// (port milik `worklog` sendiri, diimplementasikan `features/cycle/data/` —
/// lihat catatan revisi ADR-0009).
final class WorklogScope extends IsolatedScope {
  /// Membuat [WorklogScope] dengan kontainer induk [parentContainer].
  WorklogScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<KeyValueStorage>(parent<KeyValueStorage>())
      ..registerSingleton<IncomeSourceRepository>(parent<IncomeSourceRepository>())
      ..registerSingleton<CycleIncomeWriter>(parent<CycleIncomeWriter>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<WorklogRepository>(
      () => WorklogRepositoryImpl(storage: c<KeyValueStorage>()),
    );
    c.registerLazySingleton<CloseBillingBook>(
      () => CloseBillingBook(repository: c<WorklogRepository>()),
    );
    c.registerLazySingleton<InjectNetPay>(
      () => InjectNetPay(writer: c<CycleIncomeWriter>(), repository: c<WorklogRepository>()),
    );
    c.registerLazySingleton<WorklogBloc>(
      () => WorklogBloc(
        sourceRepository: c<IncomeSourceRepository>(),
        worklogRepository: c<WorklogRepository>(),
        closeBillingBook: c<CloseBillingBook>(),
        injectNetPay: c<InjectNetPay>(),
        cycleIncomeWriter: c<CycleIncomeWriter>(),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
