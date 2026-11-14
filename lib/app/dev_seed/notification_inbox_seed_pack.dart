import 'package:dependencies/dependencies.dart' show Unit;
import 'package:di/di.dart';
import 'package:saldough/app/dev_seed/seed_pack.dart';
import 'package:saldough/app/dev_seed/wallet_seed_pack.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Satu catatan tercatat otomatis seed.
typedef SeedAutoRecorded = ({String app, String text, String note, int rupiah, String walletId, String category, Duration ago});

/// Satu draf kotak masuk seed.
typedef SeedInboxDraft = ({
  String app,
  String package,
  String text,
  Duration ago,
  DraftKind kind,
  int? rupiah,
  String? walletId,
  String? category,
  Set<DraftIssue> issues,
  CaptureReviewReason? reason,
  bool duplicate,
});

/// Data uji Kotak masuk Catat dari notifikasi: lima **draf** yang menunggu
/// ditinjau (satu per alasan peninjauan) dan empat **tercatat otomatis**
/// (transaksinya sungguh ada di buku besar dan saldo dompetnya ikut).
///
/// Semua teks notifikasi karangan (nama toko, nomor rekening, kartu), bukan
/// data nyata. Waktunya relatif terhadap sekarang karena kotak masuk dan log
/// otomatis dibuang aplikasi sesudah [CaptureRetention.days] hari; id memuat
/// tanggal penerapan, jadi menerapkan ulang di hari yang sama tidak
/// menggandakan dan di hari lain menambah data segar.
///
/// Setelan Catat dari notifikasi hanya diisi (menyala, tingkat "Otomatis bila
/// lengkap", empat sumber) kalau masih bawaan; setelan yang sudah disetel
/// pengguna tidak disentuh. Izin akses notifikasi sistem tetap harus diberikan
/// lewat layar setelan. Bergantung pada [WalletSeedPack] (otomatis).
final class NotificationInboxSeedPack implements SeedPack {
  /// Membuat [NotificationInboxSeedPack].
  const NotificationInboxSeedPack();

  static int _sen(int rupiah) => rupiah * 100;

  /// Tercatat otomatis (transaksi nyata di buku besar).
  static const List<SeedAutoRecorded> autoRecorded = [
    (
      app: 'm-BCA',
      text: 'Transaksi berhasil. Pembayaran QRIS Rp48.750 ke INDOMARET 2231 dari rekening 1234***890.',
      note: 'Indomaret',
      rupiah: 48750,
      walletId: SeedIds.walletUtama,
      category: 'builtin.groceries',
      ago: Duration(hours: 3),
    ),
    (
      app: 'GoPay',
      text: 'Pembayaran berhasil Rp27.500 ke GOJEK perjalanan.',
      note: 'Gojek',
      rupiah: 27500,
      walletId: SeedIds.walletMingguan,
      category: 'builtin.transport',
      ago: Duration(days: 1, hours: 4),
    ),
    (
      app: 'm-BCA',
      text: 'Transaksi berhasil. Pembayaran QRIS Rp67.300 ke APOTEK CENTURY dari rekening 1234***890.',
      note: 'Apotek Century',
      rupiah: 67300,
      walletId: SeedIds.walletUtama,
      category: 'builtin.health',
      ago: Duration(days: 2, hours: 1),
    ),
    (
      app: 'GoPay',
      text: 'Pembayaran berhasil Rp32.000 di KOPI KENANGAN.',
      note: 'Kopi Kenangan',
      rupiah: 32000,
      walletId: SeedIds.walletMingguan,
      category: 'builtin.food',
      ago: Duration(days: 3, hours: 2),
    ),
  ];

