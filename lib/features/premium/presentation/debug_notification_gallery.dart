// SEMENTARA -- galeri debug Catat dari notifikasi. JANGAN DI-COMMIT.
// Hapus berkas ini dan dua baris DEBUG-SEMENTARA di account_page.dart.
// Penyimpanan di memori, hari ini dikunci 4 Nov 2026. Rute lain tidak terpasang:
// Catat / Tetap catat / Atur membuka CATAT atau setelan lewat rute dan akan
// gagal di sini; yang bisa dicoba: pilih aplikasi, Sudah tutup, Abaikan,
// Tautkan, Batalkan, tab Otomatis, dan setelan pengiriman (Plus bawaan nyala,
// Gratis mati). Notifikasi bertombol dan Catat semua ada di perangkat, bukan
// di galeri: pakai DEBUG-SEMENTARA-fase26.sh.
import 'dart:async';
import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';
import 'package:saldough/features/notification_capture/data/notification_rule_interpreter.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_journal_record.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/features/notification_capture/domain/usecases/capture_inbox_actions.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/capture_inbox_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/pages/capture_inbox_page.dart';
import 'package:saldough/features/notification_capture/presentation/pages/notification_settings_page.dart';
import 'package:saldough/features/notification_capture/presentation/pages/quick_start_page.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

const _apps = [
  InstalledApp(packageName: 'id.contoh.brimo', label: 'BRImo'),
  InstalledApp(packageName: 'id.contoh.bca', label: 'BCA mobile'),
  InstalledApp(packageName: 'id.contoh.jago', label: 'Jago'),
  InstalledApp(packageName: 'id.contoh.gopay', label: 'GoPay'),
  InstalledApp(packageName: 'id.contoh.ovo', label: 'OVO'),
  InstalledApp(packageName: 'id.contoh.dana', label: 'DANA'),
  InstalledApp(packageName: 'id.contoh.kalkulator', label: 'Kalkulator'),
  InstalledApp(packageName: 'id.contoh.kamera', label: 'Kamera'),
  InstalledApp(packageName: 'id.contoh.chrome', label: 'Chrome'),
  InstalledApp(packageName: 'id.contoh.whatsapp', label: 'WhatsApp'),
  InstalledApp(packageName: 'id.contoh.spotify', label: 'Spotify'),
  InstalledApp(packageName: 'id.contoh.tokopedia', label: 'Tokopedia'),
  InstalledApp(
    packageName: 'id.contoh.aplikasi.dengan.nama.paket.yang.sangat.panjang',
    label: 'Aplikasi Bernama Sangat Panjang Sekali',
  ),
];

final class _Gateway implements NotificationCaptureGateway {
  _Gateway({this.loadFails = false, this.access = false});
  final bool loadFails;
  bool access;

  @override
  bool get isSupported => true;
  @override
  Future<Either<Failure, List<CapturedNotification>>> pending() async => right(const []);
  @override
  Future<Either<Failure, Unit>> acknowledge(List<String> ids) async => right(unit);
  @override
  Stream<void> get captured => const Stream.empty();
  @override
  Stream<String> get reminderTaps => const Stream.empty();
  @override
  Future<String?> takeLaunchReminderTap() async => null;
  @override
  Future<bool> isAccessGranted() async => access;
  @override
  Future<void> openAccessSettings() async => access = true;
  @override
  Future<bool> canPostReminders() async => true;
  @override
  Future<bool> requestReminderPermission() async => true;
  @override
  Future<Either<Failure, Unit>> configure({
    required bool enabled,
    required List<NotificationSource> sources,
    required bool remindWhenClosed,
    required ReminderTexts texts,
    bool saveSamples = false,
    bool autoNotify = false,
  }) async => right(unit);
  @override
  Future<void> showReminder({
    required String captureId,
    required String title,
    required String body,
    Uint8List? icon,
  }) async {}
  @override
  Future<Either<Failure, List<InstalledApp>>> installedApps() async =>
      loadFails ? left(const SystemFailure(code: FailureCode.unknown, message: 'debug')) : right(_apps);
  @override
  Future<List<CapturedNotification>> debugSamples() async => const [];
  @override
  Future<List<CapturedNotification>> samples(String packageName) async => const [];
  @override
  Future<void> clearSamples({String? packageName}) async {}
  @override
  Future<List<CaptureJournalRecord>> journal() async => const [];
  @override
  Future<void> acknowledgeJournal(List<String> ids) async {}
  @override
  Future<void> cancelActionable() async {}
  @override
  Future<void> syncPlan({required bool isPlus, DateTime? until}) async {}
}

