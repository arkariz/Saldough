import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_text.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Draf dari satu notifikasi.
final class NotificationDraft {
  /// Membuat [NotificationDraft].
  const NotificationDraft({required this.draft});

  /// Draf hasil tafsir.
  final RecordDraft draft;
}

/// Menyusun draf dari notifikasi (ADR-044 §3.4): [CaptureDraftComposer]
/// (aturan notifikasi → Gemini bila ragu), lalu dompet sumber mengisi dompet
/// draf. Tanpa pola buatan pengguna; bentuk dipelajari hanya menyaring
/// (ADR-044 Revisi 11).
final class NotificationDraftComposer {
  /// Membuat [NotificationDraftComposer]. [composer] memakai interpreter
  /// aturan notifikasi.
  const NotificationDraftComposer({required this.composer});

  /// Penyusun aturan → cloud.
  final CaptureDraftComposer composer;

  /// Draf untuk [notification] dari [source].
  Future<NotificationDraft> compose(
    CapturedNotification notification, {
    required NotificationSource source,
    required List<Wallet> wallets,
    required List<Category> categories,
    required String currencyCode,
    required String languageCode,
  }) async {
    // Bahasa notifikasi mengikuti aplikasi bank, bukan bahasa Tanukonomy:
    // pengguna berantarmuka Inggris tetap menerima "Pembayaran Rp25.000".
    final language = detectNotificationLanguage(notification.text, fallback: languageCode);
    final evidence = CaptureEvidence(
      source: CaptureSource.notification,
      text: notification.text,
      capturedAt: notification.postedAt,
      languageCode: language?.code ?? languageCode,
      origin: notification.packageName,
    );
    // Dompet sumber untuk teks ini (ADR-042 §3.1): aturan dompet, lalu bawaan;
    // ambigu = tidak menebak. Dompet sumber tidak boleh terbaca sebagai lawan
    // transfer, tetapi dompet lain milik aplikasi yang sama boleh.
    final resolved = source.resolveWallet(notification.text);
    final otherWallets = [
      for (final w in wallets)
        if (w.id != resolved.walletId) w,
    ];

    final masked = language == null
        ? evidence.text
        : NotificationText.maskNonTransactionNumbers(evidence.text, language.notification);
    // Aturan notifikasi → Gemini bila ragu.
    final composed = _tidy(
      _withSourceWallet(
        await composer.compose(
          evidence,
          wallets: otherWallets,
          categories: categories,
          currencyCode: currencyCode,
          // Saldo, nomor rekening, dan nomor referensi tidak perlu ke cloud.
          cloudText: masked,
        ),
        resolved.walletId,
        ambiguous: resolved.ambiguous,
      ),
      source,
      notification.title,
      language,
    );
    return NotificationDraft(draft: composed);
  }

  /// Catatan tanpa awalan yang bukan isi transaksi: judul notifikasi (sering
  /// nama bank atau "Transaksi Berhasil") dan nama aplikasi sumber, lalu
  /// preposisi yang jadi terdepan ("ke KOPI KENANGAN" → "KOPI KENANGAN",
  /// sama seperti catatan tanpa judul). Awalan tidak dibuang bila catatannya
  /// jadi kosong.
  RecordDraft _tidy(RecordDraft draft, NotificationSource source, String title, CaptureLanguage? language) {
    var note = draft.note.trim();
    var stripped = false;
    for (final prefix in [title.trim(), source.appLabel.trim()]) {
      if (prefix.isEmpty || !note.toLowerCase().startsWith(prefix.toLowerCase())) continue;
      final rest = note.substring(prefix.length).replaceAll(RegExp(r'^[\s:,.-]+'), '');
      if (rest.isEmpty) continue;
      note = rest;
      stripped = true;
    }
    if (stripped && language != null) {
      final leading = [
        ...language.toPrepositions,
        ...language.fromPrepositions,
        'di',
        'at',
      ].map(RegExp.escape).join('|');
      final rest = note.replaceFirst(RegExp('^(?:$leading)\\s+', caseSensitive: false), '');
      if (rest.isNotEmpty) note = rest;
    }
    if (note == draft.note) return draft;
    return RecordDraft(
      kind: draft.kind,
      amountSen: draft.amountSen,
      walletId: draft.walletId,
      toWalletId: draft.toWalletId,
      categoryId: draft.categoryId,
      note: note,
      date: draft.date,
      issues: draft.issues,
      sourceText: draft.sourceText,
    );
  }

  /// Dompet sumber mengisi dompet draf: pemasukan/pengeluaran memakai dompet
  /// sumber (menggantikan sebutan dompet dari teks); transfer mengisi sisi
  /// yang kosong. Tanpa dompet sumber, draf tidak diubah.
  RecordDraft _withSourceWallet(RecordDraft draft, String? sourceWalletId, {bool ambiguous = false}) {
    if (ambiguous) {
      // Lebih dari satu dompet cocok: tidak menebak, biarkan pengguna memilih.
      return draft.copyWith(
        walletId: () => null,
        toWalletId: () => null,
        issues: {...draft.issues, DraftIssue.walletUnknown},
      );
    }
    if (sourceWalletId == null) return draft;
    if (draft.kind != DraftKind.transfer) {
      return draft.copyWith(
        walletId: () => sourceWalletId,
        issues: {...draft.issues}..remove(DraftIssue.walletUnknown),
      );
    }
    final issues = {...draft.issues};
    var from = draft.walletId;
    var to = draft.toWalletId;
    if (from == null && to != null && to != sourceWalletId) {
      from = sourceWalletId;
      issues.remove(DraftIssue.transferSourceMissing);
    } else if (to == null && from != null && from != sourceWalletId) {
      to = sourceWalletId;
      issues.remove(DraftIssue.transferTargetMissing);
    }
    if (from != null && to != null) issues.remove(DraftIssue.walletUnknown);
    return draft.copyWith(walletId: () => from, toWalletId: () => to, issues: issues);
  }
}

/// Paket bahasa yang paling cocok dengan [text] menurut kosakata notifikasinya
/// (kata arah, saldo, kata baku); seri atau tanpa kecocokan → [fallback]
/// (bahasa aplikasi).
CaptureLanguage? detectNotificationLanguage(String text, {required String fallback}) {
  final lower = text.toLowerCase();
  final preferred = CaptureLanguages.of(fallback);
  var best = preferred;
  var bestScore = preferred == null ? -1 : _languageScore(lower, preferred);
  for (final language in CaptureLanguages.all.values) {
    final score = _languageScore(lower, language);
    if (score > bestScore) {
      best = language;
      bestScore = score;
    }
  }
  return best;
}

int _languageScore(String lower, CaptureLanguage language) {
  final lexicon = language.notification;
  final phrases = {
    ...lexicon.incomeCues,
    ...lexicon.expenseCues,
    ...lexicon.balanceWords,
    ...lexicon.transferCues,
    ...lexicon.fillerWords,
  };
  return phrases.where((p) => RegExp('(^|[^a-z])${RegExp.escape(p)}(?=[^a-z]|\$)').hasMatch(lower)).length;
}
