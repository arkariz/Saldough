import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/data/capture/rule_based_transaction_interpreter.dart';
import 'package:saldough/features/record/domain/capture/capture_draft_resolver.dart';
import 'package:saldough/features/record/domain/capture/capture_evidence.dart';
import 'package:saldough/features/record/domain/capture/interpreted_transaction.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
import 'package:saldough/features/record/domain/capture/transaction_interpreter.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Dataset benchmark teks Catat Cerdas (VOICE_INPUT_RESEARCH.md §10), dijalankan
/// lewat interpreter berbasis aturan + resolver. Uji ini juga menjadi alat ukur
/// saat interpreter model (T-11.7/11.8) dibandingkan: kasus yang sama, draf
/// yang sama.
void main() {
  const wallets = [
    Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    Wallet(id: 'cash', name: 'Cash', iconKey: 'walletCash', initialBalance: 0, currentBalance: 0),
    Wallet(id: 'gopay', name: 'GoPay', iconKey: 'walletEwallet', initialBalance: 0, currentBalance: 0),
  ];
  const names = {
    'food': 'Makan & Minum',
    'groceries': 'Belanja Harian',
    'transport': 'Transportasi',
    'bills': 'Tagihan',
    'internet': 'Pulsa & Internet',
    'health': 'Kesehatan',
    'entertainment': 'Hiburan',
    'shopping': 'Belanja',
    'education': 'Pendidikan',
    'family': 'Keluarga',
    'donation': 'Donasi',
    'expenseOther': 'Lainnya',
    'salary': 'Gaji',
    'freelance': 'Freelance',
    'bonus': 'Bonus',
    'gift': 'Hadiah',
    'incomeOther': 'Lainnya',
  };
  final categories = [
    for (final b in BuiltInCategories.all) Category(id: b.id, kind: b.kind, name: names[b.key]!, builtInKey: b.key),
  ];
  final interpreter = RuleBasedTransactionInterpreter(categories: () => categories);
  final resolver = CaptureDraftResolver(wallets: wallets, categories: categories);
  final now = DateTime(2026, 9, 30, 12);
  final context = InterpretationContext(
    walletNames: [for (final w in wallets) w.name],
    expenseCategoryNames: const [],
    incomeCategoryNames: const [],
    today: now,
  );

  RecordDraft draftOf(String text) {
    final evidence = CaptureEvidence(source: CaptureSource.voice, text: text, capturedAt: now);
    return resolver.resolve(evidence, interpreter.interpretSync(text, context));
  }

  const e = DraftKind.expense;
  const i = DraftKind.income;
  const t = DraftKind.transfer;

  /// (teks, jenis, nominal satuan utama, dompet, dompet tujuan, kategori, masalah)
  final cases = <(String, DraftKind, int?, String?, String?, String?, Set<DraftIssue>)>[
    // Sederhana
    ('makan 25 ribu', e, 25000, null, null, 'builtin.food', {}),
    ('parkir 5 ribu', e, 5000, null, null, 'builtin.transport', {}),
    ('gaji 10 juta', i, 10000000, null, null, 'builtin.salary', {}),
    // Bahasa alami
    ('tadi siang makan ayam geprek dua puluh lima ribu', e, 25000, null, null, 'builtin.food', {}),
    ('barusan beli kopi sebelum meeting', e, null, null, null, 'builtin.food', {DraftIssue.amountMissing}),
    ('makan siang tiga puluh lima ribu', e, 35000, null, null, 'builtin.food', {}),
    ('tadi beli kopi dua puluh lima ribu', e, 25000, null, null, 'builtin.food', {}),
    ('bayar listrik dua ratus lima puluh ribu', e, 250000, null, null, 'builtin.bills', {}),
    ('gaji masuk dua belas juta', i, 12000000, null, null, 'builtin.salary', {}),
    ('isi bensin seratus ribu', e, 100000, null, null, 'builtin.transport', {}),
    ('beli shampoo dan sabun total tujuh puluh dua ribu', e, 72000, null, null, null, {}),
    // Dompet
    ('Tadi makan siang 35 ribu pakai BCA', e, 35000, 'bca', null, 'builtin.food', {}),
    ('ojek 15 ribu bayarnya cash', e, 15000, 'cash', null, 'builtin.transport', {}),
    ('gaji 12 juta masuk ke GoPay', i, 12000000, 'gopay', null, 'builtin.salary', {}),
    ('Gaji bulan ini 12 juta masuk BCA', i, 12000000, 'bca', null, 'builtin.salary', {}),
    ('makan 20 ribu pakai BRI', e, 20000, null, null, 'builtin.food', {DraftIssue.walletUnknown}),
    // Transfer
    ('transfer lima ratus ribu dari BCA', t, 500000, 'bca', null, null, {DraftIssue.transferTargetMissing}),
    ('transfer 200 ribu dari BCA ke GoPay', t, 200000, 'bca', 'gopay', null, {}),
    ('top up GoPay 100k', t, 100000, null, 'gopay', null, {DraftIssue.transferSourceMissing}),
    ('top up GoPay 100 ribu dari BCA', t, 100000, 'bca', 'gopay', null, {}),
    // Ambigu
    ('tadi belanja', e, null, null, null, 'builtin.shopping', {DraftIssue.amountMissing}),
    ('bayar tagihan', e, null, null, null, 'builtin.bills', {DraftIssue.amountMissing}),
    (
      'transfer uang',
      t,
      null,
      null,
      null,
      null,
      {DraftIssue.amountMissing, DraftIssue.transferSourceMissing, DraftIssue.transferTargetMissing},
    ),
    ('beli dua kopi lima puluh ribu', e, 50000, null, null, 'builtin.food', {}),
    ('kopi 25 ribu roti 15 ribu', e, null, null, null, 'builtin.food', {DraftIssue.amountMultiple}),
    ('parkir 5', e, null, null, null, 'builtin.transport', {DraftIssue.amountWithoutUnit}),
    ('kopi 5,000', e, null, null, null, 'builtin.food', {DraftIssue.amountAmbiguous}),
    ('dapat 10 dolar', i, null, null, null, null, {DraftIssue.currencyUnsupported}),
    // Campur bahasa
    ('coffee 25 ribu pakai BCA', e, 25000, 'bca', null, 'builtin.food', {}),
    ('tadi ngopi 25k', e, 25000, null, null, 'builtin.food', {}),
    // Regresi verifikasi M1 (F2, F4, F5).
    ('bayar masuk tol 20 ribu', e, 20000, null, null, 'builtin.transport', {}),
    ('dapat diskon beli baju 100 ribu', e, 100000, null, null, 'builtin.shopping', {}),
    ('beli pulsa bonus kuota 50 ribu', e, 50000, null, null, 'builtin.internet', {}),
    ('beli air mineral 5 ribu', e, 5000, null, null, null, {}),
    ('uang masuk 500 ribu', i, 500000, null, null, null, {}),
    ('bonus 1 juta', i, 1000000, null, null, 'builtin.bonus', {}),
    ('kopi 25 ribu 2 gelas', e, 25000, null, null, 'builtin.food', {}),
    ('gaji satu setengah juta', i, 1500000, null, null, 'builtin.salary', {}),
  ];

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

  group('pagar halusinasi (keluaran model palsu)', () {
    final evidence = CaptureEvidence(source: CaptureSource.voice, text: 'makan siang 35 ribu', capturedAt: now);

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
      );
      final draft = resolver.resolve(notification, const InterpretedTransaction(amountText: 'Rp35.000,00'));
      expect(draft.amountSen, 3500000);
      expect(draft.date, DateTime(2026, 9, 28, 9));
    });
  });
}
