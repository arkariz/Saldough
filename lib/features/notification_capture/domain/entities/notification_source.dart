import 'package:dependencies/dependencies.dart';

/// Filter bawaan sumber baru (ADR-032 §3.1): frasa yang hanya muncul di
/// notifikasi transaksi yang sudah terjadi, bukan promosi atau pengingat.
/// Pengguna bisa menambah, menghapus, atau mengembalikannya.
const defaultNotificationKeywords = [
  'pembayaran berhasil',
  'pembelian berhasil',
  'transaksi berhasil',
  'transfer berhasil',
  'top up berhasil',
  'berhasil dibayar',
  'dana masuk',
  'transfer masuk',
  'uang masuk',
  'kamu menerima',
  'anda menerima',
  'payment successful',
  'transfer successful',
  'you received',
];

/// Aturan dompet tambahan sebuah sumber (ADR-042 §3.1): notifikasi yang
/// memuat salah satu [keywords] (mis. nama Kantong) milik [walletId].
final class WalletRule extends Equatable {
  /// Membuat [WalletRule].
  const WalletRule({required this.walletId, this.keywords = const []});

  /// Dompet Tanukonomy yang diwakili.
  final String walletId;

  /// Frasa pengenal di teks notifikasi, tanpa beda huruf besar-kecil.
  final List<String> keywords;

  /// `true` bila [text] memuat salah satu [keywords].
  bool matches(String text) {
    final lower = text.toLowerCase();
    return keywords.any((k) => k.trim().isNotEmpty && lower.contains(k.trim().toLowerCase()));
  }

  /// Salinan dengan field yang diganti.
  WalletRule copyWith({String? walletId, List<String>? keywords}) =>
      WalletRule(walletId: walletId ?? this.walletId, keywords: keywords ?? this.keywords);

  @override
  List<Object?> get props => [walletId, keywords];
}

/// Aplikasi yang notifikasinya didengarkan (ADR-032 §3.2), dipilih pengguna.
final class NotificationSource extends Equatable {
  /// Membuat [NotificationSource].
  const NotificationSource({
    required this.packageName,
    required this.appLabel,
    this.keywords = const [],
    this.walletId,
    this.walletRules = const [],
    this.enabled = true,
  });

  /// Nama paket Android, mis. `id.co.bri.brimo`.
  final String packageName;

  /// Nama aplikasi saat dipilih, untuk ditampilkan.
  final String appLabel;

  /// Filter (whitelist): notifikasi hanya ditangkap bila memuat salah satu
  /// frasa ini (tanpa beda huruf besar-kecil). Kosong = tidak ada yang
  /// ditangkap. Sumber baru diisi [defaultNotificationKeywords].
  final List<String> keywords;

  /// Dompet yang mewakili aplikasi ini, mengisi dompet draf.
  final String? walletId;

  /// Aturan dompet tambahan (ADR-042 §3.1), mis. satu per Kantong Jago.
  final List<WalletRule> walletRules;

  /// Didengarkan atau tidak.
  final bool enabled;

  /// `true` bila [text] memicu sumber ini menurut [keywords].
  bool matchesKeywords(String text) {
    final lower = text.toLowerCase();
    return keywords.any((k) => k.trim().isNotEmpty && lower.contains(k.trim().toLowerCase()));
  }

  /// Semua dompet yang diwakili sumber ini: bawaan dan aturan.
  Set<String> get allWalletIds => {?walletId, for (final r in walletRules) r.walletId};

  /// Dompet sumber untuk [text] (ADR-042 §3.1): tepat satu dompet berbeda
  /// cocok → dompet itu; tidak ada → [walletId]; lebih dari satu → ambigu
  /// (`null`, tidak menebak).
  ({String? walletId, bool ambiguous}) resolveWallet(String text) {
    final hits = {
      for (final r in walletRules)
        if (r.matches(text)) r.walletId,
    };
    if (hits.length > 1) return (walletId: null, ambiguous: true);
    return (walletId: hits.isEmpty ? walletId : hits.single, ambiguous: false);
  }

  /// Dompet untuk potongan teks [fragment] (penanda `{from}`/`{to}`), atau
  /// `null` bila tidak ada atau lebih dari satu aturan cocok.
  String? walletForFragment(String fragment) {
    final hits = {
      for (final r in walletRules)
        if (r.matches(fragment)) r.walletId,
    };
    return hits.length == 1 ? hits.single : null;
  }

  /// Salinan dengan field yang diganti. [walletId] memakai fungsi supaya bisa
  /// dikosongkan.
  NotificationSource copyWith({
    String? appLabel,
    List<String>? keywords,
    String? Function()? walletId,
    List<WalletRule>? walletRules,
    bool? enabled,
  }) => NotificationSource(
    packageName: packageName,
    appLabel: appLabel ?? this.appLabel,
    keywords: keywords ?? this.keywords,
    walletId: walletId == null ? this.walletId : walletId(),
    walletRules: walletRules ?? this.walletRules,
    enabled: enabled ?? this.enabled,
  );

  @override
  List<Object?> get props => [packageName, appLabel, keywords, walletId, walletRules, enabled];
}
