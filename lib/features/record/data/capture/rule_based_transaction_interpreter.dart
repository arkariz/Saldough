import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/utils/formatters/spoken_amount_parser.dart';
import 'package:saldough/features/record/domain/capture/capture_evidence.dart';
import 'package:saldough/features/record/domain/capture/interpreted_transaction.dart';
import 'package:saldough/features/record/domain/capture/transaction_interpreter.dart';
import 'package:saldough/shared/category/category.dart';

/// Interpreter tanpa model: kata kunci, [SpokenAmountParser], dan pencocokan
/// nama dompet/kategori (ADR-027, riset §11). Offline, gratis, dan dalam
/// hitungan milidetik; menangani pola "aktivitas + nominal + (dompet)".
///
/// Kalau tidak yakin, interpreter ini tidak menebak: kutipannya dibiarkan
/// kosong atau berisi teks utuh supaya `CaptureDraftResolver` melaporkan
/// masalahnya (mis. dua nominal).
final class RuleBasedTransactionInterpreter implements TransactionInterpreter {
  /// Membuat [RuleBasedTransactionInterpreter]. [categories] dibaca setiap
  /// kali menafsirkan (alias kategori bawaan ikut dipakai).
  const RuleBasedTransactionInterpreter({required this.categories});

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

    final amounts = SpokenAmountParser.findAll(text);
    final withUnit = amounts.where((a) => a.hasUnit).toList();
    // Satu nominal bersatuan: kutip frasanya. Selain itu kutip teks utuh,
    // supaya resolver melaporkan alasannya (tidak ada, lebih dari satu, tanpa
    // satuan) alih-alih memilih salah satu.
    final amountText = withUnit.length == 1 ? withUnit.single.text : text;

    final spans = <(int, int)>[
      for (final amount in amounts) _spanOf(text, amount.text),
    ];

    final wallets = _findWallets(lower, context.walletNames, spans);
    String? walletText;
    String? toWalletText;
    if (kind == DraftKind.transfer) {
      walletText = wallets.from;
      toWalletText = wallets.to;
    } else {
      walletText = wallets.any;
    }

    final categoryName = kind == DraftKind.transfer ? null : _findCategory(lower, kind, spans);
    final dateText = lower.contains('kemarin lusa') ? 'kemarin lusa' : (lower.contains('kemarin') ? 'kemarin' : null);

    return InterpretedTransaction(
      kind: kind,
      amountText: amountText,
      walletText: walletText,
      toWalletText: toWalletText,
      categoryName: categoryName,
      note: _noteOf(text, spans),
      dateText: dateText,
    );
  }

  /// Jenis dari kata kunci. Kata pemasukan yang juga lazim di kalimat
  /// pengeluaran ("masuk tol", "dapat diskon", "bonus kuota") hanya dihitung
  /// kalau tidak ada tanda pengeluaran di kalimat yang sama.
  DraftKind _kindOf(String lower) {
    bool any(List<String> words) => words.any((w) => _hasWord(lower, w));
    if (any(_transferWords)) return DraftKind.transfer;
    if (any(_incomeWords)) return DraftKind.income;
    if (any(_weakIncomeWords) && !any(_expenseCues)) return DraftKind.income;
    return DraftKind.expense;
  }

  /// Kategori pertama (frasa terpanjang lebih dulu) yang cocok nama atau
  /// alias kategori aktif berjenis [kind].
  String? _findCategory(String lower, DraftKind kind, List<(int, int)> amountSpans) {
    final categoryKind = kind == DraftKind.income ? CategoryKind.income : CategoryKind.expense;
    final active = categories().where((c) => !c.isArchived && c.kind == categoryKind).toList();
    final words = [
      for (final m in RegExp('[a-z&]+').allMatches(lower))
        if (!amountSpans.any((s) => m.start >= s.$1 && m.end <= s.$2)) m.group(0)!,
    ];
    for (var size = 3; size >= 1; size--) {
      for (var i = 0; i + size <= words.length; i++) {
        final match = matchCategory(active, categoryKind, words.sublist(i, i + size).join(' '));
        if (match != null) return match.name;
      }
    }
    return null;
  }

  /// Catatan: teks tanpa nominal, sebutan dompet berpreposisi, kata pengisi,
  /// dan kata kunci transfer.
  String _noteOf(String text, List<(int, int)> amountSpans) {
    final buffer = StringBuffer();
    var cursor = 0;
    for (final span in [...amountSpans]..sort((a, b) => a.$1.compareTo(b.$1))) {
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
      RegExp(r'\b(pakai|pake|via|lewat|dari|ke|masuk ke|masuk|bayarnya|bayar pakai)\s+\S+\s*$', caseSensitive: false),
      ' ',
    );
    final kept = [
      for (final word in note.split(RegExp(r'\s+')))
        if (word.isNotEmpty && !_fillerWords.contains(word.toLowerCase().replaceAll(RegExp(r'[^\w]'), ''))) word,
    ];
    return kept.join(' ').replaceAll(RegExp(r'^[,.\s]+|[,.\s]+$'), '');
  }
}

