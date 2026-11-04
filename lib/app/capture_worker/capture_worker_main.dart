// Mesin Dart tanpa layar untuk Catat dari notifikasi (ADR-044 §3.5, spike
// T-26.9, T-26.10). Dinyalakan layanan pendengar saat mesin aplikasi tidak
// hidup. Hanya MEMBACA Hive; hasilnya (notifikasi bertombol dan muatan jurnal)
// dikirim ke native, dan aplikasi yang menerapkannya ke Hive saat dibuka
// (`ApplyCaptureJournal`).
import 'dart:async';
import 'dart:convert';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
// Hive.close() melepas kotak sebelum mesin dimatikan; hive_ce hanya dependensi transitif
// (lewat hive_storage) dan satu-satunya yang menyediakan penutupnya.
// ignore: depend_on_referenced_packages
import 'package:hive_ce/hive.dart';
import 'package:hive_storage/hive_storage.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/data/notification_rule_interpreter.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/services/active_capture_inputs.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_card_class.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_codec.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_resolver.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/features/recurring/data/local_notification_reminder_scheduler.dart';
import 'package:saldough/features/recurring/data/reminder_settings_repository_impl.dart';
import 'package:saldough/features/recurring/domain/resync_reminders_for_capture.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

const _channel = MethodChannel('tanukonomy/capture_worker');

/// Titik masuk mesin tanpa layar. Dipanggil native lewat
/// `DartEntrypoint(libraryUri, "captureWorkerMain")`; perpustakaan ini harus
/// terjangkau dari `main.dart` supaya ikut dalam kernel/AOT.
@pragma('vm:entry-point')
Future<void> captureWorkerMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final clock = Stopwatch()..start();
  Future<void> log(String message) => _channel.invokeMethod<void>('log', '+${clock.elapsedMilliseconds}ms $message');
  final handled = <String>[];
  try {
    final pending = await _channel.invokeListMethod<Map<Object?, Object?>>('pending') ?? const [];
    await log('dart hidup, ${pending.length} tangkapan menunggu');
    final resync = await _channel.invokeMethod<bool>('resyncPending') ?? false;
    if (pending.isNotEmpty || resync) {
      final storage = await HiveKeyValueStorage.initialize(boxName: 'saldough_kv');
      try {
        await _prepareLocale(storage);
        if (pending.isNotEmpty) await _drain(storage, pending, handled, log);
        if (resync) await _resyncReminders(storage, log);
        final hold = await _channel.invokeMethod<int>('hold') ?? 0;
        if (hold > 0) {
          await log('menahan Hive terbuka $hold ms');
          await Future<void>.delayed(Duration(milliseconds: hold));
        }
      } finally {
        // Lepas Hive sebelum mesin dimatikan; aplikasi akan membukanya lagi.
        await Hive.close();
        await log('hive ditutup');
      }
    }
  } on Object catch (e, st) {
    await log('GAGAL $e\n$st');
  } finally {
    await _channel.invokeMethod<void>('done', handled);
  }
}

/// Bahasa dan mata uang pilihan pengguna, seperti bootstrap aplikasi: teks
/// notifikasi dan nominalnya harus sama dengan yang dilihat di aplikasi.
Future<void> _prepareLocale(HiveKeyValueStorage storage) async {
  final savedLanguage = (await LanguagePreferenceRepositoryImpl(storage: storage).load()).getOrElse((_) => null);
  if (savedLanguage != null) {
    await LocaleSettings.setLocale(savedLanguage);
  } else {
    await LocaleSettings.useDeviceLocale();
  }
  ActiveLanguage.notifier.value = LocaleSettings.currentLocale;
  ActiveCurrency.notifier.value = (await CurrencyPreferenceRepositoryImpl(storage: storage).load()).getOrElse(
    (_) => AppCurrency.idr,
  );
}

/// Menyesuaikan pengingat rutin dengan keputusan Catat di jurnal (T-26.12):
/// kemunculan yang sudah dicatat lewat tombol tidak lagi diingatkan; Batalkan
/// memulihkannya. Hanya jadwal, tidak menulis Hive.
Future<void> _resyncReminders(HiveKeyValueStorage storage, Future<void> Function(String) log) async {
  final entries = await _channel.invokeListMethod<Map<Object?, Object?>>('journalEntries') ?? const [];
  final recorded = <({String ruleId, DateTime date})>[];
  for (final entry in entries) {
    if (entry['decision'] != 'record') continue;
    try {
      final payload = jsonDecode(entry['payload']! as String) as Map<String, Object?>;
      final match = payload['match'];
      if (match is! Map) continue;
      final date = DateTime.tryParse('${match['date']}');
      if (date != null) recorded.add((ruleId: '${match['ruleId']}', date: date));
    } on Object {
      continue;
    }
  }
  final changed = await ResyncRemindersForCapture(
    scheduler: LocalNotificationReminderScheduler(),
    settings: ReminderSettingsRepositoryImpl(storage: storage),
    rules: RecurringRuleRepositoryImpl(storage: storage),
    transactions: TransactionRepositoryImpl(storage: storage),
  )(recorded);
  await log('pengingat rutin disesuaikan: ${recorded.length} kemunculan tercatat di jurnal, diubah=$changed');
}

