/// Tampilan identitas yang dipakai lebih dari satu fitur (ADR-030 §3.2):
/// avatar akun dan tombol akun Beranda. Barrel terpisah dari `auth.dart`
/// supaya `domain/` yang mengimpor barrel utama tidak ikut menarik Flutter.
library;

export 'presentation/account_avatar.dart';
