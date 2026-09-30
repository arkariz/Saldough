/// Tampilan entitas `Wallet` yang dipakai lebih dari satu fitur (ADR-030
/// §3.2). Barrel terpisah dari `wallet.dart` supaya `domain/` yang
/// mengimpor barrel utama tidak ikut menarik Flutter.
library;

export 'presentation/wallet_balance_preview.dart';
export 'presentation/wallet_select_field.dart';