  /// Draf di kotak masuk, satu per alasan peninjauan.
  static const List<SeedInboxDraft> drafts = [
    (
      app: 'm-BCA',
      package: 'com.bca',
      text: 'Transaksi berhasil. Pembayaran QRIS Rp56.500 ke TOKO MAJU JAYA dari rekening 1234***890.',
      ago: Duration(minutes: 30),
      kind: DraftKind.expense,
      rupiah: 56500,
      walletId: SeedIds.walletUtama,
      category: null,
      issues: {DraftIssue.categoryUnknown},
      reason: CaptureReviewReason.categoryUnclear,
      duplicate: false,
    ),
    (
      app: 'Livin by Mandiri',
      package: 'id.bmri.livin',
      text: 'Pembelian berhasil di TOKOPEDIA Rp349.000 dengan kartu kredit ****4821.',
      ago: Duration(hours: 2),
      kind: DraftKind.expense,
      rupiah: 349000,
      walletId: null,
      category: 'builtin.shopping',
      issues: {DraftIssue.walletUnknown},
      reason: CaptureReviewReason.walletUnknown,
      duplicate: false,
    ),
    (
      app: 'DANA',
      package: 'id.dana',
      text: 'Kamu menerima 2 transaksi: Rp120.000 dan Rp85.000 dari WARUNG BU TINI.',
      ago: Duration(hours: 5),
      kind: DraftKind.income,
      rupiah: null,
      walletId: SeedIds.walletUtama,
      category: null,
      issues: {DraftIssue.amountMultiple},
      reason: CaptureReviewReason.amountUnclear,
      duplicate: false,
    ),
    (
      app: 'm-BCA',
      package: 'com.bca',
      text: 'Transfer berhasil Rp1.250.000 ke 8801****23 a.n. RIZKY AHMAD.',
      ago: Duration(days: 1),
      kind: DraftKind.expense,
      rupiah: 1250000,
      walletId: SeedIds.walletUtama,
      category: null,
      issues: {DraftIssue.kindUnclear},
      reason: CaptureReviewReason.kindUnclear,
      duplicate: false,
    ),
    (
      app: 'GoPay',
      package: 'com.gojek.gopay',
      text: 'Pembayaran berhasil Rp32.000 di KOPI KENANGAN.',
      ago: Duration(days: 1, hours: 6),
      kind: DraftKind.expense,
      rupiah: 32000,
      walletId: SeedIds.walletMingguan,
      category: 'builtin.food',
      issues: <DraftIssue>{},
      reason: null,
      duplicate: true,
    ),
  ];

  @override
  String get id => 'notification_inbox';

  @override
  String get label => 'Kotak masuk notifikasi (5 draf, 4 otomatis)';

  @override
  String get description =>
      'Lima draf menunggu ditinjau (kategori, dompet, nominal, jenis, kembar) dan empat catatan '
      'tercatat otomatis, lengkap dengan transaksinya. Setelan hanya diisi bila masih bawaan.';

  @override
  Future<SeedResult> apply(GetIt container) => applyAt(container, DateTime.now());

