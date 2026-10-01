import 'package:di/di.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/features/record/data/capture/system_speech_transcriber.dart';
import 'package:saldough/features/record/domain/capture/speech_transcriber.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/capture/bloc/voice_capture_bloc.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup dependensi fitur `record` (lembar CATAT). `WalletRepository` dan
/// `TransactionRepository` sudah didaftarkan di `RootModule` sebagai
/// repository bersama (ADR-0009 — keduanya dipakai fitur lain juga di fase
/// selanjutnya), jadi cukup dibawa lewat [bridge]. `RecomputeWalletBalances`
/// dan `RecordTransaction` adalah use case murni (bukan repository), jadi
/// diinstansiasi langsung di [register], bukan diambil dari kontainer induk.
final class RecordScope extends IsolatedScope {
  /// Membuat [RecordScope] dengan kontainer induk [parentContainer].
  RecordScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>())
      ..registerSingleton<LedgerChanges>(parent<LedgerChanges>())
      ..registerSingleton<BudgetItemCatalog>(parent<BudgetItemCatalog>())
      ..registerSingleton<CategoryRepository>(parent<CategoryRepository>());
    // Opsional: kontainer induk yang tidak menyediakannya (mis. uji layar
    // lain) berarti suara dibuka tanpa bertanya bahasa.
    if (parent.isRegistered<SpeechLanguagePrompt>()) {
      c.registerSingleton<SpeechLanguagePrompt>(parent<SpeechLanguagePrompt>());
    }
  }

  @override
  void register(GetIt c) {
    c
      // Catat Cerdas (ADR-027, ADR-029): penangkap suara dan penyusun draf.
      // Aturan per paket bahasa; cloud (Firebase AI, T-11.7) hanya bila
      // draf aturan ragu atau bahasanya tanpa paket.
      ..registerLazySingleton<SpeechTranscriber>(SystemSpeechTranscriber.new)
      ..registerLazySingleton<CaptureDraftComposer>(
        () => CaptureDraftComposer(
          ruleInterpreterFor: (language) => RuleBasedTransactionInterpreter(
            language: language,
            categories: () => ActiveCategories.notifier.value,
          ),
          cloudInterpreter: FirebaseAiTransactionInterpreter(),
        ),
      )
      ..registerLazySingleton<RecordBloc>(
        () => RecordBloc(
          walletRepository: c<WalletRepository>(),
          transactionRepository: c<TransactionRepository>(),
          budgetItemCatalog: c<BudgetItemCatalog>(),
          createCategory: CreateCategory(repository: c<CategoryRepository>()),
          voiceCaptureFactory: () =>
              VoiceCaptureBloc(transcriber: c<SpeechTranscriber>(), composer: c<CaptureDraftComposer>()),
          speechLanguagePrompt: c.isRegistered<SpeechLanguagePrompt>() ? c<SpeechLanguagePrompt>() : null,
          recordTransaction: RecordTransaction(
            ledgerChanges: c<LedgerChanges>(),
            transactionRepository: c<TransactionRepository>(),
            recomputeWalletBalances: RecomputeWalletBalances(
              walletRepository: c<WalletRepository>(),
              transactionRepository: c<TransactionRepository>(),
            ),
          ),
        ),
        dispose: (bloc) => bloc.close(),
      );
  }
}
