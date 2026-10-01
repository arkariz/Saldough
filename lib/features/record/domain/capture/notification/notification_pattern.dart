import 'package:dependencies/dependencies.dart';

/// Arti tetap sebuah pola (ADR-032 §3.3).
enum NotificationPatternKind {
  /// Pengeluaran dari dompet sumber.
  expense,

  /// Pemasukan ke dompet sumber.
  income,

  /// Transfer dari dompet sumber ke dompet lain milik pengguna.
  transferOut,

  /// Transfer dari dompet lain milik pengguna ke dompet sumber.
  transferIn,
}

/// Templat teks notifikasi satu aplikasi (ADR-032 §3.3): teks literal dengan
/// penanda [amountToken] (wajib), [noteToken] (opsional), dan [anyToken]
/// (bagian yang berubah-ubah). Pola bawaan ada di kode; pola pengguna dibuat
/// dari contoh.
final class NotificationPattern extends Equatable {
  /// Membuat [NotificationPattern].
  const NotificationPattern({
    required this.id,
    required this.packageName,
    required this.label,
    required this.template,
    required this.kind,
    this.categoryId,
    this.transferWalletId,
    this.builtIn = false,
    this.verified = true,
  });

  /// Penanda nominal.
  static const amountToken = '{amount}';

  /// Penanda catatan (merchant atau lawan transaksi).
  static const noteToken = '{note}';

  /// Penanda bagian yang berubah-ubah (tanggal, jam, no. referensi, saldo).
  static const anyToken = '{*}';

  /// Identitas pola.
  final String id;

  /// Paket aplikasi yang notifikasinya dicocokkan.
  final String packageName;

  /// Nama singkat pola, untuk ditampilkan.
  final String label;

  /// Templat teks.
  final String template;

  /// Jenis transaksi yang dihasilkan.
  final NotificationPatternKind kind;

  /// Kategori tetap, atau `null`.
  final String? categoryId;

  /// Dompet lawan untuk pola transfer, atau `null`.
  final String? transferWalletId;

  /// Pola bawaan (tidak bisa disunting).
  final bool builtIn;

  /// Pola sudah dicocokkan dengan sampel notifikasi asli. Draf dari pola yang
  /// belum terverifikasi tidak pernah dicatat otomatis.
  final bool verified;

  /// Salinan pola pengguna dari pola ini (untuk "Gandakan").
  NotificationPattern duplicateAs(String newId) => NotificationPattern(
    id: newId,
    packageName: packageName,
    label: label,
    template: template,
    kind: kind,
    categoryId: categoryId,
    transferWalletId: transferWalletId,
  );

  @override
  List<Object?> get props => [id, packageName, label, template, kind, categoryId, transferWalletId, builtIn, verified];
}
