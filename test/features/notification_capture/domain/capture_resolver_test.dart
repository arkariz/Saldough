import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_card_class.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_resolver.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

import 'notification_fixtures.dart';

final class _Memory implements MerchantMemory {
  _Memory(this.byNote);

  final Map<String, String> byNote;

  @override
  String? categoryFor({required String packageName, required String note}) => byNote[note];
}

void main() {
  final postedAt = DateTime(2026, 11, 4, 10);
  var ledger = <Transaction>[];

  CapturedNotification notif(String body, {String id = 'n1'}) =>
      CapturedNotification(id: id, packageName: 'id.co.bri.brimo', title: '', body: body, postedAt: postedAt);

  RecurringRule rule(
    String id,
    String name, {
    int amount = 5400000,
    String? category = 'builtin.bills',
    RecurringAmountMode mode = RecurringAmountMode.fixed,
  }) => RecurringRule(
    id: id,
    kind: RecurringKind.expense,
    amount: amount,
    amountMode: mode,
    walletId: 'bri',
    note: name,
    categoryId: category,
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 10, 4)),
  );

  Future<ResolvedCapture> resolve(
    String body, {
    List<RecurringRule> rules = const [],
    List<NotificationPattern> patterns = const [],
    MerchantMemory? memory,
  }) =>
      CaptureResolver(
        composer: notificationComposer(),
        ledgerAround: (_) async => ledger,
        memory: memory,
      ).resolve(
        notif(body),
        source: brimoSource,
        patterns: patterns,
        wallets: notificationWallets,
        categories: notificationCategories,
        currencyCode: 'IDR',
        languageCode: 'id',
        rules: rules,
      );

  // Pedagang tanpa alias kategori, supaya kategori hanya bisa datang dari rencana atau ingatan.
  const unknownMerchant = 'Pembayaran Rp54.000 ke ZXQ LAYANAN berhasil';

  setUp(() => ledger = []);

  group('urutan: rencana, ingatan, aturan umum', () {
    test('tanpa rutin dan tanpa kategori terbaca: perlu diisi, jejak kosong', () async {
      final result = await resolve(unknownMerchant);

      expect(result.plainDraft.categoryId, isNull);
      expect(result.plan.match, isNull);
      expect(result.notes, isEmpty);
      expect(result.cardClass, CaptureCardClass.needsInput);
    });

    test('aturan umum membaca kategori dari alias: dikenali tanpa rutin', () async {
      final result = await resolve('Pembayaran Rp25.000 ke KOPI KENANGAN berhasil');

      expect(result.draft.categoryId, isNotNull);
      expect(result.cardClass, CaptureCardClass.recognized);
    });

    test('rutin tunggal yang cocok: cocok rencana, kategori dan catatan dari rutin', () async {
      final result = await resolve(unknownMerchant, rules: [rule('spotify', 'Spotify')]);

      expect(result.plan.match?.rule.id, 'spotify');
      expect(result.plan.tieBroken, isFalse);
      expect(result.draft.categoryId, 'builtin.bills');
      expect(result.plainDraft.categoryId, isNull, reason: 'draf asli tidak diubah');
      expect(result.notes, containsAllInOrder([ResolveNote.planUnique, ResolveNote.categoryFromPlan]));
      expect(result.draft.issues, isNot(contains(DraftIssue.categoryUnknown)));
      expect(result.cardClass, CaptureCardClass.planned);
    });

    test('rencana mengalahkan ingatan: kategori rutin dipakai, ingatan tidak ditanya', () async {
      final memory = _Memory({'ZXQ LAYANAN': 'builtin.food'});
      final result = await resolve(unknownMerchant, rules: [rule('spotify', 'Spotify')], memory: memory);

      expect(result.draft.categoryId, 'builtin.bills');
      expect(result.notes, isNot(contains(ResolveNote.categoryFromMemory)));
    });

    test('tanpa rencana, ingatan pedagang mengisi kategori', () async {
      final probe = await resolve(unknownMerchant);
      final memory = _Memory({probe.plainDraft.note: 'builtin.bills'});

      final result = await resolve(unknownMerchant, memory: memory);

      expect(result.draft.categoryId, 'builtin.bills');
      expect(result.notes, contains(ResolveNote.categoryFromMemory));
      expect(result.cardClass, CaptureCardClass.recognized);
    });

    test('ingatan yang tidak mengenal pedagang: dilewati', () async {
      final result = await resolve(unknownMerchant, memory: _Memory({}));

      expect(result.draft.categoryId, isNull);
      expect(result.notes, isNot(contains(ResolveNote.categoryFromMemory)));
    });
  });

  group('ambigu tidak ditebak', () {
    test('dua rutin cocok tanpa nama di teks: tanpa saran, perlu diputuskan pengguna', () async {
      final result = await resolve(unknownMerchant, rules: [rule('a', 'Layanan Satu'), rule('b', 'Layanan Dua')]);

      expect(result.plan.match, isNull);
      expect(result.plan.ambiguous, isTrue);
      expect(result.notes, contains(ResolveNote.planAmbiguous));
      expect(result.cardClass, CaptureCardClass.needsInput);
    });

    test('dua rutin cocok, satu namanya ada di teks: dipilih sebagai saran (pemutus seri)', () async {
      final result = await resolve(
        'Pembayaran Rp54.000 ke SPOTIFY PREMIUM berhasil',
        rules: [rule('a', 'Spotify'), rule('b', 'Netflix')],
      );

      expect(result.plan.match?.rule.id, 'a');
      expect(result.plan.tieBroken, isTrue);
      expect(result.notes, contains(ResolveNote.planTieBreak));
    });

    test('dua rutin cocok, kedua nama ada di teks: tetap ambigu', () async {
      final result = await resolve(
        'Pembayaran Rp54.000 ke SPOTIFY NETFLIX berhasil',
        rules: [rule('a', 'Spotify'), rule('b', 'Netflix')],
      );

      expect(result.plan.ambiguous, isTrue);
      expect(result.plan.match, isNull);
    });

    test('nama rutin terlalu pendek tidak dipakai memutus', () async {
      final result = await resolve(
        'Pembayaran Rp54.000 ke XY LAYANAN berhasil',
        rules: [rule('a', 'XY'), rule('b', 'Zz')],
      );

      expect(result.plan.ambiguous, isTrue);
    });

    test('nominal beda: tanpa rencana', () async {
      final result = await resolve(unknownMerchant, rules: [rule('a', 'Spotify', amount: 9900000)]);

      expect(result.plan.match, isNull);
      expect(result.plan.ambiguous, isFalse);
    });

    test('rutin kira-kira dalam ±10%: saran yang tidak persis', () async {
      final result = await resolve(
        unknownMerchant,
        rules: [rule('listrik', 'Listrik', amount: 5500000, mode: RecurringAmountMode.estimated)],
      );

      expect(result.plan.match?.exact, isFalse);
      expect(result.cardClass, CaptureCardClass.planned);
    });
  });

  group('pola terikat ke rutin', () {
    const verified = NotificationPattern(
      id: 'u1',
      packageName: 'id.co.bri.brimo',
      label: 'Layanan',
      template: 'Pembayaran {amount} ke {note} berhasil',
      kind: NotificationPatternKind.expense,
    );

    RecurringRule bound(int amount) => rule('spotify', 'Spotify', amount: amount).withNotificationBinding(
      const NotificationBinding(packageName: 'id.co.bri.brimo', patternId: 'u1', patternLabel: 'Layanan'),
    );

    test('nominal persis: rencana ditentukan pola', () async {
      final result = await resolve(unknownMerchant, rules: [bound(5400000)], patterns: [verified]);

      expect(result.plan.bound, isTrue);
      expect(result.plan.boundUnclear, isFalse);
      expect(result.plan.match?.rule.id, 'spotify');
      expect(result.notes, contains(ResolveNote.planBound));
    });

    test('nominal beda: terikat tetapi tidak jelas, ditinjau dan tidak ditebak', () async {
      final result = await resolve(unknownMerchant, rules: [bound(9900000)], patterns: [verified]);

      expect(result.plan.bound, isTrue);
      expect(result.plan.boundUnclear, isTrue);
      expect(result.plan.match, isNull);
      expect(result.notes, contains(ResolveNote.planBoundUnclear));
      expect(result.cardClass, CaptureCardClass.needsInput);
    });

    test('pola yang belum terverifikasi tidak pernah mengikat', () async {
      const guess = NotificationPattern(
        id: 'u1',
        packageName: 'id.co.bri.brimo',
        label: 'Layanan',
        template: 'Pembayaran {amount} ke {note} berhasil',
        kind: NotificationPatternKind.expense,
        verified: false,
      );
      final result = await resolve(unknownMerchant, rules: [bound(9900000)], patterns: [guess]);

      expect(result.plan.bound, isFalse);
    });
  });

  group('duplikat', () {
    test('catatan yang sama sudah ada: ditandai dan perlu diputuskan, juga bila cocok rencana', () async {
      ledger = [
        ExpenseTransaction(id: 'm', date: postedAt, amount: 5400000, note: 'Spotify', walletId: 'bri'),
      ];

      final result = await resolve(unknownMerchant, rules: [rule('spotify', 'Spotify')]);

      expect(result.existing?.id, 'm');
      expect(result.notes, contains(ResolveNote.duplicateInLedger));
      expect(result.cardClass, CaptureCardClass.needsInput);
    });
  });

  group('kartu tersimpan', () {
    test('resolveStored memberi rencana yang sama dari draf dan teks tersimpan', () async {
      final fresh = await resolve(unknownMerchant, rules: [rule('spotify', 'Spotify')]);
      final entry = CaptureInboxEntry(
        id: 'n1',
        packageName: 'id.co.bri.brimo',
        appLabel: 'BRImo',
        text: unknownMerchant,
        capturedAt: postedAt,
        draft: fresh.plainDraft,
      );

      final stored = await CaptureResolver(
        composer: notificationComposer(),
        ledgerAround: (_) async => ledger,
      ).resolveStored(entry, rules: [rule('spotify', 'Spotify')]);

      expect(stored.plan.match?.rule.id, fresh.plan.match?.rule.id);
      expect(stored.cardClass, fresh.cardClass);
      expect(stored.composed, isNull);
    });
  });

  group('enrichFromPlan', () {
    final match = OccurrenceMatch(rule: rule('spotify', 'Spotify'), date: DateTime(2026, 11, 4), exact: true);

    test('tidak mengganti kategori atau catatan yang sudah terisi', () {
      const draft = RecordDraft(kind: DraftKind.expense, categoryId: 'builtin.food', note: 'Kopi');

      expect(enrichFromPlan(draft, match), draft);
    });

    test('mengisi yang kosong dan menggugurkan isu kategori', () {
      const draft = RecordDraft(kind: DraftKind.expense, issues: {DraftIssue.categoryUnknown});

      final result = enrichFromPlan(draft, match);

      expect(result.categoryId, 'builtin.bills');
      expect(result.note, 'Spotify');
      expect(result.issues, isEmpty);
    });

    test('tanpa kecocokan: draf apa adanya', () {
      const draft = RecordDraft(kind: DraftKind.expense);

      expect(enrichFromPlan(draft, null), draft);
    });
  });
}