final _at = DateTime(2026, 11, 4, 10);

CaptureInboxEntry _entry(
  String id, {
  required String app,
  required String text,
  int? amount,
  String note = '',
  CaptureReviewReason? reason = CaptureReviewReason.autoRecordOff,
  String? category,
  bool flagged = false,
  Duration ago = Duration.zero,
}) => CaptureInboxEntry(
  id: id,
  packageName: 'id.contoh.${app.toLowerCase()}',
  appLabel: app,
  text: text,
  capturedAt: _at.subtract(ago),
  draft: RecordDraft(
    kind: DraftKind.expense,
    amountSen: amount,
    walletId: amount == null ? null : 'bca',
    categoryId: category,
    note: note,
    date: _at.subtract(ago),
    issues: amount == null ? {DraftIssue.amountMissing} : const {},
  ),
  reviewReason: reason,
  possibleDuplicate: flagged,
);

Future<(CaptureInboxBloc, NotificationSettingsBloc)> _seed({required bool empty, bool access = false}) async {
  final storage = InMemoryKeyValueStorage();
  final store = NotificationCaptureStoreImpl(storage: storage);
  final wallets = WalletRepositoryImpl(storage: storage);
  final ledger = TransactionRepositoryImpl(storage: storage);
  final rules = RecurringRuleRepositoryImpl(storage: storage);
  final ledgerChanges = LedgerChanges();
  final gateway = _Gateway(access: access);
  // Fitur menyala: tanpa izin, kotak masuk menampilkan banner Izinkan.
  await store.saveSettings(const NotificationCaptureSettings(enabled: true));
  await wallets.saveWallet(
    const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 650000000),
  );
  if (!empty) {
    await rules.saveRule(
      RecurringRule(
        id: 'netflix',
        kind: RecurringKind.expense,
        amount: 6500000,
        walletId: 'bca',
        note: 'Netflix',
        schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 10, 4)),
      ),
    );
    await rules.saveRule(
      RecurringRule(
        id: 'spotify',
        kind: RecurringKind.expense,
        amount: 5400000,
        walletId: 'bca',
        note: 'Spotify',
        categoryId: 'builtin.entertainment',
        schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 10, 4)),
      ),
    );
    // Catatan manual yang cocok dengan kartu 3 dan 4 (tanpa tautan).
    await ledger.saveTransaction(
      ExpenseTransaction(id: 'm1', date: _at, amount: 4500000, note: 'Kopi pagi', walletId: 'bca'),
    );
    await ledger.saveTransaction(
      ExpenseTransaction(id: 'm2', date: _at, amount: 6500000, note: 'Netflix', walletId: 'bca'),
    );
    await store.saveInbox([
      _entry(
        '1',
        app: 'BRImo',
        text: 'Pembayaran Rp18.500 ke WARUNG BU TINI berhasil',
        amount: 1850000,
        note: 'WARUNG BU TINI',
      ),
      _entry(
        '2',
        app: 'GoPay',
        text: 'Transaksi berhasil di Tokopedia. Cek detail di aplikasi.',
        reason: CaptureReviewReason.amountUnclear,
        ago: const Duration(minutes: 40),
      ),
      _entry(
        '3',
        app: 'BCA',
        text: 'Pembayaran Rp45.000 ke STARBUCKS berhasil',
        amount: 4500000,
        note: 'STARBUCKS',
        ago: const Duration(hours: 1),
      ),
      _entry(
        '4',
        app: 'Jago',
        text: 'Pembayaran Rp65.000 ke NETFLIX.COM berhasil',
        amount: 6500000,
        note: 'NETFLIX.COM',
        reason: null,
        ago: const Duration(hours: 2),
      ),
      // Dikenali: dompet, nominal, dan kategori terbaca -> satu ketuk (Plus).
      _entry(
        '6',
        app: 'OVO',
        text: 'Pembayaran Rp32.000 ke KOPI KENANGAN berhasil',
        amount: 3200000,
        note: 'KOPI KENANGAN',
        category: 'builtin.food',
        ago: const Duration(hours: 3),
      ),
      _entry(
        '7',
        app: 'GoPay',
        text: 'Pembayaran Rp21.000 ke GOJEK berhasil',
        amount: 2100000,
        note: 'GOJEK',
        category: 'builtin.transport',
        ago: const Duration(hours: 4),
      ),
      // Cocok rencana: rutin Spotify tetap persis -> satu ketuk, juga di Gratis.
      _entry(
        '8',
        app: 'BCA',
        text: 'Pembayaran Rp54.000 ke SPOTIFY berhasil',
        amount: 5400000,
        note: 'SPOTIFY',
        category: 'builtin.entertainment',
        ago: const Duration(hours: 6),
      ),
      _entry(
        '5',
        app: 'DANA',
        text: 'Pembayaran Rp12.000 ke GOJEK berhasil (notifikasi kedua dari transaksi yang sama)',
        amount: 1200000,
        note: 'GOJEK',
        flagged: true,
        ago: const Duration(hours: 5),
      ),
    ]);
    await store.saveAutoRecorded([
      AutoRecordedEntry(
        captureId: 'a1',
        transactionId: 't1',
        transactionDate: _at,
        kind: DraftKind.expense,
        amountSen: 2500000,
        appLabel: 'BRImo',
        recordedAt: _at,
        note: 'INDOMARET',
      ),
      AutoRecordedEntry(
        captureId: 'a2',
        transactionId: 't2',
        transactionDate: _at,
        kind: DraftKind.income,
        amountSen: 150000000,
        appLabel: 'Jago',
        recordedAt: _at,
        note: 'Gaji',
      ),
    ]);
  }
  final changes = CaptureInboxChanges();
  NotificationRuleInterpreter ruleInterpreter(CaptureLanguage language) =>
      NotificationRuleInterpreter(language: language, categories: () => ActiveCategories.notifier.value);
  final composer = NotificationDraftComposer(
    composer: CaptureDraftComposer(
      ruleInterpreterFor: ruleInterpreter,
      cloudInterpreter: FirebaseAiTransactionInterpreter(),
    ),
  );
  final recordTransaction = RecordTransaction(
    ledgerChanges: ledgerChanges,
    transactionRepository: ledger,
    recomputeWalletBalances: RecomputeWalletBalances(walletRepository: wallets, transactionRepository: ledger),
  );
  final actions = CaptureInboxActions(
    store: store,
    recordTransaction: recordTransaction,
    transactionRepository: ledger,
    composer: composer,
    walletRepository: wallets,
    categories: () => ActiveCategories.notifier.value,
    currencyCode: () => 'IDR',
    languageCode: () => 'id',
    changes: changes,
    recurringRules: rules,
  );
  final inbox = CaptureInboxBloc(
    store: store,
    actions: actions,
    transactionRepository: ledger,
    changes: changes,
    ledgerChanges: ledgerChanges,
  )..add(const CaptureInboxStarted());
  final settings = NotificationSettingsBloc(gateway: gateway, store: store, walletRepository: wallets);
  return (inbox, settings);
}

