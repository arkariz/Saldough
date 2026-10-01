import 'package:saldough/features/record/domain/capture/capture_evidence.dart';
import 'package:saldough/features/record/domain/capture/interpreted_transaction.dart';
import 'package:saldough/features/record/domain/capture/language/capture_language.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
import 'package:saldough/features/record/domain/capture/spoken_amount_parser.dart';
import 'package:saldough/features/record/domain/capture/spoken_date_parser.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Mengubah keluaran interpreter mana pun menjadi [RecordDraft] (ADR-027
/// §3.3). Deterministik dan sama untuk semua penyedia — inilah pagar yang
/// mencegah keluaran model mengarang data:
///
/// - nominal hanya diambil dari frasa yang **benar-benar ada** di teks bukti,
///   lalu dihitung [SpokenAmountParser] dalam `int` sen -- dan nilainya harus
///   sama dengan frasa bilangan utuh di teks itu, jadi kutipan yang memotong
///   angka ("350" dari "350 ribu") ditolak;
/// - dompet dan kategori hanya dicocokkan ke daftar yang ada, tidak pernah
///   dibuat;
/// - tanggal hanya dipakai bila kutipannya ada di teks bukti, tidak di masa
///   depan, dan -- bila paket bahasa mengenali kutipannya -- sama dengan
///   tafsiran [SpokenDateParser];
/// - hal yang meragukan menjadi [DraftIssue], bukan tebakan.
///
/// Resolver tidak mengenal kata bahasa apa pun (ADR-029 §3.1): bilangan kata
/// dan sinonim tunai datang dari [language], atau hanya digit bila bahasa
/// bukti tidak punya paket.
final class CaptureDraftResolver {
  /// Membuat [CaptureDraftResolver] untuk [wallets] aktif dan [categories].
  const CaptureDraftResolver({
    required this.wallets,
    required this.categories,
    this.currencyCode = 'IDR',
    this.language,
  });

  /// Dompet aktif yang boleh dipilih.
  final List<Wallet> wallets;

  /// Seluruh kategori (yang terarsip tidak dipilih).
  final List<Category> categories;

  /// Kode ISO mata uang aplikasi (ADR-025).
  final String currencyCode;

  /// Paket bahasa bukti, atau `null` bila bahasanya tidak punya paket.
  final CaptureLanguage? language;

  /// Menyusun draf dari [interpreted] untuk [evidence].
  RecordDraft resolve(CaptureEvidence evidence, InterpretedTransaction interpreted) {
    final kind = interpreted.kind ?? DraftKind.expense;
    final issues = <DraftIssue>{
      // Notifikasi menyatakan arah dengan kata baku; tanpa itu bawaan
      // pengeluaran hanya tebakan (ADR-032 §3.3).
      if (interpreted.kind == null && evidence.source == CaptureSource.notification) DraftIssue.kindUnclear,
    };

    final amountSen = _resolveAmount(evidence.text, interpreted.amountText, issues);

    String? walletId;
    String? toWalletId;
    if (kind == DraftKind.transfer) {
      walletId = _resolveWallet(interpreted.walletText, issues);
      toWalletId = _resolveWallet(interpreted.toWalletText, issues);
      if (walletId != null && walletId == toWalletId) toWalletId = null;
      if (walletId == null) issues.add(DraftIssue.transferSourceMissing);
      if (toWalletId == null) issues.add(DraftIssue.transferTargetMissing);
    } else {
      walletId = _resolveWallet(interpreted.walletText, issues);
    }

    String? categoryId;
    final categoryName = interpreted.categoryName?.trim() ?? '';
    if (kind != DraftKind.transfer && categoryName.isNotEmpty) {
      final categoryKind = kind == DraftKind.income ? CategoryKind.income : CategoryKind.expense;
      final match = matchCategory(categories.where((c) => !c.isArchived), categoryKind, categoryName);
      if (match == null) {
        issues.add(DraftIssue.categoryUnknown);
      } else {
        categoryId = match.id;
      }
    }

    return RecordDraft(
      kind: kind,
      amountSen: amountSen,
      walletId: walletId,
      toWalletId: toWalletId,
      categoryId: categoryId,
      note: interpreted.note?.trim() ?? '',
      date: _resolveDate(evidence, interpreted, issues),
      issues: issues,
      sourceText: evidence.text,
    );
  }

  int? _resolveAmount(String evidenceText, String? amountText, Set<DraftIssue> issues) {
    final phrase = amountText?.trim() ?? '';
    // Kutipan yang tidak ada di teks bukti adalah karangan -- abaikan.
    if (phrase.isEmpty || !_normalize(evidenceText).contains(_normalize(phrase))) {
      issues.add(DraftIssue.amountMissing);
      return null;
    }
    final lexicon = language?.numbers ?? NumberLexicon.neutral;
    final result = SpokenAmountParser.parse(phrase, lexicon: lexicon, currencyCode: currencyCode);
    switch (result.issue) {
      case null:
        if (_isWholeAmount(evidenceText, phrase, result.sen, lexicon)) return result.sen;
        issues.add(DraftIssue.amountMissing);
      case SpokenAmountIssue.missing:
        issues.add(DraftIssue.amountMissing);
      case SpokenAmountIssue.multiple:
        issues.add(DraftIssue.amountMultiple);
      case SpokenAmountIssue.withoutUnit:
        issues.add(DraftIssue.amountWithoutUnit);
      case SpokenAmountIssue.ambiguous:
        issues.add(DraftIssue.amountAmbiguous);
      case SpokenAmountIssue.foreignCurrency:
        issues.add(DraftIssue.currencyUnsupported);
    }
    return null;
  }

