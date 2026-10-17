import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/features/analysis/presentation/analysis_colors.dart';
import 'package:saldough/shared/category/category.dart';

/// Warna irisan tetap per kategori di semua periode (DonutChart): hanya
/// pembeda, bukan penilaian.
void main() {
  Category category(String id, {String? builtIn}) => Category(
    id: id,
    kind: CategoryKind.expense,
    name: id,
    builtInKey: builtIn,
  );

  test(
    'kategori bawaan mengikuti pembagian TileTint yang sama dengan tile',
    () {
      expect(
        analysisTintOf(category('builtin.food', builtIn: 'food')),
        TileTint.orange,
      );
      expect(
        analysisTintOf(category('builtin.groceries', builtIn: 'groceries')),
        TileTint.green,
      );
      expect(
        analysisTintOf(category('builtin.transport', builtIn: 'transport')),
        TileTint.blue,
      );
      expect(
        analysisTintOf(category('builtin.bills', builtIn: 'bills')),
        TileTint.purple,
      );
      expect(
        analysisTintOf(category('builtin.donation', builtIn: 'donation')),
        TileTint.brown,
      );
    },
  );

  test(
    'kategori buatan pengguna: warna stabil dari id, tidak pernah slate, dan tersebar',
    () {
      final ids = [for (var i = 0; i < 60; i++) 'kategori-$i'];
      final first = [for (final id in ids) analysisTintOf(category(id))];
      final again = [for (final id in ids) analysisTintOf(category(id))];
      expect(again, first, reason: 'sama di tiap pemanggilan, antarperiode');
      expect(first, isNot(contains(TileTint.slate)));
      expect(
        first.toSet().length,
        greaterThanOrEqualTo(6),
        reason: 'palet dipakai merata',
      );
    },
  );

  test(
    'Lainnya slate, Tanpa kategori line-strong, Freelance turunan indigo',
    () {
      const colors = AppColors.light;
      AnalysisGroup group(AnalysisGroupKind kind) => AnalysisGroup(
        kind: kind,
        amount: 1,
        count: 1,
        share: const AnalysisShare(percent: 1, belowOne: false),
      );
      expect(
        analysisColorOf(colors, group(AnalysisGroupKind.others)),
        colors.catSlate,
      );
      expect(
        analysisColorOf(colors, group(AnalysisGroupKind.uncategorized)),
        colors.lineStrong,
      );
      expect(
        analysisColorOf(colors, group(AnalysisGroupKind.freelance)),
        colors.catIndigo,
      );
    },
  );
}
