import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/capture/capture.dart';

import '../benchmark/capture_benchmark_dataset.dart';

/// Dataset benchmark teks Catat Cerdas (VOICE_INPUT_RESEARCH.md §10), dijalankan
/// lewat interpreter berbasis aturan + resolver. Uji ini juga menjadi alat ukur
/// saat interpreter model (T-11.7/11.8) dibandingkan: kasus yang sama, draf
/// yang sama.
void main() {
  const wallets = benchmarkWallets;
  final categories = benchmarkCategories;
  final resolver = CaptureDraftResolver(wallets: wallets, categories: categories, language: indonesian);
  final now = benchmarkNow;
  final context = InterpretationContext(
    walletNames: [for (final w in wallets) w.name],
    expenseCategoryNames: const [],
    incomeCategoryNames: const [],
    today: now,
    currencyCode: 'IDR',
  );

  RecordDraft draftIn(CaptureLanguage language, String text) {
    final interpreter = RuleBasedTransactionInterpreter(language: language, categories: () => categories);
    final evidence = CaptureEvidence(
      source: CaptureSource.voice,
      text: text,
      capturedAt: now,
      languageCode: language.code,
    );
    return CaptureDraftResolver(
      wallets: wallets,
      categories: categories,
      language: language,
    ).resolve(evidence, interpreter.interpretSync(text, context));
  }

  RecordDraft draftOf(String text) => draftIn(indonesian, text);

  final cases = indonesianCases;

  for (final (text, kind, units, wallet, toWallet, category, issues) in cases) {
    test('"$text"', () {
      final draft = draftOf(text);
      expect(draft.kind, kind, reason: 'jenis');
      expect(draft.amountSen, units == null ? null : units * 100, reason: 'nominal');
      expect(draft.walletId, wallet, reason: 'dompet');
      expect(draft.toWalletId, toWallet, reason: 'dompet tujuan');
      expect(draft.categoryId, category, reason: 'kategori');
      expect(draft.issues, issues, reason: 'masalah');
    });
  }

  test('catatan membuang nominal, dompet berpreposisi, dan kata pengisi', () {
    expect(draftOf('Tadi makan siang 35 ribu pakai BCA').note, 'makan siang');
    expect(draftOf('Gaji bulan ini 12 juta masuk BCA').note, 'Gaji bulan ini');
  });

  test('"kemarin" memundurkan tanggal satu hari; suara tanpa tanggal memakai tanggal bawaan formulir', () {
    expect(draftOf('kemarin makan 40 ribu').date, DateTime(2026, 9, 29, 12));
    expect(draftOf('makan 40 ribu').date, isNull);
  });

  group('tanggal pasti (ADR-029 §3.2), diucapkan 30 Sep 2026', () {
    test('"tanggal 27 september": nominal 5000, tanggal 27 Sep, angka tanggal bukan nominal', () {
      final draft = draftOf('beli kopi 5000 tanggal 27 september');
      expect(draft.amountSen, 500000);
      expect(draft.date, DateTime(2026, 9, 27, 12));
      expect(draft.note, 'beli kopi');
    });

    test('tanpa tahun: tanggal terdekat yang sudah lewat', () {
      expect(draftOf('makan 20 ribu 5 oktober').date, DateTime(2025, 10, 5, 12));
      expect(draftOf('makan 20 ribu tanggal 31').date, DateTime(2026, 8, 31, 12));
      expect(draftOf('makan 20 ribu tgl 3').date, DateTime(2026, 9, 3, 12));
    });

    test('relatif dan angka', () {
      expect(draftOf('makan 20 ribu 2 hari lalu').date, DateTime(2026, 9, 28, 12));
      expect(draftOf('kemarin lusa makan 40 ribu').date, DateTime(2026, 9, 28, 12));
      expect(draftOf('makan 20 ribu 27/9').date, DateTime(2026, 9, 27, 12));
    });

    test('tahun disebut tetapi di masa depan: disorot, tanggal bawaan', () {
      final draft = draftOf('makan 20 ribu 5 oktober 2026');
      expect(draft.date, isNull);
      expect(draft.issues, {DraftIssue.dateUnclear});
    });
  });

  group('paket bahasa Inggris (ADR-029 §3.1)', () {
    for (final (text, kind, units, wallet, toWallet, category, issues) in englishCases) {
      test('"$text"', () {
        final draft = draftIn(english, text);
        expect(draft.kind, kind, reason: 'jenis');
        expect(draft.amountSen, units == null ? null : units * 100, reason: 'nominal');
        expect(draft.walletId, wallet, reason: 'dompet');
        expect(draft.toWalletId, toWallet, reason: 'dompet tujuan');
        expect(draft.categoryId, category, reason: 'kategori');
        expect(draft.issues, issues, reason: 'masalah');
      });
    }

    test('tanggal bahasa Inggris', () {
      expect(draftIn(english, 'coffee 25k yesterday').date, DateTime(2026, 9, 29, 12));
      expect(draftIn(english, 'paid 5,000 for parking on September 27th').date, DateTime(2026, 9, 27, 12));
      expect(draftIn(english, 'lunch 40k on the 3rd').date, DateTime(2026, 9, 3, 12));
      expect(draftIn(english, 'lunch 40k 9/27').date, DateTime(2026, 9, 27, 12));
    });

    test('catatan bahasa Inggris membuang nominal dan dompet berpreposisi', () {
      expect(draftIn(english, 'lunch with friends 35 thousand using BCA').note, 'lunch with friends');
    });
  });

  group('pagar halusinasi (keluaran model palsu)', () {
    final evidence = CaptureEvidence(
      source: CaptureSource.voice,
      text: 'makan siang 35 ribu',
      capturedAt: now,
      languageCode: 'id',
    );

    test('nominal yang tidak ada di teks ditolak', () {
      final draft = resolver.resolve(evidence, const InterpretedTransaction(kind: e, amountText: '350 ribu'));
      expect(draft.amountSen, isNull);
      expect(draft.issues, {DraftIssue.amountMissing});
    });

    test('dompet dan kategori karangan tidak dibuat', () {
      final draft = resolver.resolve(
        evidence,
        const InterpretedTransaction(kind: e, amountText: '35 ribu', walletText: 'Mandiri', categoryName: 'Kuliner'),
      );
      expect(draft.amountSen, 3500000);
      expect(draft.walletId, isNull);
      expect(draft.categoryId, isNull);
      expect(draft.issues, {DraftIssue.walletUnknown, DraftIssue.categoryUnknown});
    });

    test('notifikasi memakai waktu notifikasinya sebagai tanggal', () {
      final notification = CaptureEvidence(
        source: CaptureSource.notification,
        text: 'Pembayaran Rp35.000,00 berhasil',
        capturedAt: DateTime(2026, 9, 28, 9),
        languageCode: 'id',
      );
      final draft = resolver.resolve(notification, const InterpretedTransaction(amountText: 'Rp35.000,00'));
      expect(draft.amountSen, 3500000);
      expect(draft.date, DateTime(2026, 9, 28, 9));
    });

    test('tanggal yang kutipannya tidak ada di teks ditolak', () {
      final draft = resolver.resolve(
        evidence,
        InterpretedTransaction(kind: e, amountText: '35 ribu', dateText: 'tanggal 1', date: DateTime(2026, 9, 2)),
      );
      expect(draft.date, isNull);
      expect(draft.issues, {DraftIssue.dateUnclear});
    });

    test('tanggal tanpa kutipan diabaikan', () {
      final draft = resolver.resolve(
        evidence,
        InterpretedTransaction(kind: e, amountText: '35 ribu', date: DateTime(2026, 9, 2)),
      );
      expect(draft.date, isNull);
      expect(draft.issues, isEmpty);
    });

    test('tanggal masa depan dari model ditolak', () {
      final draft = resolver.resolve(
        evidence,
        InterpretedTransaction(kind: e, amountText: '35 ribu', dateText: 'makan siang', date: DateTime(2026, 10, 2)),
      );
      expect(draft.date, isNull);
      expect(draft.issues, {DraftIssue.dateUnclear});
    });
  });
}
