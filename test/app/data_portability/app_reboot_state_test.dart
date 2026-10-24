import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Boot ulang sesudah pemulihan (ADR-040 §3.7) harus memuat ulang setiap state
/// global dalam memori. Uji ini memaksa keputusan sadar: state global baru
/// (`static final ValueNotifier`) tidak bisa ditambahkan tanpa diputuskan
/// apakah `bootstrapApp()` memuat atau mengosongkannya ulang.
void main() {
  // Kelas → cara boot ulang menanganinya.
  const handled = <String, String>{
    'AppReboot': 'laporan pemulihan; diisi bootstrap, tidak dimuat dari penyimpanan',
    'ActiveCategories': 'dikosongkan lalu diisi `listCategories()` di bootstrapApp',
    'ActiveCurrency': 'dimuat ulang dari CurrencyPreferenceRepository di bootstrapApp',
    'ActiveFinancialMonth': 'dimuat ulang dari FinancialMonthPreferenceRepository di bootstrapApp',
    'ActiveLanguage': 'milik perangkat (R-9), dibaca ulang di bootstrapApp',
    'AmountVisibility': 'milik perangkat (R-9), dibaca ulang di bootstrapApp',
    'HistoryPeriod': 'dikosongkan di _resetGlobalState (pilihan layar, bukan data)',
    'ActiveDay': 'jam, bukan data penyimpanan',
    'ActivePlan': 'dikembalikan ke Gratis di _resetGlobalState, diisi lagi oleh startEntitlements (ADR-041)',
    'SourceIcons': 'dikosongkan di _resetGlobalState, dimuat lagi saat dibutuhkan',
  };

  test('setiap state global ValueNotifier di lib/ punya penanganan boot ulang', () {
    final found = <String>{};
    final declaration = RegExp(r'static\s+final\s+ValueNotifier<');
    final classDeclaration = RegExp(r'(?:abstract\s+)?(?:final\s+)?class\s+(\w+)');
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final m in declaration.allMatches(source)) {
        final owner = classDeclaration.allMatches(source.substring(0, m.start)).last.group(1)!;
        found.add(owner);
      }
    }
    expect(found, isNotEmpty);
    expect(
      found.difference(handled.keys.toSet()),
      isEmpty,
      reason:
          'State global baru harus ditangani bootstrapApp()/_resetGlobalState '
          'dan didaftarkan di uji ini (ADR-040 §3.7)',
    );
    expect(handled.keys.toSet().difference(found), isEmpty, reason: 'entri usang');
  });
}
