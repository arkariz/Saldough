// Satu method disengaja: port kecil untuk satu kebutuhan baca (E1, B-85).
// ignore_for_file: one_member_abstracts

import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/services/auto_record_policy.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_card_class.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Ingatan pedagang (ADR-044 §3.1, E1/B-85): kategori yang pernah
/// dikonfirmasi pengguna untuk catatan serupa dari aplikasi yang sama. Port
/// kecil; implementasinya datang bersama "Ingat". Tanpa ingatan, langkah ini
/// dilewati.
abstract interface class MerchantMemory {
  /// Kategori yang diingat untuk [note] dari [packageName], atau `null`.
  String? categoryFor({required String packageName, required String note});
}

/// Jejak keputusan penentu, urut sesuai langkahnya. Untuk uji dan, nanti,
/// penjelasan di kartu ("kenapa ini dikenali").
enum ResolveNote {
  /// Rutin ditentukan oleh pola yang terikat (ADR-042 §3.4).
  planBound,

  /// Pola terikat tetapi kemunculannya tidak jelas: ditinjau, tidak ditebak.
  planBoundUnclear,

  /// Tepat satu kemunculan rutin yang cocok.
  planUnique,

  /// Beberapa kemunculan cocok; satu-satunya yang namanya muncul di teks dipilih.
  planTieBreak,

  /// Beberapa kemunculan cocok dan nama tidak memutus: tidak ditebak.
  planAmbiguous,

  /// Kategori diisi dari rutin yang cocok.
  categoryFromPlan,

  /// Catatan diisi dari rutin yang cocok.
  noteFromPlan,

  /// Kategori diisi dari ingatan pedagang.
  categoryFromMemory,

  /// Catatan yang tampak sama sudah ada di buku besar.
  duplicateInLedger,
}

/// Hasil pencocokan rencana (rutin) untuk satu tangkapan.
final class PlanResolution {
  /// Membuat [PlanResolution].
  const PlanResolution({
    this.match,
    this.bound = false,
    this.boundUnclear = false,
    this.tieBroken = false,
    this.ambiguous = false,
  });

  /// Tanpa rencana yang cocok.
  static const none = PlanResolution();

  /// Kemunculan rutin yang cocok, atau `null` (tidak ada, atau ambigu).
  final OccurrenceMatch? match;

  /// Rutinnya ditentukan pola yang terikat.
  final bool bound;

  /// Pola terikat tetapi kemunculan tidak jelas atau nominal tidak persis:
  /// tangkapan ditinjau, tidak dicatat tanpa tautan.
  final bool boundUnclear;

  /// [match] dipilih karena namanya muncul di teks; hanya saran, tidak pernah
  /// ditautkan otomatis.
  final bool tieBroken;

  /// Beberapa kemunculan cocok dan tidak ada pemutus.
  final bool ambiguous;
}

/// Mencocokkan draf dengan kemunculan rutin (ADR-035 §3.4, ADR-042 §3.4).
///
/// 1. Pola yang terikat ke rutin menentukan rutinnya sendiri
///    (`matchBoundOccurrence`, ±7 hari, tepat satu kemunculan terbuka).
/// 2. Selain itu `occurrenceCandidates` (jenis, dompet, nominal persis atau
///    ±10%, ±3 hari, belum tercatat atau dilewati): satu kandidat dipakai.
/// 3. Beberapa kandidat: yang namanya muncul di [text] memutus bila hanya satu;
///    selain itu ambigu dan tidak ditebak.
///
/// [patternId] hanya diberikan untuk pola yang layak mengikat (terverifikasi).
PlanResolution resolvePlan({
  required RecordDraft draft,
  required DateTime date,
  required String packageName,
  required String text,
  required List<RecurringRule> rules,
  required Iterable<Transaction> ledger,
  String? patternId,
}) {
  final amount = draft.amountSen;
  final walletId = draft.walletId;
  if (amount == null || walletId == null || rules.isEmpty) return PlanResolution.none;
  final kind = switch (draft.kind) {
    DraftKind.income => RecurringKind.income,
    DraftKind.expense => RecurringKind.expense,
    DraftKind.transfer => RecurringKind.transfer,
  };
  final bound = patternId == null
      ? null
      : rules
            .where(
              (r) => r.notificationBinding?.packageName == packageName && r.notificationBinding?.patternId == patternId,
            )
            .firstOrNull;
  if (bound != null) {
    final match = matchBoundOccurrence(
      bound,
      kind: kind,
      walletId: walletId,
      toWalletId: draft.toWalletId,
      amount: amount,
      date: date,
      transactions: ledger,
    );
    return PlanResolution(match: match, bound: true, boundUnclear: !(match != null && match.exact));
  }
  final candidates = occurrenceCandidates(
    kind: kind,
    walletId: walletId,
    toWalletId: draft.toWalletId,
    amount: amount,
    date: date,
    rules: rules,
    transactions: ledger,
  );
  if (candidates.isEmpty) return PlanResolution.none;
  if (candidates.length == 1) return PlanResolution(match: candidates.single);
  final named = [
    for (final c in candidates)
      if (_mentions(text, c.rule.note)) c,
  ];
  if (named.length == 1) return PlanResolution(match: named.single, tieBroken: true);
  return const PlanResolution(ambiguous: true);
}

