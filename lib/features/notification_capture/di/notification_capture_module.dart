import 'dart:io';

import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/features/notification_capture/data/approved_shape_store_impl.dart';
import 'package:saldough/features/notification_capture/data/merchant_memory_store_impl.dart';
import 'package:saldough/features/notification_capture/data/method_channel_notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/data/negative_shape_store_impl.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/data/notification_rule_interpreter.dart';
import 'package:saldough/features/notification_capture/domain/repositories/merchant_memory_store.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/approved_shapes.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_finalizer.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/domain/services/negative_shapes.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/features/notification_capture/domain/services/store_backed_merchant_memory.dart';
import 'package:saldough/features/notification_capture/domain/usecases/apply_capture_journal.dart';
import 'package:saldough/features/notification_capture/domain/usecases/capture_inbox_actions.dart';
import 'package:saldough/features/notification_capture/domain/usecases/process_captured_notifications.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Registrasi Catat dari notifikasi (ADR-032) di kontainer **akar**:
/// pemrosesan terjadi dari mana saja (buka aplikasi, resume, event native,
/// ketukan pengingat), tidak terikat satu layar. Dipanggil `RootModule`
/// sesudah repository bersama terdaftar.
abstract final class NotificationCaptureModule {
  NotificationCaptureModule._();

