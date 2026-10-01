import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/active_capture_inputs.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Aksi pengguna di kotak masuk (ADR-032 §3.6).
final class CaptureInboxActions {
  /// Membuat [CaptureInboxActions].
  const CaptureInboxActions({
    required this.store,
    required this.recordTransaction,
    required this.transactionRepository,
    required this.composer,
    required this.walletRepository,
    required this.categories,
    required this.currencyCode,
    required this.languageCode,
    this.changes,
  });

  /// Sinyal perubahan kotak masuk, atau `null`.
  final CaptureInboxChanges? changes;

  /// Penyimpanan.
  final NotificationCaptureStore store;

  /// Use case tulis buku besar (untuk Batalkan).
  final RecordTransaction recordTransaction;

  /// Buku besar.
  final TransactionRepository transactionRepository;

  /// Penyusun draf (untuk menafsirkan ulang dengan pola baru).
  final NotificationDraftComposer composer;

  /// Dompet aktif.
  final WalletRepository walletRepository;

  /// Kategori terkini.
  final List<Category> Function() categories;

  /// Mata uang aplikasi.
  final String Function() currencyCode;

  /// Bahasa aplikasi.
  final String Function() languageCode;

  /// Menghapus item kotak masuk [id] (Abaikan, atau sesudah dicatat lewat
  /// CATAT). Teksnya ikut terhapus.
  Future<Either<Failure, Unit>> remove(String id) async {
    final inbox = (await store.loadInbox()).getOrElse((_) => const []);
    final saved = await store.saveInbox([
      for (final e in inbox)
        if (e.id != id) e,
    ]);
    changes?.notify();
    return saved;
  }

  /// Membatalkan transaksi otomatis [entry]: menghapusnya dari buku besar
  /// lewat [RecordTransaction.delete], lalu dari log. Transaksi yang sudah
  /// dihapus pengguna cukup dihapus dari log.
  Future<Either<Failure, Unit>> undo(AutoRecordedEntry entry) async {
    final ledger = await transactionRepository.listTransactionsInMonth(entry.transactionDate);
    switch (ledger) {
      case Left(:final value):
        return left(value);
      case Right(:final value):
        final transaction = value.where((t) => t.id == entry.transactionId).firstOrNull;
        if (transaction != null) {
          final deleted = await recordTransaction.delete(transaction);
          if (deleted.isLeft()) return deleted;
        }
    }
    final auto = (await store.loadAutoRecorded()).getOrElse((_) => const []);
    final saved = await store.saveAutoRecorded([
      for (final e in auto)
        if (e.transactionId != entry.transactionId) e,
    ]);
    changes?.notify();
    return saved;
  }

  /// Menafsirkan ulang item [id] sesudah pola baru disimpan; drafnya
  /// diganti, tidak dicatat otomatis (pengguna sedang meninjaunya).
  Future<CaptureInboxEntry?> reinterpret(String id) async {
    final settings = (await store.loadSettings()).getOrElse((_) => const NotificationCaptureSettings());
    final inbox = [...(await store.loadInbox()).getOrElse((_) => const [])];
    final index = inbox.indexWhere((e) => e.id == id);
    if (index < 0) return null;
    final entry = inbox[index];
    final source = settings.activeSource(entry.packageName);
    if (source == null) return entry;
    final wallets = await loadActiveWallets(walletRepository);
    final patterns = await loadActivePatterns(store, settings);
    final composed = await composer.compose(
      CapturedNotification(
        id: entry.id,
        packageName: entry.packageName,
        title: '',
        body: entry.text,
        postedAt: entry.capturedAt,
      ),
      source: source,
      patterns: patterns,
      wallets: wallets,
      categories: categories(),
      currencyCode: currencyCode(),
      languageCode: languageCode(),
    );
    final updated = CaptureInboxEntry(
      id: entry.id,
      packageName: entry.packageName,
      appLabel: entry.appLabel,
      text: entry.text,
      capturedAt: entry.capturedAt,
      draft: composed.draft.copyWith(sourceIconId: () => entry.iconId),
      possibleDuplicate: entry.possibleDuplicate,
      iconId: entry.iconId,
    );
    inbox[index] = updated;
    await store.saveInbox(inbox);
    changes?.notify();
    return updated;
  }
}