/// Nama rutin [name] muncul di [text] (tanpa beda huruf dan spasi ganda);
/// nama yang terlalu pendek tidak dipakai supaya tidak memutus secara kebetulan.
bool _mentions(String text, String name) {
  String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  final n = norm(name);
  return n.length >= 3 && norm(text).contains(n);
}

/// [draft] dilengkapi dari rutin yang cocok ([match]): kategori dan catatan yang
/// kosong diisi dari rutin (yang sudah terisi tidak diganti), dan isu "kategori
/// belum dikenal" gugur. Sama dengan yang dilakukan CATAT untuk kartu yang cocok.
RecordDraft enrichFromPlan(RecordDraft draft, OccurrenceMatch? match) {
  if (match == null) return draft;
  final rule = match.rule;
  final fillCategory = draft.categoryId == null && rule.categoryId != null;
  final fillNote = draft.note.trim().isEmpty && rule.note.trim().isNotEmpty;
  if (!fillCategory && !fillNote) return draft;
  return draft.copyWith(
    categoryId: fillCategory ? () => rule.categoryId : null,
    note: fillNote ? rule.note : null,
    issues: fillCategory ? ({...draft.issues}..remove(DraftIssue.categoryUnknown)) : null,
  );
}

/// Keluaran penentu untuk satu tangkapan.
final class ResolvedCapture {
  /// Membuat [ResolvedCapture].
  const ResolvedCapture({
    required this.composed,
    required this.plainDraft,
    required this.draft,
    required this.plan,
    required this.existing,
    required this.cardClass,
    required this.notes,
  });

  /// Hasil penyusun draf (aturan aplikasi, pola, aturan umum); `null` untuk kartu tersimpan.
  final NotificationDraft? composed;

  /// Draf sebelum rencana dan ingatan: dasar pencatatan otomatis yang tidak
  /// tertaut ke rutin.
  final RecordDraft plainDraft;

  /// Draf setelah dilengkapi rencana dan ingatan: yang disimpan di kartu.
  final RecordDraft draft;

  /// Pencocokan rutin.
  final PlanResolution plan;

  /// Catatan di buku besar yang tampak sama, atau `null`.
  final Transaction? existing;

  /// Jenis kartu (cocok rencana, dikenali, perlu diisi).
  final CaptureCardClass cardClass;

  /// Jejak keputusan, urut.
  final List<ResolveNote> notes;
}

/// Penentu bersama (ADR-044 §3.1): satu jalur untuk aplikasi terbuka, kotak
/// masuk, dan nanti mesin tanpa layar.
///
/// Urutan: aturan aplikasi dan pola/aturan umum (penyusun draf, termasuk
/// dompet sumber) → rencana (rutin) → ingatan pedagang → catatan yang sama di
/// buku besar. Yang ambigu tidak ditebak. Pos anggaran dari rutin diisi oleh
/// `CaptureFinalizer` saat transaksi disimpan.
final class CaptureResolver {
  /// Membuat [CaptureResolver]. [ledgerAround] memuat transaksi di sekitar tanggal.
  const CaptureResolver({required this.composer, required this.ledgerAround, this.memory});

