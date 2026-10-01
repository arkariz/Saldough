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

/// Aplikasi yang notifikasinya didengarkan (ADR-032 §3.2), dipilih pengguna.
final class NotificationSource extends Equatable {
  /// Membuat [NotificationSource].
  const NotificationSource({
    required this.packageName,
    required this.appLabel,
    this.keywords = const [],
    this.walletId,
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

  /// Didengarkan atau tidak.
  final bool enabled;

  /// `true` bila [text] memicu sumber ini menurut [keywords].
  bool matchesKeywords(String text) {
    final lower = text.toLowerCase();
    return keywords.any((k) => k.trim().isNotEmpty && lower.contains(k.trim().toLowerCase()));
  }

  /// Salinan dengan field yang diganti. [walletId] memakai fungsi supaya bisa
  /// dikosongkan.
  NotificationSource copyWith({
    String? appLabel,
    List<String>? keywords,
    String? Function()? walletId,
    bool? enabled,
  }) => NotificationSource(
    packageName: packageName,
    appLabel: appLabel ?? this.appLabel,
    keywords: keywords ?? this.keywords,
    walletId: walletId == null ? this.walletId : walletId(),
    enabled: enabled ?? this.enabled,
  );

  @override
  List<Object?> get props => [packageName, appLabel, keywords, walletId, enabled];
}