/// Dompet yang disebut di [lower]: asal ("dari X"), tujuan ("ke X", "top up
/// X"), dan sebutan bebas pertama. Nama yang tidak dikenal hanya diambil
/// setelah preposisi yang jelas-jelas menunjuk dompet, supaya "ke kantor"
/// tidak dianggap dompet.
({String? from, String? to, String? any}) _findWallets(
  String lower,
  List<String> walletNames,
  List<(int, int)> amountSpans,
) {
  final mentions = <(int, String)>[];
  for (final name in walletNames) {
    final pattern = RegExp('(^|[^a-z0-9])(${RegExp.escape(name.toLowerCase())})(?=[^a-z0-9]|\$)');
    for (final m in pattern.allMatches(lower)) {
      mentions.add((m.start + m.group(1)!.length, name));
    }
  }
  for (final word in _cashSpoken) {
    if (mentions.any((m) => _cashSpoken.contains(m.$2.toLowerCase()))) break;
    final m = RegExp('(^|[^a-z])$word(?=[^a-z]|\$)').firstMatch(lower);
    if (m != null) mentions.add((m.start + m.group(1)!.length, word));
  }
  mentions.sort((a, b) => a.$1.compareTo(b.$1));

  String? after(RegExp preposition) {
    for (final m in preposition.allMatches(lower)) {
      final at = m.end;
      for (final mention in mentions) {
        if (mention.$1 == at) return mention.$2;
      }
      // Nama tak dikenal setelah preposisi dompet: kutip apa adanya supaya
      // resolver menandainya "dompet tidak dikenal".
      final next = RegExp('[a-z][a-z0-9]*').matchAsPrefix(lower, at);
      if (next != null && !_fillerWords.contains(next.group(0)) && !amountSpans.any((s) => at >= s.$1 && at < s.$2)) {
        return next.group(0);
      }
    }
    return null;
  }

  final from = after(RegExp(r'\b(dari|from)\s+'));
  final to = after(RegExp(r'\b(ke|to|top ?up|isi saldo)\s+'));
  final any =
      after(RegExp(r'\b(pakai|pake|via|lewat|masuk ke|bayarnya|bayar pakai|pakainya)\s+')) ??
      (mentions.isEmpty ? null : mentions.first.$2);
  return (from: from, to: to, any: any);
}

(int, int) _spanOf(String text, String phrase) {
  final at = text.indexOf(phrase);
  return at < 0 ? (0, 0) : (at, at + phrase.length);
}

bool _hasWord(String lower, String word) => RegExp('(^|[^a-z])${RegExp.escape(word)}(?=[^a-z]|\$)').hasMatch(lower);

const _transferWords = [
  'transfer',
  'tf',
  'top up',
  'topup',
  'isi saldo',
  'pindah dana',
  'pindahin',
  'tarik tunai',
  'setor tunai',
];

/// Kata yang hampir pasti berarti pemasukan.
const _incomeWords = ['gaji', 'gajian', 'pemasukan', 'thr', 'salary', 'income', 'refund', 'cashback'];

/// Kata pemasukan yang juga muncul di kalimat pengeluaran.
const _weakIncomeWords = ['masuk', 'dapat', 'dapet', 'terima', 'diterima', 'bonus', 'dibayar'];

/// Tanda kalimat pengeluaran; mengalahkan [_weakIncomeWords].
const _expenseCues = [
  'beli',
  'bayar',
  'belanja',
  'jajan',
  'makan',
  'isi',
  'tol',
  'parkir',
  'diskon',
  'potongan',
  'ongkir',
  'ongkos',
  'pulsa',
  'kuota',
  'buy',
  'pay',
];

const _cashSpoken = ['cash', 'tunai', 'kas'];

/// Kata yang dibuang dari catatan.
const _fillerWords = {
  'tadi',
  'td',
  'barusan',
  'baru',
  'abis',
  'habis',
  'saya',
  'aku',
  'gue',
  'udah',
  'sudah',
  'aja',
  'total',
  'totalnya',
  'sebesar',
  'seharga',
  'harganya',
  'rp',
  'rupiah',
  'transfer',
  'tf',
  'top',
  'up',
  'topup',
  'kemarin',
  'lusa',
  'pakai',
  'pake',
  'masuk',
};
