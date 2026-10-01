import 'package:di/di.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/domain/usecases/process_captured_notifications.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/capture_inbox_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Lingkup layar setelan dan kotak masuk Catat dari notifikasi (ADR-032).
/// Gateway, penyimpanan, dan aksi kotak masuk singleton akar
/// (`NotificationCaptureModule`), dibawa lewat [bridge].
final class NotificationCaptureScope extends IsolatedScope {
  /// Membuat [NotificationCaptureScope] dengan kontainer induk [parentContainer].
  NotificationCaptureScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c
      ..registerSingleton<NotificationCaptureGateway>(parent<NotificationCaptureGateway>())
      ..registerSingleton<NotificationCaptureStore>(parent<NotificationCaptureStore>())
      ..registerSingleton<CaptureInboxActions>(parent<CaptureInboxActions>())
      ..registerSingleton<CaptureInboxChanges>(parent<CaptureInboxChanges>())
      ..registerSingleton<WalletRepository>(parent<WalletRepository>())
      ..registerSingleton<CategoryRepository>(parent<CategoryRepository>())
      ..registerSingleton<TransactionRepository>(parent<TransactionRepository>());
  }

  @override
  void register(GetIt c) {
    c
      ..registerLazySingleton<NotificationSettingsBloc>(
        () => NotificationSettingsBloc(
          gateway: c<NotificationCaptureGateway>(),
          store: c<NotificationCaptureStore>(),
          walletRepository: c<WalletRepository>(),
        ),
        dispose: (bloc) => bloc.close(),
      )
      ..registerLazySingleton<CaptureInboxBloc>(
        () => CaptureInboxBloc(
          store: c<NotificationCaptureStore>(),
          actions: c<CaptureInboxActions>(),
          transactionRepository: c<TransactionRepository>(),
          changes: c<CaptureInboxChanges>(),
        ),
        dispose: (bloc) => bloc.close(),
      );
  }
}
