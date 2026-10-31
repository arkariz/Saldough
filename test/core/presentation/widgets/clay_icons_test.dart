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
    expect(ClayIcons.all.toSet(), hasLength(48));
    final onDisk = Directory(
      'assets/icons_clay',
    ).listSync().where((e) => e.path.endsWith('.svg')).map((e) => e.path).toSet();
    expect(ClayIcons.all.toSet(), onDisk, reason: 'setiap berkas terdaftar dan sebaliknya');
    expect(File('pubspec.yaml').readAsStringSync(), contains('assets/icons_clay/'));
  });

  test('forIcon: semua ikon benda (kategori, dompet, jenis, Freelance) punya clay', () {
    const skipped = {IconKey.balanceSpread};
    final things = IconKey.values
        .where((k) {
          final n = k.name;
          return n.startsWith('category') ||
              n.startsWith('wallet') && n != 'wallets' ||
              const [
                'income',
                'expense',
                'transfer',
                'freelance',
                'worklog',
                'hourlyRate',
                'invoice',
                'workCompleted',
                'pending',
                'paid',
                'overBudget',
                'empty',
              ].contains(n);
        })
        .where((k) => !skipped.contains(k));
    for (final key in things) {
      expect(ClayIcons.forIcon(key), isNotNull, reason: key.name);
    }
  });

  test('forIcon: kategori yang sudah digambar dipetakan, ikon tindakan tidak', () {
    expect(ClayIcons.forIcon(IconKey.categoryCoffee), ClayIcons.coffee);
    expect(ClayIcons.forIcon(IconKey.categoryTransport), ClayIcons.train);
    expect(ClayIcons.forIcon(IconKey.freelance), ClayIcons.stylus);
    expect(ClayIcons.forIcon(IconKey.categoryHealth), ClayIcons.heart);
    expect(ClayIcons.forIcon(IconKey.add), isNull);
  });

  testWidgets('setiap aset clay terurai oleh flutter_svg tanpa galat', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DsTheme.light,
        home: Scaffold(
          body: Wrap(children: [for (final a in ClayIcons.all) SvgPicture.asset(a, width: 32, height: 32)]),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(SvgPicture), findsNWidgets(ClayIcons.all.length));
  });

  testWidgets('DsIconTile.asset memuat SVG di tile datar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DsTheme.light,
        home: Scaffold(
          body: Center(child: DsIconTile.asset(asset: ClayIcons.coffee)),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
    final box = tester.widget<Container>(
      find.descendant(of: find.byType(DsIconTile), matching: find.byType(Container)).first,
    );
    expect((box.decoration! as BoxDecoration).color, matcha.light.surfaceSunken);
    expect((box.decoration! as BoxDecoration).boxShadow, isNull);
  });
}