  /// Penyusun draf notifikasi.
  final NotificationDraftComposer composer;

  /// Transaksi di sekitar tanggal (bulan sebelum, sesudah, dan bulan itu).
  final Future<List<Transaction>> Function(DateTime date) ledgerAround;

  /// Ingatan pedagang; `null` = dilewati.
  final MerchantMemory? memory;

  /// Menyelesaikan [notification] dari awal.
  Future<ResolvedCapture> resolve(
    CapturedNotification notification, {
    required NotificationSource source,
    required List<NotificationPattern> patterns,
    required List<Wallet> wallets,
    required List<Category> categories,
    required String currencyCode,
    required String languageCode,
    required List<RecurringRule> rules,
  }) async {
    final composed = await composer.compose(
      notification,
      source: source,
      patterns: patterns,
      wallets: wallets,
      categories: categories,
      currencyCode: currencyCode,
      languageCode: languageCode,
    );
    return _finish(
      composed: composed,
      plain: composed.draft,
      postedAt: notification.postedAt,
      packageName: notification.packageName,
      text: notification.text,
      patternId: composed.pattern?.verified ?? false ? composed.pattern?.id : null,
      rules: rules,
    );
  }

  /// Menyelesaikan ulang kartu yang sudah tersimpan (rencana, ingatan,
  /// duplikat), tanpa menyusun ulang drafnya.
  Future<ResolvedCapture> resolveStored(CaptureInboxEntry entry, {required List<RecurringRule> rules}) => _finish(
    composed: null,
    plain: entry.draft,
    postedAt: entry.capturedAt,
    packageName: entry.packageName,
    text: entry.text,
    patternId: entry.patternId,
    rules: rules,
  );

  Future<ResolvedCapture> _finish({
    required NotificationDraft? composed,
    required RecordDraft plain,
    required DateTime postedAt,
    required String packageName,
    required String text,
    required String? patternId,
    required List<RecurringRule> rules,
  }) async {
    final date = plain.date ?? postedAt;
    final ledger = await ledgerAround(date);
    final plan = resolvePlan(
      draft: plain,
      date: date,
      packageName: packageName,
      text: text,
      rules: rules,
      ledger: ledger,
      patternId: patternId,
    );
    final notes = <ResolveNote>[
      if (plan.bound && plan.boundUnclear) ResolveNote.planBoundUnclear,
      if (plan.bound && !plan.boundUnclear) ResolveNote.planBound,
      if (!plan.bound && plan.match != null && plan.tieBroken) ResolveNote.planTieBreak,
      if (!plan.bound && plan.match != null && !plan.tieBroken) ResolveNote.planUnique,
      if (plan.ambiguous) ResolveNote.planAmbiguous,
    ];

    var draft = enrichFromPlan(plain, plan.match);
    if (draft.categoryId != plain.categoryId) notes.add(ResolveNote.categoryFromPlan);
    if (draft.note != plain.note) notes.add(ResolveNote.noteFromPlan);

    if (draft.categoryId == null && draft.kind != DraftKind.transfer && draft.note.trim().isNotEmpty) {
      final remembered = memory?.categoryFor(packageName: packageName, note: draft.note);
      if (remembered != null) {
        draft = draft.copyWith(
          categoryId: () => remembered,
          issues: {...draft.issues}..remove(DraftIssue.categoryUnknown),
        );
        notes.add(ResolveNote.categoryFromMemory);
      }
    }

    final existing = AutoRecordPolicy.findInLedger(plain, date, ledger);
    if (existing != null) notes.add(ResolveNote.duplicateInLedger);

    return ResolvedCapture(
      composed: composed,
      plainDraft: plain,
      draft: draft,
      plan: plan,
      existing: existing,
      cardClass: cardClassOfDraft(
        draft,
        match: plan.match,
        duplicate: existing != null,
        planUnclear: plan.boundUnclear || plan.ambiguous,
      ),
      notes: notes,
    );
  }
}
