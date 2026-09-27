import 'package:di/di.dart';
import 'package:saldough/features/budget/domain/repositories/budget_template_repository.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_template_bloc.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup layar Template Anggaran (T-7.2). Hidup selama layar itu terbuka
/// saja, sama seperti `FreelanceScope`: `BudgetTemplateRepository` dan
/// `WalletRepository` tinggal di `RootModule` dan dibawa lewat [bridge].
/// Dompet hanya DIBACA — untuk pilihan dan nama dompet tujuan pos transfer.
final class BudgetTemplateScope extends IsolatedScope {
  /// Membuat [BudgetTemplateScope] dengan kontainer induk [parentContainer].
  BudgetTemplateScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<BudgetTemplateRepository>(parent<BudgetTemplateRepository>())
      ..registerSingleton<WalletRepository>(parent<WalletRepository>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<BudgetTemplateBloc>(
      () => BudgetTemplateBloc(
        templateRepository: c<BudgetTemplateRepository>(),
        walletRepository: c<WalletRepository>(),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
