import 'package:dependencies/dependencies.dart';

/// Jenis transaksi dalam draf. Bukan `RecordChoice` (lapisan tampilan) supaya
/// domain Catat Cerdas tidak bergantung pada widget.
enum DraftKind {
  /// Pengeluaran.
  expense,

  /// Pemasukan.
  income,

  /// Transfer antar dompet.
  transfer,
}

/// Keluaran interpreter (ADR-027 §3.2): **kutipan** dari teks bukti, bukan
/// nilai final. Nominal, dompet, dan kategori diubah menjadi nilai oleh
/// `CaptureDraftResolver`, sama untuk semua penyedia (aturan, model lokal,
/// cloud). Semua field opsional.
final class InterpretedTransaction extends Equatable {
  /// Membuat [InterpretedTransaction].
  const InterpretedTransaction({
    this.kind,
    this.amountText,
    this.walletText,
    this.toWalletText,
    this.categoryName,
    this.note,
    this.dateText,
    this.date,
  });

  /// Jenis yang ditafsirkan, atau `null` kalau tidak jelas.
  final DraftKind? kind;

  /// Frasa nominal persis seperti di teks ("35 ribu", "Rp35.000,00").
  final String? amountText;

  /// Sebutan dompet (untuk transfer: dompet asal).
  final String? walletText;

  /// Sebutan dompet tujuan transfer.
  final String? toWalletText;

  /// Nama kategori yang dipilih dari daftar konteks.
  final String? categoryName;

  /// Catatan singkat, mis. "makan siang".
  final String? note;

  /// Sebutan tanggal persis seperti di teks ("kemarin", "tanggal 27
  /// september").
  final String? dateText;

  /// Tafsiran [dateText] oleh interpreter (ADR-029 §3.2). Resolver hanya
  /// memakainya bila [dateText] benar-benar ada di teks bukti.
  final DateTime? date;

  @override
  List<Object?> get props => [kind, amountText, walletText, toWalletText, categoryName, note, dateText, date];
}
