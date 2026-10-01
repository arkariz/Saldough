import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/capture/domain/capture_evidence.dart';
import 'package:saldough/shared/capture/domain/interpreted_transaction.dart';
import 'package:saldough/shared/capture/domain/language/capture_language.dart';
import 'package:saldough/shared/capture/domain/spoken_amount_parser.dart';
import 'package:saldough/shared/capture/domain/spoken_date_parser.dart';
import 'package:saldough/shared/capture/domain/transaction_interpreter.dart';
import 'package:saldough/shared/category/category.dart';

/// Interpreter tanpa model: kata kunci, [SpokenAmountParser],
/// [SpokenDateParser], dan pencocokan nama dompet/kategori (ADR-027, riset
/// §11). Offline, gratis, dan dalam hitungan milidetik; menangani pola
/// "aktivitas + nominal + (dompet) + (tanggal)".
///
/// Seluruh kata datang dari [language] (ADR-029 §3.1): satu instans per
/// bahasa, logika yang sama untuk semua bahasa.
///
/// Kalau tidak yakin, interpreter ini tidak menebak: kutipannya dibiarkan
/// kosong atau berisi teks utuh supaya `CaptureDraftResolver` melaporkan
/// masalahnya (mis. dua nominal).
final class RuleBasedTransactionInterpreter implements TransactionInterpreter {
  /// Membuat [RuleBasedTransactionInterpreter] untuk [language].
  /// [categories] dibaca setiap kali menafsirkan (alias kategori bawaan ikut
  /// dipakai).
  const RuleBasedTransactionInterpreter({required this.language, required this.categories});

  /// Paket bahasa.
  final CaptureLanguage language;

  /// Sumber kategori terkini.
  final List<Category> Function() categories;

  @override
  Future<Either<Failure, InterpretedTransaction>> interpret(
    CaptureEvidence evidence,
    InterpretationContext context,
  ) async => right(interpretSync(evidence.text, context));

  /// Versi sinkron [interpret], untuk uji dan kaskade.
  InterpretedTransaction interpretSync(String text, InterpretationContext context) {
    final lower = text.toLowerCase();
    final kind = _kindOf(lower);

    // Tanggal lebih dulu: angkanya ("tanggal 27") bukan calon nominal.
    final dates = SpokenDateParser.findAll(
      text,
      lexicon: language.dates,
      numbers: language.numbers,
      today: context.today,
    );
    final dateSpans = [for (final d in dates) (d.start, d.end)];
    final amounts = [
      for (final amount in SpokenAmountParser.findAll(text, lexicon: language.numbers))
        if (!dateSpans.any((s) => amount.start < s.$2 && s.$1 < amount.end)) amount,
    ];
    final spans = [for (final amount in amounts) (amount.start, amount.end), ...dateSpans];

    final wallets = _findWallets(lower, context.walletNames, spans);
    String? walletText;
    String? toWalletText;
    if (kind == DraftKind.transfer) {
      walletText = wallets.from;
      toWalletText = wallets.to;
    } else {
      walletText = wallets.any;
    }

    return InterpretedTransaction(
      kind: kind,
      amountText: _amountQuote(text, amounts, context.currencyCode),
      walletText: walletText,
      toWalletText: toWalletText,
      categoryName: kind == DraftKind.transfer ? null : _findCategory(lower, kind, spans),
      note: _noteOf(text, spans),
      dateText: dates.isEmpty ? null : dates.first.text,
      date: dates.isEmpty ? null : dates.first.date,
    );
  }

  /// Kutipan nominal: frasa terpilih ([SpokenAmountParser.select]), atau teks
  /// utuh bila ada lebih dari satu, supaya resolver melaporkan alasannya
  /// alih-alih memilih salah satu.
  String? _amountQuote(String text, List<SpokenAmount> amounts, String currencyCode) {
    final picked = SpokenAmountParser.select(amounts, currencyCode: currencyCode);
    return switch (picked.issue) {
      SpokenAmountIssue.missing => null,
      SpokenAmountIssue.multiple || SpokenAmountIssue.foreignCurrency => text,
      null || SpokenAmountIssue.ambiguous || SpokenAmountIssue.withoutUnit => picked.amount!.text,
    };
  }

  /// Jenis dari kata kunci. Kata pemasukan yang juga lazim di kalimat
  /// pengeluaran ("masuk tol", "dapat diskon", "bonus kuota") hanya dihitung
  /// kalau tidak ada tanda pengeluaran di kalimat yang sama.
  DraftKind _kindOf(String lower) {
    bool any(List<String> words) => words.any((w) => _hasWord(lower, w));
    if (any(language.transferWords)) return DraftKind.transfer;
    if (any(language.incomeWords)) return DraftKind.income;
    if (any(language.weakIncomeWords) && !any(language.expenseCues)) return DraftKind.income;
    return DraftKind.expense;
  }

