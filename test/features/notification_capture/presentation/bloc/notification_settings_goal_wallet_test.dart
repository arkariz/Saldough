import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/domain/services/active_capture_inputs.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/fake_notification_capture_gateway.dart';

final class _GoalWallets implements TransferOnlyWallets {
  const _GoalWallets();

  @override
  Future<Set<String>> walletIds() async => const {'goal-1'};
}

/// Dompet milik tujuan hanya untuk transfer (ADR-048 §8.2a): tidak ditawarkan
/// di aturan dompet dan tidak ditebak untuk catatan dari notifikasi.
void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl wallets;

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    wallets = WalletRepositoryImpl(storage: storage);
    for (final id in ['bank', 'goal-1']) {
      await wallets.saveWallet(Wallet(id: id, name: id, iconKey: 'walletBank', initialBalance: 0, currentBalance: 0));
    }
  });

  test('aturan dompet tidak menawarkan dompet milik tujuan', () async {
    final bloc = NotificationSettingsBloc(
      gateway: FakeNotificationCaptureGateway(),
      store: NotificationCaptureStoreImpl(storage: storage),
      walletRepository: wallets,
      transferOnlyWallets: const _GoalWallets(),
    );
    addTearDown(bloc.close);
    bloc.add(const NotificationSettingsStarted());
    await pumpEventQueue();
    expect(bloc.state.wallets.map((w) => w.id), ['bank']);
  });

  test('penentu tidak pernah memakai dompet milik tujuan', () async {
    final active = await loadActiveWallets(wallets, exclude: const {'goal-1'});
    expect(active.map((w) => w.id), ['bank']);
    expect((await loadActiveWallets(wallets)).map((w) => w.id), ['bank', 'goal-1']);
  });
}
