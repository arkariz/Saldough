import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/design_system/legacy/app_theme_bridge.dart';
import 'package:saldough/core/design_system/presets/ds_theme_presets.dart';
import 'package:saldough/core/presentation/widgets/app_action_snack_bar.dart';

/// Snackbar v2: tema, titik bernada, judul + isi, dan aksi.
void main() {
  Future<void> show(
    WidgetTester tester,
    SnackBar Function(BuildContext context) build, {
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, brightness),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(build(context)),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('tema jembatan memakai snackbar v2: mengambang, sudut 16, permukaan terbalik', (tester) async {
    final theme = AppThemeBridge.build(DsThemePresets.fallback, Brightness.light);
    final colors = theme.extension<DsColorScheme>()!;
    final snack = theme.snackBarTheme;
    expect(snack.behavior, SnackBarBehavior.floating);
    expect(snack.backgroundColor, colors.inverseSurface);
    expect(snack.actionTextColor, colors.inversePrimary);
    expect(snack.shape, const RoundedRectangleBorder(borderRadius: DsRadius.lgAll));
  });

  testWidgets('judul tebal dan isi di bawahnya; titik nada ada tetapi tidak dibacakan', (tester) async {
    await show(
      tester,
      (context) => dsSnackBar(
        context.ds,
        tone: DsSnackTone.info,
        content: const DsSnackMessage(title: 'Catat otomatis dari BCA?', message: 'Langsung dicatat tanpa kamu cek.'),
      ),
    );
    expect(find.text('Catat otomatis dari BCA?'), findsOneWidget);
    expect(find.text('Langsung dicatat tanpa kamu cek.'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
  });

  for (final (tone, icon) in [
    (DsSnackTone.success, Icons.check_rounded),
    (DsSnackTone.warning, Icons.priority_high_rounded),
    (DsSnackTone.error, Icons.close_rounded),
  ]) {
    testWidgets('nada ${tone.name} punya ikon sendiri', (tester) async {
      await show(tester, (context) => dsSnackBar(context.ds, tone: tone, content: const Text('pesan')));
      expect(find.byIcon(icon), findsOneWidget);
    });
  }

  testWidgets('aksi: kunci dan tombol dipertahankan, ketukan memanggil onPressed', (tester) async {
    var undone = 0;
    await show(
      tester,
      (context) => dsSnackBar(
        context.ds,
        content: const Text('Tercatat'),
        tone: DsSnackTone.success,
        action: SnackBarAction(key: const ValueKey('undo'), label: 'Batalkan', onPressed: () => undone++),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('undo')));
    expect(undone, 1);
  });

  testWidgets('ber-aksi hilang sendiri; tanpa aksi lebih singkat', (tester) async {
    await show(
      tester,
      (context) => dsSnackBar(
        context.ds,
        content: const Text('Tercatat'),
        action: SnackBarAction(label: 'Batalkan', onPressed: () {}),
      ),
    );
    expect(find.text('Tercatat'), findsOneWidget);
    await tester.pump(dsSnackBarActionDuration + const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Tercatat'), findsNothing);
  });

  testWidgets('mode gelap tidak melempar', (tester) async {
    await show(
      tester,
      (context) => dsSnackBar(context.ds, content: const Text('gelap')),
      brightness: Brightness.dark,
    );
    expect(find.text('gelap'), findsOneWidget);
  });

  testWidgets('satu slot: snackbar baru menggantikan yang tampil dan membuang antreannya', (tester) async {
    late ScaffoldMessengerState messenger;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              messenger = ScaffoldMessenger.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    messenger
      ..showAppSnackBar(const SnackBar(content: Text('satu')))
      ..showAppSnackBar(const SnackBar(content: Text('dua')))
      ..showAppSnackBar(const SnackBar(content: Text('tiga')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('tiga'), findsOneWidget);
    expect(find.text('satu'), findsNothing);
    expect(find.text('dua'), findsNothing);
    // Tidak ada yang menunggu di belakang: sesudah ditutup, tidak ada yang muncul.
    messenger.hideCurrentSnackBar();
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });
}
