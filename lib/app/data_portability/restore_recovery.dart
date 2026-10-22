import 'dart:developer' as developer;

import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:saldough/app/data_portability/app_reboot.dart';
import 'package:saldough/core/foundation/analytics/app_bootstrap_firebase.dart';
import 'package:saldough/features/data_portability/data/restore_engine.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Hasil pemeriksaan jurnal pemulihan yang dijalankan saat penyimpanan dibuka
/// (`RootModule`), sebelum repositori mana pun dibuat.
final class RestoreRecoveryOutcome {
  /// Membuat [RestoreRecoveryOutcome].
  const RestoreRecoveryOutcome(this.outcome);

  /// Hasil [RestoreEngine.recover].
  final RecoveryOutcome outcome;
}

/// Memeriksa jurnal pemulihan; dipanggil `RootModule` saat penyimpanan dibuka
/// (ADR-040 §3.4). Galat tidak boleh menghalangi aplikasi terbuka: dilaporkan,
/// jurnal tetap ada, dan dicoba lagi pada pembukaan berikutnya.
Future<RecoveryOutcome> recoverRestoreJournal(RestoreEngine engine) async {
  try {
    return await engine.recover();
  } on Object catch (e, st) {
    developer.log('Pemeriksaan jurnal pemulihan gagal', error: e, stackTrace: st, name: 'RestoreEngine');
    AppBootstrap.recordNonFatal(e, reason: 'RestoreEngine.recover');
    return RecoveryOutcome.none;
  }
}

/// Menuntaskan pemulihan sesudah kontainer DI siap (ADR-040 §3.4 langkah 6):
/// menghitung ulang saldo dompet (R-6) lalu membersihkan. Idempoten; bila
/// terputus, diulang pada pembukaan berikutnya.
Future<void> finishRestoreIfNeeded(GetIt container) async {
  if (container<RestoreRecoveryOutcome>().outcome != RecoveryOutcome.needsFinalize) return;
  try {
    final report = await container<RestoreEngine>().finalize(() async {
      final result = await RecomputeWalletBalances(
        walletRepository: container<WalletRepository>(),
        transactionRepository: container<TransactionRepository>(),
      )();
      if (result case Left(value: final failure)) {
        throw StateError('Hitung ulang saldo dompet gagal: ${failure.message}');
      }
    });
    AppReboot.report.value = report;
  } on Object catch (e, st) {
    developer.log('Finalisasi pemulihan gagal, dicoba lagi nanti', error: e, stackTrace: st, name: 'RestoreEngine');
    AppBootstrap.recordNonFatal(e, reason: 'RestoreEngine.finalize');
  }
}
