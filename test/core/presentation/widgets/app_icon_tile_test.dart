import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Komponen IconTile (ADR-034): ikon piksel 32px di tile `surface2`, Material
/// Symbols di tile `cat-*`.
void main() {
  Future<void> pump(WidgetTester tester, Widget tile) => tester.pumpWidget(
    MaterialApp(
      theme: PixelTheme.light,
      home: Scaffold(body: Center(child: tile)),
    ),
  );

  ShapeDecoration decorationOf(WidgetTester tester) =>
      tester
              .widget<Container>(
                find.descendant(
                  of: find.byType(AppIconTile),
                  matching: find.byType(Container),
                ),
              )
              .decoration!
          as ShapeDecoration;

  testWidgets(
    'ikon piksel: tile surface2 40px, ikon 32px skala 1:1, sudut piksel kecil',
    (tester) async {
      await pump(tester, const AppIconTile(IconKey.categoryFood));
      expect(tester.getSize(find.byType(AppIconTile)), const Size(40, 40));
      expect(tester.getSize(find.byType(SvgPicture)), const Size(32, 32));
      final decoration = decorationOf(tester);
      expect(decoration.color, AppColors.light.surface2);
      expect(decoration.shape, const PixelCornerBorder.small());
    },
  );

  testWidgets('ikon piksel tetap 32px di tile kepala rincian 48px', (
    tester,
  ) async {
    await pump(tester, const AppIconTile(IconKey.walletBank, size: 48));
    expect(tester.getSize(find.byType(SvgPicture)), const Size(32, 32));
  });

  testWidgets(
    'tanpa ikon piksel: Material Symbols di tile berwarna sesuai tabel',
    (tester) async {
      await pump(tester, const AppIconTile(IconKey.categoryFamily));
      expect(decorationOf(tester).color, AppColors.light.catBrownBg);
      expect(
        tester.widget<Icon>(find.byType(Icon)).color,
        AppColors.light.catBrown,
      );

      await pump(tester, const AppIconTile(IconKey.categoryGift));
      expect(decorationOf(tester).color, AppColors.light.catRoseBg);

      await pump(tester, const AppIconTile(IconKey.categoryOther));
      expect(decorationOf(tester).color, AppColors.light.catSlateBg);
    },
  );

  testWidgets('tint menimpa warna bawaan varian Material Symbols', (
    tester,
  ) async {
    await pump(
      tester,
      const AppIconTile(IconKey.categoryOther, tint: TileTint.teal),
    );
    expect(decorationOf(tester).color, AppColors.light.catTealBg);
  });

  testWidgets('tile diabaikan pembaca layar; baris yang menjelaskan', (
    tester,
  ) async {
    await pump(tester, const AppIconTile(IconKey.categoryFood));
    expect(find.byType(ExcludeSemantics), findsWidgets);
  });

  test('PixelCornerBorder memotong sudut dua langkah', () {
    final path = PixelCornerBorder.pathFor(
      const Rect.fromLTWH(0, 0, 40, 40),
      4,
    );
    expect(path.contains(const Offset(0.5, 0.5)), isFalse);
    expect(path.contains(const Offset(5, 5)), isTrue);
    expect(path.contains(const Offset(20, 0.5)), isTrue);
    expect(path.contains(const Offset(39.5, 39.5)), isFalse);
  });
}