/// Tombol di app bar Akun yang membuka skenario Catat dari notifikasi.
class DebugNotificationGalleryButton extends StatelessWidget {
  const DebugNotificationGalleryButton({super.key});

  Future<void> _quickStart(
    BuildContext context, {
    bool free = false,
    bool fails = false,
    bool oneWallet = false,
  }) async {
    final previous = ActivePlan.notifier.value;
    if (free) ActivePlan.notifier.value = const FreePlan();
    final storage = InMemoryKeyValueStorage();
    final walletRepository = WalletRepositoryImpl(storage: storage);
    for (final (id, name) in [('bca', 'BCA'), ('tabungan', 'Tabungan')].take(oneWallet ? 1 : 2)) {
      await walletRepository.saveWallet(
        Wallet(id: id, name: name, iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
      );
    }
    final bloc = NotificationSettingsBloc(
      gateway: _Gateway(loadFails: fails),
      store: NotificationCaptureStoreImpl(storage: storage),
      walletRepository: walletRepository,
    )..add(const NotificationSettingsStarted());
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<NotificationSettingsBloc>.value(
          value: bloc,
          child: EffectListener<NotificationSettingsBloc, NotificationSettingsState>(child: const QuickStartPage()),
        ),
      ),
    );
    ActivePlan.notifier.value = previous;
  }

  Future<void> _inbox(BuildContext context, {bool empty = false, bool access = false, bool free = false}) async {
    final (inbox, settings) = await _seed(empty: empty, access: access);
    if (!context.mounted) return;
    final previous = ActivePlan.notifier.value;
    if (free) ActivePlan.notifier.value = const FreePlan();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<CaptureInboxBloc>.value(value: inbox),
            BlocProvider<NotificationSettingsBloc>.value(value: settings),
          ],
          child: EffectListener<CaptureInboxBloc, CaptureInboxState>(child: const CaptureInboxPage()),
        ),
      ),
    );
    ActivePlan.notifier.value = previous;
  }

  Future<void> _settings(BuildContext context, {bool free = false, NotificationDelivery? delivery}) async {
    final previous = ActivePlan.notifier.value;
    if (free) ActivePlan.notifier.value = const FreePlan();
    final storage = InMemoryKeyValueStorage();
    final store = NotificationCaptureStoreImpl(storage: storage);
    final wallets = WalletRepositoryImpl(storage: storage);
    await wallets.saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 650000000),
    );
    await store.saveSettings(
      NotificationCaptureSettings(
        enabled: true,
        delivery: delivery ?? NotificationDelivery.automatic,
        sources: const [
          NotificationSource(
            packageName: 'id.contoh.brimo',
            appLabel: 'BRImo',
            keywords: ['berhasil'],
            walletId: 'bca',
          ),
          NotificationSource(packageName: 'id.contoh.gopay', appLabel: 'GoPay', keywords: ['berhasil']),
        ],
      ),
    );
    final bloc = NotificationSettingsBloc(
      gateway: _Gateway(access: true),
      store: store,
      walletRepository: wallets,
    )..add(const NotificationSettingsStarted());
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<NotificationSettingsBloc>.value(
          value: bloc,
          child: EffectListener<NotificationSettingsBloc, NotificationSettingsState>(
            child: const NotificationSettingsPage(),
          ),
        ),
      ),
    );
    ActivePlan.notifier.value = previous;
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    icon: const Icon(Icons.rocket_launch),
    tooltip: 'Catat dari notifikasi (debug)',
    onSelected: (i) => switch (i) {
      0 => _quickStart(context),
      1 => _quickStart(context, free: true),
      2 => _quickStart(context, fails: true),
      3 => _inbox(context),
      4 => _inbox(context, empty: true),
      5 => _quickStart(context, oneWallet: true),
      7 => _inbox(context, access: true, free: true),
      8 => _settings(context),
      9 => _settings(context, free: true),
      10 => _settings(context, delivery: NotificationDelivery.inboxOnly),
      _ => _inbox(context, access: true),
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 0, child: Text('Mulai cepat: Plus, 2 dompet (pilih dompet per aplikasi)')),
      PopupMenuItem(value: 5, child: Text('Mulai cepat: Plus, 1 dompet (otomatis)')),
      PopupMenuItem(value: 1, child: Text('Mulai cepat: Gratis (catatan batas)')),
      PopupMenuItem(value: 2, child: Text('Mulai cepat: gagal memuat daftar')),
      PopupMenuItem(value: 3, child: Text('Kotak masuk: Plus, izin dicabut (banner)')),
      PopupMenuItem(value: 6, child: Text('Kotak masuk: Plus, izin ada (satu ketuk + Catat semua)')),
      PopupMenuItem(value: 7, child: Text('Kotak masuk: Gratis, izin ada (hanya rutin tetap satu ketuk)')),
      PopupMenuItem(value: 4, child: Text('Kotak masuk: kosong')),
      PopupMenuItem(value: 8, child: Text('Setelan: Plus (pengingat nyala otomatis)')),
      PopupMenuItem(value: 9, child: Text('Setelan: Gratis (pengingat mati)')),
      PopupMenuItem(value: 10, child: Text('Setelan: Plus, dimatikan sendiri')),
    ],
  );
}