  /// Seperti [apply] dengan "sekarang" [now] (untuk uji).
  Future<SeedResult> applyAt(GetIt container, DateTime now) async {
    T ok<T>(dynamic either) => (either as dynamic).fold((Object f) => throw StateError('$f'), (T r) => r) as T;

    await const WalletSeedPack().apply(container);
    final store = container<NotificationCaptureStore>();
    final txRepo = container<TransactionRepository>();
    final ymd = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    var added = 0;
    var skipped = 0;

    // Setelan: hanya bila belum pernah disetel.
    final settings = ok<NotificationCaptureSettings>(await store.loadSettings());
    if (!settings.enabled && settings.sources.isEmpty) {
      ok<Unit>(
        await store.saveSettings(
          settings.copyWith(
            enabled: true,
            autoRecordLevel: AutoRecordLevel.whenComplete,
            sources: const [
              NotificationSource(
                packageName: 'com.bca',
                appLabel: 'm-BCA',
                keywords: defaultNotificationKeywords,
                walletId: SeedIds.walletUtama,
              ),
              NotificationSource(
                packageName: 'id.bmri.livin',
                appLabel: 'Livin by Mandiri',
                keywords: defaultNotificationKeywords,
              ),
              NotificationSource(packageName: 'id.dana', appLabel: 'DANA', keywords: defaultNotificationKeywords),
              NotificationSource(
                packageName: 'com.gojek.gopay',
                appLabel: 'GoPay',
                keywords: defaultNotificationKeywords,
                walletId: SeedIds.walletMingguan,
              ),
            ],
          ),
        ),
      );
      added++;
    } else {
      skipped++;
    }

    // Tercatat otomatis: transaksi dulu, lalu log-nya.
    final existingAuto = {for (final e in ok<List<AutoRecordedEntry>>(await store.loadAutoRecorded())) e.captureId};
    final autoLog = [...ok<List<AutoRecordedEntry>>(await store.loadAutoRecorded())];
    final touchedWallets = <String>{};
    for (final (i, a) in autoRecorded.indexed) {
      final captureId = 'seed_cap_auto_${ymd}_$i';
      if (existingAuto.contains(captureId)) {
        skipped++;
        continue;
      }
      final capturedAt = now.subtract(a.ago);
      final txId = 'seed_tx_auto_${ymd}_$i';
      ok<Unit>(
        await txRepo.saveTransaction(
          ExpenseTransaction(
            id: txId,
            date: DateTime(capturedAt.year, capturedAt.month, capturedAt.day),
            amount: _sen(a.rupiah),
            note: a.note,
            walletId: a.walletId,
            categoryId: a.category,
          ),
        ),
      );
      touchedWallets.add(a.walletId);
      autoLog.add(
        AutoRecordedEntry(
          captureId: captureId,
          transactionId: txId,
          transactionDate: DateTime(capturedAt.year, capturedAt.month, capturedAt.day),
          kind: DraftKind.expense,
          amountSen: _sen(a.rupiah),
          appLabel: a.app,
          recordedAt: capturedAt.add(const Duration(minutes: 1)),
          note: a.note,
          categoryId: a.category,
          capturedAt: capturedAt,
          isNew: i == autoRecorded.length - 1,
        ),
      );
      added++;
    }
    if (touchedWallets.isNotEmpty) {
      ok<Unit>(await store.saveAutoRecorded(autoLog));
      ok<Unit>(
        await RecomputeWalletBalances(
          walletRepository: container<WalletRepository>(),
          transactionRepository: txRepo,
        ).forWallets(touchedWallets),
      );
      container<LedgerChanges>().notifyChanged(source: this);
    }

    // Draf di kotak masuk.
    final inbox = [...ok<List<CaptureInboxEntry>>(await store.loadInbox())];
    final existingInbox = {for (final e in inbox) e.id};
    var inboxChanged = false;
    for (final (i, d) in drafts.indexed) {
      final captureId = 'seed_cap_inbox_${ymd}_$i';
      if (existingInbox.contains(captureId)) {
        skipped++;
        continue;
      }
      final capturedAt = now.subtract(d.ago);
      inbox.add(
        CaptureInboxEntry(
          id: captureId,
          packageName: d.package,
          appLabel: d.app,
          text: d.text,
          capturedAt: capturedAt,
          draft: RecordDraft(
            kind: d.kind,
            amountSen: d.rupiah == null ? null : _sen(d.rupiah!),
            walletId: d.walletId,
            categoryId: d.category,
            date: DateTime(capturedAt.year, capturedAt.month, capturedAt.day),
            issues: d.issues,
            sourceText: d.text,
          ),
          possibleDuplicate: d.duplicate,
          reviewReason: d.reason,
        ),
      );
      inboxChanged = true;
      added++;
    }
    if (inboxChanged) ok<Unit>(await store.saveInbox(inbox));

    if (added > 0) container<CaptureInboxChanges>().notify();
    return SeedResult(added: added, skipped: skipped);
  }
}
