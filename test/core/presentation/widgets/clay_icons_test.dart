import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';

void main() {
  test('semua aset clay ada di disk, valid, dan tanpa filter', () {
    for (final path in ClayIcons.all) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      final svg = file.readAsStringSync();
      expect(svg, startsWith('<svg'), reason: path);
      expect(svg.toLowerCase(), isNot(contains('<filter')), reason: '$path: flutter_svg tak mendukung filter');
    }
    expect(ClayIcons.all.toSet(), hasLength(10));
    expect(File('pubspec.yaml').readAsStringSync(), contains('assets/icons_clay/'));
  });

  test('forIcon: kategori yang sudah digambar dipetakan, sisanya null', () {
    expect(ClayIcons.forIcon(IconKey.categoryCoffee), ClayIcons.coffee);
    expect(ClayIcons.forIcon(IconKey.categoryTransport), ClayIcons.train);
    expect(ClayIcons.forIcon(IconKey.freelance), ClayIcons.stylus);
    expect(ClayIcons.forIcon(IconKey.categoryHealth), isNull);
  });

  testWidgets('DsIconTile.asset memuat SVG di tile datar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DsTheme.light,
        home: Scaffold(body: Center(child: DsIconTile.asset(asset: ClayIcons.coffee))),
      ),
    );
    await tester.pump();
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
    final box = tester.widget<Container>(find.descendant(of: find.byType(DsIconTile), matching: find.byType(Container)).first);
    expect((box.decoration! as BoxDecoration).color, matcha.light.surfaceSunken);
    expect((box.decoration! as BoxDecoration).boxShadow, isNull);
  });
}