Future<void> _drain(
  HiveKeyValueStorage storage,
  List<Map<Object?, Object?>> pending,
  List<String> handled,
  Future<void> Function(String) log,
) async {
  final store = NotificationCaptureStoreImpl(storage: storage);
  final settings = (await store.loadSettings()).getOrElse((_) => const NotificationCaptureSettings());
  final wallets = await loadActiveWallets(WalletRepositoryImpl(storage: storage));
  final categories = (await CategoryRepositoryImpl(storage: storage).listCategories()).getOrElse((_) => const []);
  final rules = (await RecurringRuleRepositoryImpl(storage: storage).listRules()).getOrElse((_) => const []);
  final patterns = await loadActivePatterns(store, settings);
  final processed = (await store.loadProcessedIds()).getOrElse((_) => {});
  final journaled = {...?(await _channel.invokeListMethod<String>('journalIds'))};
  final plan = await _channel.invokeMapMethod<String, Object?>('plan');
  final isPlus = plan?['isPlus'] == true;
  await log(
    'dibaca: ${wallets.length} dompet, ${categories.length} kategori, ${rules.length} rutin, '
    '${settings.sources.length} sumber, plus=$isPlus',
  );

  final ledger = TransactionRepositoryImpl(storage: storage);
  NotificationRuleInterpreter ruleInterpreter(CaptureLanguage language) =>
      NotificationRuleInterpreter(language: language, categories: () => ActiveCategories.notifier.value);
  final resolver = CaptureResolver(
    composer: NotificationDraftComposer(
      composer: CaptureDraftComposer(ruleInterpreterFor: ruleInterpreter, cloudInterpreter: _NoCloud()),
      ruleInterpreterFor: ruleInterpreter,
    ),
    ledgerAround: (date) async => [
      for (final offset in const [-1, 0, 1])
        ...(await ledger.listTransactionsInMonth(DateTime(date.year, date.month + offset))).getOrElse((_) => const []),
    ],
  );
  // Gratis: hanya sumber pertama di daftar yang diproses (sama dengan aplikasi).
  // Tanpa sumber tersimpan tidak ada yang dibatasi (tangkapan tanpa sumber dilewati di bawah).
  final allowed = isPlus || settings.sources.isEmpty
      ? null
      : {for (final s in settings.sources.take(EntitlementLimits.defaults.freeNotificationSources)) s.packageName};

  for (final item in pending) {
    final id = item['id']! as String;
    handled.add(id);
    // Sudah diproses aplikasi, atau sudah punya notifikasi dari putaran sebelumnya.
    if (processed.containsKey(id) || journaled.contains(id)) continue;
    final packageName = item['packageName']! as String;
    if (allowed != null && !allowed.contains(packageName)) continue;
    final source = settings.activeSource(packageName) ?? _debugSource(packageName, wallets);
    if (source == null) continue;

    try {
      final notification = CapturedNotification(
        id: id,
        packageName: packageName,
        title: (item['title'] as String?) ?? '',
        body: (item['body'] as String?) ?? '',
        postedAt: DateTime.fromMillisecondsSinceEpoch((item['postedAt'] as num?)?.toInt() ?? 0),
      );
      final resolved = await resolver.resolve(
        notification,
        source: source,
        patterns: patterns,
        wallets: wallets,
        categories: categories,
        currencyCode: ActiveCurrency.value.code,
        languageCode: LocaleSettings.currentLocale.languageCode,
        rules: rules,
      );
      final amount = resolved.draft.amountSen;
      await log(
        'diselesaikan $id: kelas ${resolved.cardClass.name}, nominal $amount, dompet ${resolved.draft.walletId}',
      );

      // Tombol Catat hanya untuk Plus dan draf lengkap tanpa tebakan; selain itu
      // notifikasi membuka CATAT terisi (pengingat biasa).
      final withActions = isPlus && resolved.cardClass != CaptureCardClass.needsInput;
      final entry = CaptureInboxEntry(
        id: id,
        packageName: packageName,
        appLabel: source.appLabel,
        text: notification.text,
        capturedAt: notification.postedAt,
        draft: resolved.draft,
        possibleDuplicate: resolved.existing != null,
        patternId: resolved.composed?.pattern?.id,
      );
      final match = resolved.plan.match;
      final texts = t.notificationCapture;
      await _channel.invokeMethod<void>('postActionable', {
        'captureId': id,
        'title': texts.reminderReviewTitle(
          amount: amount == null ? texts.amountUnknown : AppMoneyFormatter.format(amount),
          app: source.appLabel,
        ),
        'body': resolved.draft.note.trim().isEmpty ? texts.reminderReviewBody : resolved.draft.note,
        'icon': item['icon'],
        'payload': withActions
            ? jsonEncode({
                'entry': captureInboxEntryToJson(entry),
                'match': ?(match == null
                    ? null
                    : {'ruleId': match.rule.id, 'date': match.date.toIso8601String(), 'exact': match.exact}),
              })
            : null,
      });
    } on Object catch (e, st) {
      // Satu tangkapan rusak tidak menghentikan yang lain; aplikasi memprosesnya dari antrean.
      await log('GAGAL $id: $e\n$st');
    }
  }
}

/// Sumber uji untuk build non-produk bila setelan Dart belum memuat sumbernya
/// (uji perangkat tanpa menyelesaikan Mulai cepat). Build produk tidak pernah memakainya.
NotificationSource? _debugSource(String packageName, List<Wallet> wallets) {
  if (const bool.fromEnvironment('dart.vm.product')) return null;
  return NotificationSource(
    packageName: packageName,
    appLabel: 'Aplikasi Uji',
    keywords: const ['berhasil', 'masuk', 'transaksi'],
    walletId: wallets.firstOrNull?.id,
  );
}

/// Tanpa Gemini di mesin tanpa layar: aturan saja.
final class _NoCloud implements TransactionInterpreter {
  @override
  Future<Either<Failure, InterpretedTransaction>> interpret(
    CaptureEvidence evidence,
    InterpretationContext context,
  ) async => left(const SystemFailure(code: FailureCode.unknown, message: 'tanpa cloud di mesin tanpa layar'));
}
