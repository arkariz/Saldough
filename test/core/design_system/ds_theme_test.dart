import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

void main() {
  test('build disimpan per preset dan kecerahan', () {
    expect(DsTheme.build(autumnKyoto, Brightness.light), same(DsTheme.light));
    expect(DsTheme.build(autumnKyoto, Brightness.dark), same(DsTheme.dark));
    expect(DsTheme.light, isNot(same(DsTheme.dark)));
  });

  for (final (brightness, scheme) in [(Brightness.light, autumnKyoto.light), (Brightness.dark, autumnKyoto.dark)]) {
    group(brightness.name, () {
      final theme = DsTheme.build(autumnKyoto, brightness);

      test('ekstensi terpasang dan cocok dengan preset', () {
        expect(theme.extension<DsColorScheme>(), same(scheme));
        expect(theme.extension<DsTypography>(), isNotNull);
        expect(theme.extension<DsElevation>(), isNotNull);
        expect(theme.brightness, brightness);
        expect(theme.scaffoldBackgroundColor, scheme.surfaceCanvas);
        expect(theme.colorScheme.primary, scheme.primary);
      });

      test('huruf per slot TextTheme', () {
        expect(theme.textTheme.headlineMedium!.fontFamily, DsFonts.heading);
        expect(theme.textTheme.bodyMedium!.fontFamily, DsFonts.body);
        expect(theme.textTheme.labelMedium!.fontFamily, DsFonts.mono);
      });

      test('bentuk komponen mengikuti radius spek', () {
        final card = theme.cardTheme.shape! as RoundedRectangleBorder;
        expect(card.borderRadius, DsRadius.lgAll);
        expect(card.side.color, scheme.outlineSubtle);
        final input = theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
        expect(input.borderRadius, DsRadius.baseAll);
        expect(input.borderSide.color, scheme.outlineStrong);
        expect(theme.filledButtonTheme.style!.shape!.resolve({}), DsShapes.control);
        expect(theme.bottomSheetTheme.shape, DsShapes.sheet);
      });

      test('tombol utama ditekan menggelap dengan garis dasar', () {
        final style = theme.filledButtonTheme.style!;
        expect(style.backgroundColor!.resolve({}), scheme.actionPrimary);
        expect(style.backgroundColor!.resolve({WidgetState.pressed}), scheme.actionPrimaryPressed);
        expect(style.side!.resolve({WidgetState.pressed})!.color, scheme.actionPrimaryStroke);
        expect(style.foregroundColor!.resolve({}), scheme.onActionPrimary);
      });
    });
  }

  test('elevasi terang memakai bayangan spek, gelap tanpa bayangan tier 1', () {
    final light = DsTheme.light.extension<DsElevation>()!;
    final dark = DsTheme.dark.extension<DsElevation>()!;
    expect(light.tier1.shadows.single.blurRadius, 2);
    expect(light.tier2.shadows, hasLength(2));
    expect(light.tier3.shadows.first.offset, const Offset(0, 12));
    expect(dark.tier1.shadows, isEmpty);
    expect(light.tier0.decoration().border, isNull);
    expect(light.tier1.decoration().border, isNotNull);
  });

  testWidgets('context.ds jatuh ke preset bawaan tanpa ekstensi', (tester) async {
    late DsTokens tokens;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            tokens = context.ds;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(tokens.colors, same(autumnKyoto.light));
  });

  testWidgets('context.ds membaca ekstensi tema aktif', (tester) async {
    late DsTokens tokens;
    await tester.pumpWidget(
      MaterialApp(
        theme: DsTheme.dark,
        home: Builder(
          builder: (context) {
            tokens = context.ds;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(tokens.colors, same(autumnKyoto.dark));
  });
}
