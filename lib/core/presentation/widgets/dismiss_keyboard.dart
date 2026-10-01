import 'package:flutter/widgets.dart';

/// `TextField.onTapOutside` yang melepas fokus: ketukan di luar kolom
/// (pemilih tanggal, menu, chip) menutup papan ketik, dan dialog atau menu
/// yang ditutup tidak mengembalikan fokus ke kolom itu -- tanpa ini fokus
/// "melompat" kembali ke kolom nominal CATAT dan papan ketik muncul lagi.
void dismissKeyboardOnTapOutside(PointerDownEvent event) => FocusManager.instance.primaryFocus?.unfocus();
