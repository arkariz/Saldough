import 'package:saldough/shared/capture/domain/language/english.dart';
import 'package:saldough/shared/capture/domain/language/indonesian.dart';
import 'package:saldough/shared/capture/domain/number_lexicon.dart';
import 'package:saldough/shared/capture/domain/spoken_date_parser.dart';

/// Kosakata satu bahasa untuk Catat Cerdas (ADR-029 §3.1). Interpreter
/// aturan, resolver, dan pengurai hanya membaca peran kata dari sini;
/// menambah bahasa = menambah satu [CaptureLanguage] ke [CaptureLanguages].
final class CaptureLanguage {
  /// Membuat [CaptureLanguage].
  const CaptureLanguage({
    required this.code,
    required this.numbers,
    required this.dates,
    required this.transferWords,
    required this.incomeWords,
    required this.weakIncomeWords,
    required this.expenseCues,
    required this.fromPrepositions,
    required this.toPrepositions,
    required this.viaPrepositions,
    required this.noteWalletPrepositions,
    required this.cashMentions,
    required this.cashWords,
    required this.fillerWords,
    this.notification = const NotificationLexicon(),
  });

  /// Kode bahasa aplikasi (`id`, `en`; ADR-028).
  final String code;

  /// Bilangan kata dan pemisah ribuan.
  final NumberLexicon numbers;

  /// Kata tanggal.
  final DateLexicon dates;

  /// Kata yang menandai transfer.
  final List<String> transferWords;

  /// Kata yang hampir pasti berarti pemasukan.
  final List<String> incomeWords;

  /// Kata pemasukan yang juga lazim di kalimat pengeluaran ("masuk tol");
  /// hanya dihitung bila tidak ada [expenseCues].
  final List<String> weakIncomeWords;

  /// Tanda kalimat pengeluaran; mengalahkan [weakIncomeWords].
  final List<String> expenseCues;

  /// Preposisi dompet asal ("dari").
  final List<String> fromPrepositions;

  /// Preposisi dompet tujuan ("ke", "top up").
  final List<String> toPrepositions;

  /// Preposisi dompet pembayaran ("pakai", "via").
  final List<String> viaPrepositions;

  /// Preposisi yang, bersama satu kata sesudahnya di **akhir** kalimat,
  /// dibuang dari catatan ("... pakai BCA").
  final List<String> noteWalletPrepositions;

  /// Kata tunai yang dikenali interpreter sebagai sebutan dompet.
  final List<String> cashMentions;

  /// Sinonim dompet tunai yang dicocokkan resolver ke dompet tunai.
  final Set<String> cashWords;

  /// Kata yang dibuang dari catatan.
  final Set<String> fillerWords;

  /// Kosakata teks notifikasi bank/e-wallet (ADR-032 §3.3).
  final NotificationLexicon notification;
}

/// Kosakata teks notifikasi bank/e-wallet (ADR-032 §3.3). Notifikasi bukan
/// kalimat lisan: arahnya dinyatakan kata baku ("dana masuk", "debit"), dan
/// sering memuat nominal lain (saldo, limit) yang bukan nominal transaksi.
final class NotificationLexicon {
  /// Membuat [NotificationLexicon].
  const NotificationLexicon({
    this.balanceWords = const [],
    this.incomeCues = const [],
    this.expenseCues = const [],
    this.transferCues = const [],
    this.fillerWords = const {},
  });

  /// Kata yang mendahului nominal bukan-transaksi ("saldo", "limit").
  final List<String> balanceWords;

  /// Kata arah masuk ("dana masuk", "diterima").
  final List<String> incomeCues;

  /// Kata arah keluar ("pembayaran", "debit").
  final List<String> expenseCues;

  /// Kata yang, bersama sebutan dompet pengguna lain, menandai transfer antar
  /// dompet sendiri ("top up", "isi saldo").
  final List<String> transferCues;

  /// Kata baku notifikasi yang dibuang dari catatan ("berhasil").
  final Set<String> fillerWords;
}

/// Paket bahasa yang tersedia. Bahasa aplikasi tanpa paket di sini tidak
/// punya interpreter aturan dan langsung ke cloud (ADR-029 §3.4).
abstract final class CaptureLanguages {
  CaptureLanguages._();

  /// Seluruh paket, menurut kode bahasa.
  static const Map<String, CaptureLanguage> all = {'id': indonesian, 'en': english};

  /// Paket untuk [code] (mis. `id`, atau `id_ID`), atau `null`.
  static CaptureLanguage? of(String code) => all[code.split(RegExp('[_-]')).first.toLowerCase()];
}
