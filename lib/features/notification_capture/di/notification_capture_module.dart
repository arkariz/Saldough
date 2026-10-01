import 'dart:io';

import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/features/notification_capture/data/method_channel_notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/data/notification_rule_interpreter.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/features/notification_capture/domain/usecases/process_captured_notifications.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
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
      // Aturan notifikasi → Gemini bila ragu, sama dengan suara (ADR-032 §3.3).
      ..registerLazySingleton<NotificationDraftComposer>(
        () => NotificationDraftComposer(
          composer: CaptureDraftComposer(
            ruleInterpreterFor: rules,
            cloudInterpreter: FirebaseAiTransactionInterpreter(),
          ),
          ruleInterpreterFor: rules,
        ),
      )
      ..registerLazySingleton<ProcessCapturedNotifications>(
        () => ProcessCapturedNotifications(
          gateway: c<NotificationCaptureGateway>(),
          store: c<NotificationCaptureStore>(),
          composer: c<NotificationDraftComposer>(),
          recordTransaction: recordTransaction(),
          walletRepository: c<WalletRepository>(),
          transactionRepository: c<TransactionRepository>(),
          categories: () => ActiveCategories.notifier.value,
          currencyCode: () => ActiveCurrency.value.code,
          languageCode: () => ActiveLanguage.value.languageCode,
          changes: c<CaptureInboxChanges>(),
          sourceIcons: c.isRegistered<SourceIconRepository>() ? c<SourceIconRepository>() : null,
        ),
      )
      ..registerLazySingleton<CaptureInboxActions>(
        () => CaptureInboxActions(
          store: c<NotificationCaptureStore>(),
          recordTransaction: recordTransaction(),
          transactionRepository: c<TransactionRepository>(),
          composer: c<NotificationDraftComposer>(),
          walletRepository: c<WalletRepository>(),
          categories: () => ActiveCategories.notifier.value,
          currencyCode: () => ActiveCurrency.value.code,
          languageCode: () => ActiveLanguage.value.languageCode,
          changes: c<CaptureInboxChanges>(),
        ),
      );
  }
}