  /// `true` bila salah satu kemunculan [phrase] di [evidenceText] bertumpang
  /// tindih dengan frasa bilangan utuh bernilai [sen]. Kutipan yang memotong
  /// angka ("5 ribu" dari "25 ribu", "2000" dari "20000") tetap substring,
  /// tetapi nilainya berbeda dari frasa utuhnya.
  bool _isWholeAmount(String evidenceText, String phrase, int? sen, NumberLexicon lexicon) {
    final text = _normalize(evidenceText);
    final spans = SpokenAmountParser.findAll(text, lexicon: lexicon);
    return _occurrences(text, _normalize(phrase)).any(
      (at) => spans.any((s) => s.start < at.$2 && at.$1 < s.end && s.sen == sen),
    );
  }

  String? _resolveWallet(String? spoken, Set<DraftIssue> issues) {
    final text = spoken?.trim() ?? '';
    if (text.isEmpty) return null;
    final wallet = matchWallet(wallets, text, cashWords: language?.cashWords ?? const {});
    if (wallet == null) issues.add(DraftIssue.walletUnknown);
    return wallet?.id;
  }

  /// Tanggal tafsiran interpreter, bila kutipannya ada di teks bukti dan
  /// tanggalnya sah (ADR-029 §3.2). Tanpa sebutan tanggal: suara dicatat saat
  /// diucapkan (tanggal bawaan formulir); notifikasi dan struk memakai waktu
  /// buktinya.
  DateTime? _resolveDate(CaptureEvidence evidence, InterpretedTransaction interpreted, Set<DraftIssue> issues) {
    final fallback = evidence.source == CaptureSource.voice ? null : evidence.capturedAt;
    final quote = interpreted.dateText?.trim() ?? '';
    if (quote.isEmpty) return fallback;
    final date = interpreted.date;
    final captured = evidence.capturedAt;
    final valid =
        date != null &&
        _normalize(evidence.text).contains(_normalize(quote)) &&
        !DateTime(date.year, date.month, date.day).isAfter(DateTime(captured.year, captured.month, captured.day)) &&
        date.year >= 2000 &&
        _dateAgrees(evidence, quote, date);
    if (valid) return date;
    issues.add(DraftIssue.dateUnclear);
    return fallback;
  }

  /// `false` bila paket bahasa mengenali [quote] sebagai tanggal lain dari
  /// [date] ("kemarin" tetapi model menjawab 1 Sep). Kutipan yang tidak
  /// dikenali paket (atau bahasa tanpa paket) dipercaya ke model.
  bool _dateAgrees(CaptureEvidence evidence, String quote, DateTime date) {
    final language = this.language;
    if (language == null) return true;
    final text = _normalize(evidence.text);
    final spans = SpokenDateParser.findAll(
      text,
      lexicon: language.dates,
      numbers: language.numbers,
      today: evidence.capturedAt,
    );
    var recognized = false;
    for (final at in _occurrences(text, _normalize(quote))) {
      for (final span in spans.where((s) => s.start < at.$2 && at.$1 < s.end)) {
        recognized = true;
        final parsed = span.date;
        if (parsed != null && parsed.year == date.year && parsed.month == date.month && parsed.day == date.day) {
          return true;
        }
      }
    }
    return !recognized;
  }
}

/// Rentang (awal, akhir) setiap kemunculan [needle] di [text].
Iterable<(int, int)> _occurrences(String text, String needle) sync* {
  if (needle.isEmpty) return;
  for (var at = text.indexOf(needle); at >= 0; at = text.indexOf(needle, at + 1)) {
    yield (at, at + needle.length);
  }
}

/// Dompet di [wallets] yang dirujuk [spoken]: nama sama persis (tanpa beda
/// huruf/spasi), lalu satu-satunya dompet yang namanya memuat atau dimuat
/// sebutan itu sebagai kata utuh, lalu sinonim tunai [cashWords] dari paket
/// bahasa ("cash", "tunai", "dompet" merujuk dompet yang sama). `null` kalau
/// tidak ada atau lebih dari satu kandidat -- tidak menebak.
Wallet? matchWallet(List<Wallet> wallets, String spoken, {Set<String> cashWords = const {}}) {
  final needle = _normalize(spoken);
  if (needle.isEmpty) return null;
  for (final wallet in wallets) {
    if (_normalize(wallet.name) == needle) return wallet;
  }
  final partial = [
    for (final wallet in wallets)
      if (_containsWord(_normalize(wallet.name), needle) || _containsWord(needle, _normalize(wallet.name))) wallet,
  ];
  if (partial.length == 1) return partial.single;
  if (cashWords.contains(needle)) {
    final cash = [
      for (final wallet in wallets)
        if (cashWords.any((w) => _containsWord(_normalize(wallet.name), w)) || wallet.iconKey == 'walletCash') wallet,
    ];
    if (cash.length == 1) return cash.single;
  }
  return null;
}

bool _containsWord(String haystack, String needle) =>
    RegExp('(^|\\s)${RegExp.escape(needle)}(\\s|\$)').hasMatch(haystack);

String _normalize(String text) => text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