  /// Mendaftarkan gateway, penyimpanan, penyusun, pemroses, dan aksi kotak
  /// masuk. [gateway] untuk uji; bawaannya kanal Android, atau tidak
  /// didukung di platform lain.
  static void register(GetIt c, {NotificationCaptureGateway? gateway}) {
    final resolvedGateway =
        gateway ??
        (Platform.isAndroid
            ? MethodChannelNotificationCaptureGateway()
            : const UnsupportedNotificationCaptureGateway());
    NotificationRuleInterpreter rules(CaptureLanguage language) =>
        NotificationRuleInterpreter(language: language, categories: () => ActiveCategories.notifier.value);
    RecordTransaction recordTransaction() => RecordTransaction(
      ledgerChanges: c<LedgerChanges>(),
      transactionRepository: c<TransactionRepository>(),
      recomputeWalletBalances: RecomputeWalletBalances(
        walletRepository: c<WalletRepository>(),
        transactionRepository: c<TransactionRepository>(),
      ),
    );
    c
      ..registerSingleton<NotificationCaptureGateway>(resolvedGateway)
      ..registerLazySingleton<NotificationCaptureStore>(
        () => NotificationCaptureStoreImpl(storage: c<KeyValueStorage>()),
      )
      ..registerLazySingleton<CaptureInboxChanges>(CaptureInboxChanges.new)
      ..registerLazySingleton<MerchantMemoryStore>(() => MerchantMemoryStoreImpl(storage: c<KeyValueStorage>()))
      ..registerLazySingleton<ApprovedShapeStore>(() => ApprovedShapeStoreImpl(storage: c<KeyValueStorage>()))
      ..registerLazySingleton<StoreBackedApprovedShapes>(() => StoreBackedApprovedShapes(c<ApprovedShapeStore>()))
      ..registerLazySingleton<NegativeShapeStore>(() => NegativeShapeStoreImpl(storage: c<KeyValueStorage>()))
      ..registerLazySingleton<StoreBackedNegativeShapes>(() => StoreBackedNegativeShapes(c<NegativeShapeStore>()))
      ..registerLazySingleton<StoreBackedMerchantMemory>(() => StoreBackedMerchantMemory(c<MerchantMemoryStore>()))
      // Aturan notifikasi → Gemini bila ragu, sama dengan suara (ADR-032 §3.3).
      ..registerLazySingleton<NotificationDraftComposer>(
        () => NotificationDraftComposer(
          composer: CaptureDraftComposer(
            ruleInterpreterFor: rules,
            // Jatah tafsir cerdas bersama suara (ADR-041 §3.7, KT-P14).
            cloudInterpreter: c.isRegistered<Entitlements>()
                ? QuotaGatedInterpreter(inner: FirebaseAiTransactionInterpreter(), entitlements: c<Entitlements>())
                : FirebaseAiTransactionInterpreter(),
          ),
        ),
      )
      ..registerLazySingleton<ProcessCapturedNotifications>(
        () => ProcessCapturedNotifications(
          gateway: c<NotificationCaptureGateway>(),
          store: c<NotificationCaptureStore>(),
          composer: c<NotificationDraftComposer>(),
          memory: c<StoreBackedMerchantMemory>(),
          negativeShapes: c<StoreBackedNegativeShapes>(),
          approvedShapes: c<StoreBackedApprovedShapes>(),
          recordTransaction: recordTransaction(),
          walletRepository: c<WalletRepository>(),
          transactionRepository: c<TransactionRepository>(),
          categories: () => ActiveCategories.notifier.value,
          currencyCode: () => ActiveCurrency.value.code,
          languageCode: () => ActiveLanguage.value.languageCode,
          changes: c<CaptureInboxChanges>(),
          sourceIcons: c.isRegistered<SourceIconRepository>() ? c<SourceIconRepository>() : null,
          recurringRules: c.isRegistered<RecurringRuleRepository>() ? c<RecurringRuleRepository>() : null,
          matchLog: c.isRegistered<RecurrenceMatchLogRepository>() ? c<RecurrenceMatchLogRepository>() : null,
          recurringChanges: c.isRegistered<RecurringChanges>() ? c<RecurringChanges>() : null,
          finalizer: CaptureFinalizer(budgetItems: c.isRegistered<BudgetItemCatalog>() ? c<BudgetItemCatalog>() : null),
          // Gerbang Plus (ADR-041 §3.8): Gratis hanya sumber pertama dan tinjau semua.
          isPlus: () => ActivePlan.isPlus,
          freeSources: () => ActivePlan.limits.value.freeNotificationSources,
        ),
      )
      // Menerapkan jurnal notifikasi bertindak saat aplikasi dibuka (ADR-044 §3.5).
      ..registerLazySingleton<ApplyCaptureJournal>(
        () => ApplyCaptureJournal(
          gateway: c<NotificationCaptureGateway>(),
          store: c<NotificationCaptureStore>(),
          recordTransaction: recordTransaction(),
          transactionRepository: c<TransactionRepository>(),
          walletRepository: c<WalletRepository>(),
          sourceIcons: c.isRegistered<SourceIconRepository>() ? c<SourceIconRepository>() : null,
          approvedShapes: c<StoreBackedApprovedShapes>(),
          recurringRules: c.isRegistered<RecurringRuleRepository>() ? c<RecurringRuleRepository>() : null,
          finalizer: CaptureFinalizer(budgetItems: c.isRegistered<BudgetItemCatalog>() ? c<BudgetItemCatalog>() : null),
          changes: c<CaptureInboxChanges>(),
          recurringChanges: c.isRegistered<RecurringChanges>() ? c<RecurringChanges>() : null,
        ),
      )
      ..registerLazySingleton<CaptureInboxActions>(
        () => CaptureInboxActions(
          store: c<NotificationCaptureStore>(),
          merchantMemory: c<StoreBackedMerchantMemory>(),
          negativeShapes: c<StoreBackedNegativeShapes>(),
          approvedShapes: c<StoreBackedApprovedShapes>(),
          budgetItems: c.isRegistered<BudgetItemCatalog>() ? c<BudgetItemCatalog>() : null,
          recordTransaction: recordTransaction(),
          transactionRepository: c<TransactionRepository>(),
          composer: c<NotificationDraftComposer>(),
          walletRepository: c<WalletRepository>(),
          categories: () => ActiveCategories.notifier.value,
          currencyCode: () => ActiveCurrency.value.code,
          languageCode: () => ActiveLanguage.value.languageCode,
          changes: c<CaptureInboxChanges>(),
          recurringRules: c.isRegistered<RecurringRuleRepository>() ? c<RecurringRuleRepository>() : null,
          matchLog: c.isRegistered<RecurrenceMatchLogRepository>() ? c<RecurrenceMatchLogRepository>() : null,
          recurringChanges: c.isRegistered<RecurringChanges>() ? c<RecurringChanges>() : null,
          finalizer: CaptureFinalizer(budgetItems: c.isRegistered<BudgetItemCatalog>() ? c<BudgetItemCatalog>() : null),
        ),
      );
  }
}
