import 'package:flutter/painting.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/shared/category/category.dart';

/// Warna tile bawaan per kategori bawaan, mengikuti pembagian `TileTint`
/// (Makan oranye, Belanja Harian hijau, …).
const Map<String, TileTint> _builtInTints = {
  'food': TileTint.orange,
  'groceries': TileTint.green,
  'salary': TileTint.green,
  'transport': TileTint.blue,
  'bills': TileTint.purple,
  'internet': TileTint.teal,
  'health': TileTint.rose,
  'gift': TileTint.rose,
  'shopping': TileTint.amber,
  'bonus': TileTint.amber,
  'education': TileTint.indigo,
  'entertainment': TileTint.indigo,
  'freelance': TileTint.indigo,
  'family': TileTint.brown,
  'donation': TileTint.brown,
  'expenseOther': TileTint.slate,
  'incomeOther': TileTint.slate,
};

/// Warna yang dibagikan ke kategori buatan pengguna; `slate` disimpan untuk
/// Lainnya dan Tanpa kategori.
const List<TileTint> _customPalette = [
  TileTint.orange,
  TileTint.green,
  TileTint.blue,
  TileTint.purple,
  TileTint.teal,
  TileTint.rose,
  TileTint.amber,
  TileTint.indigo,
  TileTint.brown,
];

/// Warna `cat-*` tetap untuk [category] di semua periode (DonutChart): kategori
/// bawaan mengikuti [_builtInTints], buatan pengguna dari hash stabil id-nya.
/// Warna hanya pembeda kategori, bukan penilaian (nada netral Analisis).
TileTint analysisTintOf(Category category) {
  final builtIn = _builtInTints[category.builtInKey];
  if (builtIn != null) return builtIn;
  // FNV-1a 32-bit: stabil antarproses (hashCode Dart tidak dijamin stabil).
  var hash = 0x811c9dc5;
  for (final unit in category.id.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return _customPalette[hash % _customPalette.length];
}

/// Warna irisan dan penanda legenda untuk [group]: token `cat-*` ikon
/// (bukan latarnya); Lainnya `cat-slate`, Tanpa kategori `line-strong`.
Color analysisColorOf(AppColors colors, AnalysisGroup group) => switch (group.kind) {
  AnalysisGroupKind.category => colors.tile(analysisTintOf(group.category!)).$2,
  AnalysisGroupKind.freelance => colors.tile(TileTint.indigo).$2,
  AnalysisGroupKind.others => colors.tile(TileTint.slate).$2,
  AnalysisGroupKind.uncategorized => colors.lineStrong,
};
