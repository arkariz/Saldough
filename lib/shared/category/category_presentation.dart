/// Tampilan entitas `Category` yang dipakai lebih dari satu fitur (ADR-030
/// §3.2). Barrel terpisah dari `category.dart` supaya `domain/` yang
/// mengimpor barrel utama tidak ikut menarik Flutter.
library;

export 'presentation/category_display.dart';
export 'presentation/category_form_sheet.dart';
