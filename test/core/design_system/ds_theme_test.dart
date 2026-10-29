import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

void main() {
  test('build disimpan per preset dan kecerahan', () {
    expect(DsTheme.build(matcha, Brightness.light), same(DsTheme.light));
    expect(DsTheme.build(matcha, Brightness.dark), same(DsTheme.dark));
    expect(DsTheme.light, isNot(same(DsTheme.dark)));
  });

  for (final (brightness, scheme) in [(Brightness.light, matcha.light), (Brightness.dark, matcha.dark)]) {
    group(brightness.name, () {
      final theme = DsTheme.build(matcha, brightness);

      test('ekstensi terpasang dan cocok dengan preset', () {
        expect(theme.extension<DsColorScheme>(), same(scheme));
        expect(theme.extension<DsTypography>(), isNotNull);
        expect(theme.extension<DsElevation>(), isNotNull);
        expect(theme.brightness, brightness);
        expect(theme.scaffoldBackgroundColor, scheme.surfaceCanvas);
        expect(theme.colorScheme.primary, scheme.primary);
      });

      test('huruf per slot TextTheme', () {
        expect(theme.textTheme.headlineMedium!.fontFamily, DsFonts.sans);
        expect(theme.textTheme.bodyMedium!.fontFamily, DsFonts.sans);
        expect(
          theme.navigationBarTheme.labelTextStyle!.resolve({WidgetState.selected})!.fontFamily,
          DsFonts.pixel,
        );
      });

      test('bentuk komponen mengikuti radius spek', () {
        final card = theme.cardTheme.shape! as RoundedRectangleBorder;
        expect(card.borderRadius, DsRadius.lgAll);
        expect(card.side.color, scheme.outlineSubtle);
        final input = theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
        expect(input.borderRadius, DsRadius.baseAll);
        expect(input.borderSide.color, scheme.outlineSubtle);
        final focused = theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder;
        expect(focused.borderSide.color, scheme.outlineFocus);
        expect(focused.borderSide.width, 1);
        expect((theme.dialogTheme.shape! as RoundedRectangleBorder).borderRadius, DsRadius.xlAll);
        expect(theme.filledButtonTheme.style!.shape!.resolve({}), DsShapes.control);
        expect(theme.bottomSheetTheme.shape, DsShapes.sheet);
      });

      test('tombol utama dan sekunder mengikuti spek saat ditekan', () {
        final primary = theme.filledButtonTheme.style!;
        expect(primary.backgroundColor!.resolve({}), scheme.actionPrimary);
        expect(primary.backgroundColor!.resolve({WidgetState.pressed}), scheme.actionPrimaryPressed);
        expect(primary.foregroundColor!.resolve({}), scheme.onActionPrimary);
        final secondary = theme.outlinedButtonTheme.style!;
        expect(secondary.side!.resolve({})!.color, scheme.outlineSubtle);
        expect(secondary.side!.resolve({WidgetState.pressed})!.color, scheme.outlineStrong);
      });
    });
  }

  test('elevasi: kartu garis rambut, overlay bayangan tipis, gelap tanpa bayangan kartu', () {
    final light = DsTheme.light.extension<DsElevation>()!;
    final dark = DsTheme.dark.extension<DsElevation>()!;
    expect(light.card.shadows.single.blurRadius, 8);
    expect(light.overlay.shadows.single.offset, const Offset(0, 8));
    expect(dark.card.shadows, isEmpty);
    expect(light.canvas.decoration().border, isNull);
    expect(light.card.decoration().border, isNotNull);
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
    expect(tokens.colors, same(matcha.light));
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
    expect(tokens.colors, same(matcha.dark));
  });
}
