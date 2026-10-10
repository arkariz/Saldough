import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Setiap lembar modal lewat `showAppSheet`/`showFullScreenSheet` atau rute
/// lembar yang membungkus isinya dengan `SheetSafeArea`, supaya tombol di
/// dasar lembar tidak tertutup bilah navigasi sistem.
void main() {
  final files = Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

  test('showModalBottomSheet hanya di full_screen_sheet.dart', () {
    final hits = [
      for (final file in files)
        // Jalur Windows memakai `\`.
        if (!file.path.replaceAll(r'\', '/').endsWith('core/presentation/widgets/full_screen_sheet.dart') &&
            file.readAsStringSync().contains('showModalBottomSheet<'))
          file.path,
    ];
    expect(hits, isEmpty);
  });

  test('ModalBottomSheetRoute selalu bersama SheetSafeArea', () {
    final hits = [
      for (final file in files)
        if (file.readAsStringSync() case final source
            when source.contains('ModalBottomSheetRoute<') && !source.contains('SheetSafeArea('))
          file.path,
    ];
    expect(hits, isEmpty);
  });
}
