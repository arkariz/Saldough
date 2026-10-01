import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_template.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_text.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Draf dari satu notifikasi, beserta boleh-tidaknya dicatat otomatis.
final class NotificationDraft {
  /// Membuat [NotificationDraft].
  const NotificationDraft({required this.draft, required this.autoEligible, this.pattern});

  /// Draf hasil tafsir.
  final RecordDraft draft;

  /// `false` bila drafnya dari pola yang belum terverifikasi: selalu
  /// ditinjau, apa pun tingkat otomatisnya. Promosi tidak perlu disaring di
  /// sini -- filter sumber sudah whitelist frasa transaksi (ADR-032 §3.1).
  final bool autoEligible;

  /// Pola yang cocok, atau `null` bila dari aturan/cloud.
  final NotificationPattern? pattern;
}

/// Menyusun draf dari notifikasi (ADR-032 §3.3): pola pengguna, lalu pola
/// bawaan; tanpa pola yang cocok, [CaptureDraftComposer] (aturan notifikasi →
/// Gemini bila ragu). Sesudahnya dompet sumber mengisi dompet draf.
final class NotificationDraftComposer {
  /// Membuat [NotificationDraftComposer]. [composer] memakai interpreter
  /// aturan notifikasi; [ruleInterpreterFor] yang sama dipakai untuk catatan
  /// dan kategori draf dari pola.
  const NotificationDraftComposer({required this.composer, required this.ruleInterpreterFor});

  /// Penyusun aturan → cloud.
  final CaptureDraftComposer composer;

  /// Interpreter aturan notifikasi per paket bahasa.
  final TransactionInterpreter Function(CaptureLanguage language) ruleInterpreterFor;

  /// Draf untuk [notification] dari [source].
  Future<NotificationDraft> compose(
    CapturedNotification notification, {
    required NotificationSource source,
    required List<NotificationPattern> patterns,
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
    // Dompet sumber tidak boleh terbaca sebagai lawan transfer.
    final otherWallets = [
      for (final w in wallets)
        if (w.id != source.walletId) w,
    ];

    final masked = language == null
        ? evidence.text
        : NotificationText.maskNonTransactionNumbers(evidence.text, language.notification);
    final own = patterns.where((p) => p.packageName == notification.packageName).toList();

    Future<NotificationDraft?> tryPatterns(Iterable<NotificationPattern> candidates) async {
      for (final pattern in candidates) {
        final match = NotificationTemplate.match(pattern.template, masked);
        if (match == null) continue;
        final draft = await _fromPattern(
          pattern,
          match,
          evidence,
          language,
          wallets: wallets,
          otherWallets: otherWallets,
          categories: categories,
          currencyCode: currencyCode,
        );
        if (draft.amountSen == null) continue;
        return NotificationDraft(
          draft: _tidy(_withSourceWallet(draft, source.walletId), source, notification.title, language),
          autoEligible: pattern.verified,
          pattern: pattern,
        );
      }
      return null;
    }

    // 1. Pola pengguna dan pola bawaan yang sudah dicocokkan dengan sampel asli.
    final trusted = await tryPatterns(own.where((p) => p.verified));
    if (trusted != null) return trusted;

    // 2. Aturan notifikasi → Gemini bila ragu.
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
        source.walletId,
      ),
      source,
      notification.title,
      language,
    );
    if (composed.isConfident) return NotificationDraft(draft: composed, autoEligible: true);

    // 3. Pola bawaan yang belum terverifikasi, hanya bila aturan belum yakin;
    // drafnya selalu ditinjau.
    return await tryPatterns(own.where((p) => !p.verified)) ?? NotificationDraft(draft: composed, autoEligible: true);
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

  Future<RecordDraft> _fromPattern(
    NotificationPattern pattern,
    NotificationTemplateMatch match,
    CaptureEvidence evidence,
    CaptureLanguage? language, {
    required List<Wallet> wallets,
    required List<Wallet> otherWallets,
    required List<Category> categories,
    required String currencyCode,
  }) async {
    final kind = switch (pattern.kind) {
      NotificationPatternKind.expense => DraftKind.expense,
      NotificationPatternKind.income => DraftKind.income,
      NotificationPatternKind.transferOut || NotificationPatternKind.transferIn => DraftKind.transfer,
    };
    // Catatan dan kategori dari aturan bila pola tidak menentukannya.
    InterpretedTransaction? rules;
    if (language != null && (match.note == null || pattern.categoryId == null)) {
      final context = InterpretationContext(
        walletNames: [for (final w in otherWallets) w.name],
        expenseCategoryNames: [
          for (final c in categories)
            if (c.kind == CategoryKind.expense && !c.isArchived) c.name,
        ],
        incomeCategoryNames: [
          for (final c in categories)
            if (c.kind == CategoryKind.income && !c.isArchived) c.name,
        ],
        today: evidence.capturedAt,
        currencyCode: currencyCode,
      );
      try {
        rules = (await ruleInterpreterFor(language).interpret(evidence, context)).fold((_) => null, (r) => r);
      } on Object {
        rules = null;
      }
    }
    final category = _category(categories, pattern.categoryId, kind);
    final resolver = CaptureDraftResolver(
      wallets: wallets,
      categories: categories,
      currencyCode: currencyCode,
      language: language,
    );
    var draft = resolver.resolve(
      evidence,
      InterpretedTransaction(
        kind: kind,
        amountText: match.amountText,
        note: match.note ?? rules?.note,
        categoryName: kind == DraftKind.transfer
            ? null
            : (category?.name ?? (rules?.kind == kind ? rules?.categoryName : null)),
        dateText: rules?.dateText,
        date: rules?.date,
      ),
    );
    if (kind == DraftKind.transfer) {
      final other = pattern.transferWalletId;
      final known = other != null && wallets.any((w) => w.id == other);
      final issues = {...draft.issues}..removeAll({DraftIssue.transferSourceMissing, DraftIssue.transferTargetMissing});
      draft = pattern.kind == NotificationPatternKind.transferOut
          ? draft.copyWith(
              walletId: () => null,
              toWalletId: () => known ? other : null,
              issues: {...issues, DraftIssue.transferSourceMissing, if (!known) DraftIssue.transferTargetMissing},
            )
          : draft.copyWith(
              walletId: () => known ? other : null,
              toWalletId: () => null,
              issues: {...issues, if (!known) DraftIssue.transferSourceMissing, DraftIssue.transferTargetMissing},
            );
    }
    return draft;
  }

  Category? _category(List<Category> categories, String? id, DraftKind kind) {
    if (id == null || kind == DraftKind.transfer) return null;
    final wanted = kind == DraftKind.income ? CategoryKind.income : CategoryKind.expense;
    for (final c in categories) {
      if (c.id == id && !c.isArchived && c.kind == wanted) return c;
    }
    return null;
  }

  /// Dompet sumber mengisi dompet draf: pemasukan/pengeluaran memakai dompet
  /// sumber (menggantikan sebutan dompet dari teks); transfer mengisi sisi
  /// yang kosong. Tanpa dompet sumber, draf tidak diubah.
  RecordDraft _withSourceWallet(RecordDraft draft, String? sourceWalletId) {
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
