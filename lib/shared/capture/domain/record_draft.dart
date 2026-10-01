import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/capture/domain/interpreted_transaction.dart';

/// Hal yang perlu diperhatikan pengguna sebelum menyimpan draf (ADR-027
/// §3.3). Formulir CATAT menyorot kolom yang bersangkutan.
enum DraftIssue {
  /// Nominal tidak ditemukan.
  amountMissing,

  /// Lebih dari satu nominal disebut.
  amountMultiple,

  /// Angka tanpa satuan uang.
  amountWithoutUnit,

  /// Penulisan nominal bisa dibaca dua cara.
  amountAmbiguous,

  /// Menyebut mata uang selain mata uang aplikasi.
  currencyUnsupported,

  /// Dompet yang disebut tidak ada di daftar dompet aktif.
  walletUnknown,

  /// Transfer tanpa dompet asal yang jelas.
  transferSourceMissing,

  /// Transfer tanpa dompet tujuan yang jelas.
  transferTargetMissing,

  /// Kategori yang disebut tidak ada di daftar kategori.
  categoryUnknown,

  /// Tanggal disebut tetapi tidak bisa dipakai: tidak ada di kalender, di
  /// masa depan, atau kutipannya tidak ada di teks (ADR-029 §3.2).
  dateUnclear,

  /// Arah transaksi (masuk/keluar) tidak tertulis jelas. Hanya untuk bukti
  /// notifikasi (ADR-032 §3.3); suara tetap bawaan pengeluaran.
  kindUnclear,
}

/// Draf transaksi yang mengisi formulir CATAT (ADR-027 §3.4). Bukan
/// transaksi: tidak punya id, dan tidak pernah disimpan tanpa pengguna
/// menekan Catat.
final class RecordDraft extends Equatable {
  /// Membuat [RecordDraft].
  const RecordDraft({
    required this.kind,
    this.amountSen,
    this.walletId,
    this.toWalletId,
    this.categoryId,
    this.note = '',
    this.date,
    this.issues = const {},
    this.sourceText,
    this.sourceIconId,
  });

  /// Jenis transaksi.
  final DraftKind kind;

  /// Nominal dalam sen, atau `null`.
  final int? amountSen;

  /// Dompet (untuk transfer: dompet asal).
  final String? walletId;

  /// Dompet tujuan transfer.
  final String? toWalletId;

  /// Kategori (pemasukan/pengeluaran saja).
  final String? categoryId;

  /// Catatan.
  final String note;

  /// Tanggal transaksi; `null` berarti bawaan formulir (hari ini).
  final DateTime? date;

  /// Hal yang perlu diperhatikan.
  final Set<DraftIssue> issues;

  /// Teks bukti yang ditafsirkan (mis. transkrip), ditampilkan di formulir
  /// supaya pengguna bisa mencocokkan. Tidak disimpan.
  final String? sourceText;

  /// Ikon notifikasi asal (ADR-032 §3.10), ikut ke transaksi yang dicatat.
  final String? sourceIconId;

  /// Draf lengkap tanpa masalah: nominal terisi dan tidak ada [issues].
  bool get isConfident => amountSen != null && issues.isEmpty;

  /// Salinan dengan field yang diganti. [walletId], [toWalletId], dan
  /// [categoryId] memakai fungsi supaya bisa dikosongkan.
  RecordDraft copyWith({
    DraftKind? kind,
    String? Function()? walletId,
    String? Function()? toWalletId,
    String? Function()? categoryId,
    Set<DraftIssue>? issues,
    String? Function()? sourceIconId,
  }) => RecordDraft(
    kind: kind ?? this.kind,
    amountSen: amountSen,
    walletId: walletId == null ? this.walletId : walletId(),
    toWalletId: toWalletId == null ? this.toWalletId : toWalletId(),
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    note: note,
    date: date,
    issues: issues ?? this.issues,
    sourceText: sourceText,
    sourceIconId: sourceIconId == null ? this.sourceIconId : sourceIconId(),
  );

  @override
  List<Object?> get props => [
    kind,
    amountSen,
    walletId,
    toWalletId,
    categoryId,
    note,
    date,
    issues,
    sourceText,
    sourceIconId,
  ];
}
