// SPIKE T-26.9 (ADR-044 §3.5) -- mesin Dart tanpa layar untuk Catat dari
// notifikasi. Dinyalakan layanan pendengar saat mesin aplikasi tidak hidup.
// Hanya MEMBACA Hive; hasilnya dikirim ke native (notifikasi bertombol, jurnal).
// Bukan implementasi akhir: T-26.10/T-26.11 menggantikannya.
import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
// Hive.close() melepas kotak sebelum mesin dimatikan; hive_ce hanya dependensi transitif
// (lewat hive_storage) dan satu-satunya yang menyediakan penutupnya.
// ignore: depend_on_referenced_packages
import 'package:hive_ce/hive.dart';
import 'package:hive_storage/hive_storage.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/data/notification_rule_interpreter.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_resolver.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

const _channel = MethodChannel('tanukonomy/capture_worker');

/// Titik masuk mesin tanpa layar. Dipanggil native lewat
/// `DartEntrypoint(libraryUri, "captureWorkerMain")`.
@pragma('vm:entry-point')
Future<void> captureWorkerMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final clock = Stopwatch()..start();
  Future<void> log(String message) => _channel.invokeMethod<void>('log', '+${clock.elapsedMilliseconds}ms $message');
  try {
    final job = await _channel.invokeMapMethod<String, Object?>('job') ?? const {};
    await log('dart hidup, pekerjaan ${job['captureId']}');

    // 1. Hive: buka hanya untuk membaca, lalu tutup supaya UI bisa membukanya.
    final storage = await HiveKeyValueStorage.initialize(boxName: 'saldough_kv');
    await log('hive terbuka');
    final wallets = (await WalletRepositoryImpl(storage: storage).listWallets()).getOrElse((_) => const []);
    final categories = (await CategoryRepositoryImpl(storage: storage).listCategories()).getOrElse((_) => const []);
    final rules = (await RecurringRuleRepositoryImpl(storage: storage).listRules()).getOrElse((_) => const []);
    final inbox = (await NotificationCaptureStoreImpl(storage: storage).loadInbox()).getOrElse((_) => const []);
    await log(
      'dibaca: ${wallets.length} dompet, ${categories.length} kategori, ${rules.length} rutin, ${inbox.length} kartu',
    );

    // 2. Penentu bersama yang sama dengan aplikasi (ADR-044 §3.1).
    final ledger = TransactionRepositoryImpl(storage: storage);
    final posted = DateTime.fromMillisecondsSinceEpoch(
      (job['postedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );
    NotificationRuleInterpreter ruleInterpreter(CaptureLanguage language) =>
        NotificationRuleInterpreter(language: language, categories: () => ActiveCategories.notifier.value);
    final composer = NotificationDraftComposer(
      composer: CaptureDraftComposer(ruleInterpreterFor: ruleInterpreter, cloudInterpreter: _NoCloud()),
      ruleInterpreterFor: ruleInterpreter,
    );
    final resolver = CaptureResolver(
      composer: composer,
      ledgerAround: (date) async => [
        for (final offset in const [-1, 0, 1])
          ...(await ledger.listTransactionsInMonth(
            DateTime(date.year, date.month + offset),
          )).getOrElse((_) => const []),
      ],
    );
    final source = NotificationSource(
      packageName: job['packageName']! as String,
      appLabel: (job['appLabel'] as String?) ?? 'Aplikasi',
      keywords: const ['berhasil', 'masuk', 'transaksi'],
      walletId: wallets.firstOrNull?.id,
    );
    final resolved = await resolver.resolve(
      CapturedNotification(
        id: job['captureId']! as String,
        packageName: source.packageName,
        title: (job['title'] as String?) ?? '',
        body: (job['body'] as String?) ?? '',
        postedAt: posted,
      ),
      source: source,
      patterns: const [],
      wallets: wallets,
      categories: categories,
      currencyCode: 'IDR',
      languageCode: 'id',
      rules: rules,
    );
    await log(
      'diselesaikan: kelas ${resolved.cardClass.name}, nominal ${resolved.draft.amountSen}, dompet ${resolved.draft.walletId}',
    );

    // Uji tumpang tindih: tahan Hive terbuka agar UI bisa dibuka bersamaan.
    final hold = (job['holdMs'] as int?) ?? 0;
    if (hold > 0) {
      await log('menahan Hive terbuka $hold ms');
      await Future<void>.delayed(Duration(milliseconds: hold));
    }

    // 3. Lepas Hive sebelum mesin dimatikan; UI akan membukanya lagi.
    await Hive.close();
    await log('hive ditutup');

    await _channel.invokeMethod<void>('postActionable', {
      'captureId': job['captureId'],
      'title': resolved.draft.amountSen == null
          ? 'Nominal belum terbaca'
          : 'Rp${resolved.draft.amountSen! ~/ 100} · ${resolved.draft.note.isEmpty ? source.appLabel : resolved.draft.note}',
      'body': 'Spike: kelas ${resolved.cardClass.name}, ${wallets.length} dompet terbaca dari Hive',
    });
  } on Object catch (e, st) {
    await log('GAGAL $e\n$st');
  } finally {
    await _channel.invokeMethod<void>('done');
  }
}

/// Tanpa Gemini di mesin tanpa layar (spike): aturan saja.
final class _NoCloud implements TransactionInterpreter {
  @override
  Future<Either<Failure, InterpretedTransaction>> interpret(
    CaptureEvidence evidence,
    InterpretationContext context,
  ) async => left(const SystemFailure(code: FailureCode.unknown, message: 'tanpa cloud di mesin tanpa layar'));
}
