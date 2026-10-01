/// Tampilan entitas `Transaction` yang dipakai lebih dari satu fitur
/// (ADR-030 §3.2): judul dan jam transaksi, serta kartu grup per tanggal.
/// Barrel terpisah dari `transaction.dart` supaya `domain/` yang mengimpor
/// barrel utama tidak ikut menarik Flutter.
library;

export 'presentation/transaction_date_group_card.dart';
export 'presentation/transaction_display.dart';
export 'presentation/transaction_icon.dart';
