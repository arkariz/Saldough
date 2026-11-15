import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:saldough/app/period_book/period_book_gate.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/features/period_book/data/period_book_memory_store_impl.dart';
import 'package:saldough/features/period_book/domain/repositories/period_book_memory_store.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Mendaftarkan ingatan dan gerbang Buku Periode di akar (ADR-045 §3.1, §3.5).
/// Dipanggil sesudah hak Plus dan repositori bersama terdaftar.
void registerPeriodBook(GetIt container) {
  container
    ..registerLazySingleton<PeriodBookMemoryStore>(
      () => PeriodBookMemoryStoreImpl(storage: container<KeyValueStorage>()),
    )
    ..registerLazySingleton<PeriodBookGate>(
      () => PeriodBookGate(
        entitlements: container<Entitlements>(),
        memory: container<PeriodBookMemoryStore>(),
        transactions: container<TransactionRepository>(),
        schedule: container<FinancialMonthPreferenceRepository>(),
      ),
    );
}
