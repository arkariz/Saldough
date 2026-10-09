import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Komponen Skeleton (ADR-034): tampil hanya bila memuat lebih dari 300ms,
/// meniru baris (tile, dua garis, nominal), tanpa denyut saat kurangi gerakan.
void main() {
  Future<void> pump(WidgetTester tester, {bool reduceMotion = false}) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: MaterialApp(
        theme: PixelTheme.light,
        home: const Scaffold(body: AppSkeletonPage(rowCount: 3)),
      ),
    ),
  );

  testWidgets('kosong sebelum 300ms, lalu baris tiruan', (tester) async {
    await pump(tester);
    expect(find.byType(AppSkeleton), findsNothing);

    await tester.pump(AppSkeletonPage.delay);
    // Angka utama (2 blok) + tiap baris: tile, dua garis, nominal.
    expect(find.byType(AppSkeleton), findsNWidgets(2 + 3 * 4));
  });

  testWidgets('kurangi gerakan: blok surface2 diam', (tester) async {
    await pump(tester, reduceMotion: true);
    await tester.pump(AppSkeletonPage.delay);
    final box = tester.widget<Container>(
      find.descendant(of: find.byType(AppSkeleton).first, matching: find.byType(Container)),
    );
    expect((box.decoration! as BoxDecoration).color, AppColors.light.surface2);
    // Tidak ada animasi yang tertunda.
    await tester.pumpAndSettle();
  });
}
