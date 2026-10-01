import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_text.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';

/// Interpreter aturan untuk teks notifikasi bank/e-wallet (ADR-032 §3.3).
///
/// Berbeda dari kalimat lisan:
/// - angka bukan-nominal (saldo, limit, nomor rekening tersamar, nomor
///   referensi, jam) dikeluarkan lebih dulu
///   ([NotificationText.maskNonTransactionNumbers]);
/// - jenis hanya dari kata arah notifikasi ("dana masuk", "pembayaran");
///   tanpa kata arah, atau dengan dua arah sekaligus, jenisnya `null` supaya
///   resolver menandai `kindUnclear` -- tidak menebak pengeluaran;
/// - "transfer"/"top up" hanya berarti transfer antar dompet sendiri bila
///   dompet pengguna lain disebut dengan preposisi yang jelas ("ke GoPay",
///   "dari BCA"). Dompet sumber tidak ada di [InterpretationContext.walletNames]
///   (penyusun notifikasi mengeluarkannya), jadi sebutan nama bank pengirim
///   tidak terbaca sebagai lawan transfer.
///
/// Nominal, tanggal, dan kategori memakai [RuleBasedTransactionInterpreter]
/// pada teks yang sudah disaring; dompet sumber diisi penyusun notifikasi.
final class NotificationRuleInterpreter implements TransactionInterpreter {
  /// Membuat [NotificationRuleInterpreter] untuk [language].
  const NotificationRuleInterpreter({required this.language, required this.categories});

  /// Paket bahasa.
  final CaptureLanguage language;

  /// Sumber kategori terkini.
  final List<Category> Function() categories;

  @override
  Future<Either<Failure, InterpretedTransaction>> interpret(
    CaptureEvidence evidence,
    InterpretationContext context,
  ) async => right(interpretSync(evidence.text, context));

  /// Versi sinkron [interpret].
  InterpretedTransaction interpretSync(String text, InterpretationContext context) {
    final lexicon = language.notification;
    final masked = NotificationText.maskNonTransactionNumbers(text, lexicon);
    // Tanpa nama dompet: sebutan dompet di notifikasi ditangani di sini, dan
    // "via QRIS" tidak boleh menjadi "dompet tidak dikenal".
    final base = RuleBasedTransactionInterpreter(language: language, categories: categories).interpretSync(
      masked,
      InterpretationContext(
        walletNames: const [],
        expenseCategoryNames: context.expenseCategoryNames,
        incomeCategoryNames: context.incomeCategoryNames,
        today: context.today,
        currencyCode: context.currencyCode,
      ),
    );

    final lower = masked.toLowerCase();
    bool any(List<String> words) => words.any((w) => _hasPhrase(lower, w));
    final income = any(lexicon.incomeCues);
    final expense = any(lexicon.expenseCues);

    var kind = income == expense ? null : (income ? DraftKind.income : DraftKind.expense);
    String? walletText;
    String? toWalletText;
    if (any(lexicon.transferCues)) {
      final counterpart = _counterpart(lower, context.walletNames);
      if (counterpart != null) {
        kind = DraftKind.transfer;
        if (counterpart.incoming) {
          walletText = counterpart.name;
        } else {
          toWalletText = counterpart.name;
        }
      }
    }

    return InterpretedTransaction(
      kind: kind,
      amountText: base.amountText,
      walletText: walletText,
      toWalletText: toWalletText,
      categoryName: kind == DraftKind.transfer || kind == null ? null : _categoryFor(kind, base),
      note: _noteOf(base.note ?? ''),
      dateText: base.dateText,
      date: base.date,
    );
  }

  /// Kategori tafsiran dasar hanya dipakai bila jenisnya sama dengan jenis
  /// notifikasi (tafsiran dasar menebak jenis dari kata lisan).
  String? _categoryFor(DraftKind kind, InterpretedTransaction base) => base.kind == kind ? base.categoryName : null;

  /// Dompet pengguna yang disebut sesudah preposisi asal ("dari") atau
  /// tujuan ("ke", "top up"); tanpa preposisi yang jelas, `null`.
  ({String name, bool incoming})? _counterpart(String lower, List<String> walletNames) {
    for (final name in walletNames) {
      final escaped = RegExp.escape(name.toLowerCase());
      final from = language.fromPrepositions.map(RegExp.escape).join('|');
      final to = language.toPrepositions.map(RegExp.escape).join('|');
      if (from.isNotEmpty && RegExp('(?:^|[^a-z])(?:$from)\\s+$escaped(?=[^a-z0-9]|\$)').hasMatch(lower)) {
        return (name: name, incoming: true);
      }
      if (to.isNotEmpty && RegExp('(?:^|[^a-z])(?:$to)\\s+$escaped(?=[^a-z0-9]|\$)').hasMatch(lower)) {
        return (name: name, incoming: false);
      }
    }
    return null;
  }

  /// Catatan: teks tanpa kata arah, kata saldo, dan kata baku notifikasi,
  /// tanpa preposisi di awal ("ke KOPI KENANGAN" → "KOPI KENANGAN"), paling
  /// panjang 80 karakter.
  String _noteOf(String note) {
    final lexicon = language.notification;
    var text = note;
    final phrases = [...lexicon.incomeCues, ...lexicon.expenseCues, ...lexicon.transferCues, ...lexicon.balanceWords]
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final phrase in phrases) {
      text = text.replaceAll(
        RegExp('(?<![\\p{L}])${RegExp.escape(phrase)}(?![\\p{L}])', caseSensitive: false, unicode: true),
        ' ',
      );
    }
    final kept = [
      for (final word in text.split(RegExp(r'\s+')))
        if (word.isNotEmpty && !lexicon.fillerWords.contains(word.toLowerCase().replaceAll(RegExp(r'[^\w]'), ''))) word,
    ];
    var joined = kept.join(' ').replaceAll(RegExp(r'^[,.:;\s-]+|[,.:;\s-]+$'), '');
    final leading = [...language.toPrepositions, ...language.fromPrepositions, 'di', 'at'].map(RegExp.escape).join('|');
    joined = joined.replaceFirst(RegExp('^(?:$leading)\\s+', caseSensitive: false), '');
    return joined.length <= 80 ? joined : '${joined.substring(0, 79).trimRight()}…';
  }
}

bool _hasPhrase(String lower, String phrase) =>
    RegExp('(^|[^a-z])${RegExp.escape(phrase)}(?=[^a-z]|\$)').hasMatch(lower);