  /// Kategori pertama (frasa terpanjang lebih dulu) yang cocok nama atau
  /// alias kategori aktif berjenis [kind].
  String? _findCategory(String lower, DraftKind kind, List<(int, int)> spans) {
    final categoryKind = kind == DraftKind.income ? CategoryKind.income : CategoryKind.expense;
    final active = categories().where((c) => !c.isArchived && c.kind == categoryKind).toList();
    final words = [
      for (final m in RegExp('[a-z&]+').allMatches(lower))
        if (!spans.any((s) => m.start >= s.$1 && m.end <= s.$2)) m.group(0)!,
    ];
    for (var size = 3; size >= 1; size--) {
      for (var i = 0; i + size <= words.length; i++) {
        final match = matchCategory(active, categoryKind, words.sublist(i, i + size).join(' '));
        if (match != null) return match.name;
      }
    }
    return null;
  }

  /// Catatan: teks tanpa nominal dan tanggal, sebutan dompet berpreposisi di
  /// akhir, kata pengisi, dan kata kunci transfer.
  String _noteOf(String text, List<(int, int)> spans) {
    final buffer = StringBuffer();
    var cursor = 0;
    for (final span in [...spans]..sort((a, b) => a.$1.compareTo(b.$1))) {
      if (span.$1 < cursor) continue;
      buffer
        ..write(text.substring(cursor, span.$1))
        ..write(' ');
      cursor = span.$2;
    }
    buffer.write(text.substring(cursor));
    var note = buffer.toString();
    // Sebutan dompet berpreposisi ("pakai BCA", "masuk ke GoPay").
    note = note.replaceAll(
      RegExp('\\b(?:${_alt(language.noteWalletPrepositions)})\\s+\\S+\\s*\$', caseSensitive: false),
      ' ',
    );
    final kept = [
      for (final word in note.split(RegExp(r'\s+')))
        if (word.isNotEmpty && !language.fillerWords.contains(word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '')))
          word,
    ];
    return kept.join(' ').replaceAll(RegExp(r'^[,.\s]+|[,.\s]+$'), '');
  }

  /// Dompet yang disebut di [lower]: asal ("dari X"), tujuan ("ke X", "top
  /// up X"), dan sebutan bebas pertama. Nama yang tidak dikenal hanya diambil
  /// setelah preposisi yang jelas-jelas menunjuk dompet, supaya "ke kantor"
  /// tidak dianggap dompet.
  ({String? from, String? to, String? any}) _findWallets(
    String lower,
    List<String> walletNames,
    List<(int, int)> spans,
  ) {
    final mentions = <(int, String)>[];
    for (final name in walletNames) {
      final pattern = RegExp('(^|[^a-z0-9])(${RegExp.escape(name.toLowerCase())})(?=[^a-z0-9]|\$)');
      for (final m in pattern.allMatches(lower)) {
        mentions.add((m.start + m.group(1)!.length, name));
      }
    }
    final cashMentions = language.cashMentions;
    for (final word in cashMentions) {
      if (mentions.any((m) => cashMentions.contains(m.$2.toLowerCase()))) break;
      final m = RegExp('(^|[^a-z])${RegExp.escape(word)}(?=[^a-z]|\$)').firstMatch(lower);
      if (m != null) mentions.add((m.start + m.group(1)!.length, word));
    }
    mentions.sort((a, b) => a.$1.compareTo(b.$1));

    String? after(List<String> prepositions) {
      if (prepositions.isEmpty) return null;
      for (final m in RegExp('\\b(?:${_alt(prepositions)})\\s+').allMatches(lower)) {
        final at = m.end;
        for (final mention in mentions) {
          if (mention.$1 == at) return mention.$2;
        }
        // Nama tak dikenal setelah preposisi dompet: kutip apa adanya supaya
        // resolver menandainya "dompet tidak dikenal".
        final next = RegExp('[a-z][a-z0-9]*').matchAsPrefix(lower, at);
        if (next != null &&
            !language.fillerWords.contains(next.group(0)) &&
            !spans.any((s) => at >= s.$1 && at < s.$2)) {
          return next.group(0);
        }
      }
      return null;
    }

    return (
      from: after(language.fromPrepositions),
      to: after(language.toPrepositions),
      any: after(language.viaPrepositions) ?? (mentions.isEmpty ? null : mentions.first.$2),
    );
  }
}

/// Alternasi regex, frasa terpanjang lebih dulu.
String _alt(List<String> words) {
  final sorted = [...words]..sort((a, b) => b.length.compareTo(a.length));
  return sorted.map(RegExp.escape).join('|');
}

bool _hasWord(String lower, String word) => RegExp('(^|[^a-z])${RegExp.escape(word)}(?=[^a-z]|\$)').hasMatch(lower);
