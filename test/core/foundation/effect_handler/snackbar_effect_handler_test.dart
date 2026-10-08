import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/foundation/effect_handler/src/snackbar_effect_handler.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:state_management/state_management.dart';

/// Snackbar per [FeedbackSeverity] (ADR-034): satu latar `inverse-surface`,
/// tingkat dibedakan lewat ikon, sukses bukan hijau "uang masuk".
void main() {
  final registry = EffectRegistry();
  registerSnackBarEffectHandler(registry);

  Future<SnackBar> show(WidgetTester tester, FeedbackSeverity severity) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    registry.handle(captured, ShowSnackBarEffect(message: 'Pengeluaran tercatat.', severity: severity));
    await tester.pump();
    return tester.widget<SnackBar>(find.byType(SnackBar));
  }

  AppColors colorsOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold))).extension<AppColors>()!;

  testWidgets('sukses: latar inverse-surface dengan ikon centang, bukan hijau pemasukan', (tester) async {
    final snackBar = await show(tester, FeedbackSeverity.success);
    final colors = colorsOf(tester);
    expect(snackBar.backgroundColor, colors.inverseSurface);
    expect(snackBar.backgroundColor, isNot(colors.positive));
    expect(find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.check), findsOneWidget);
  });

  testWidgets('galat: latar sama, dibedakan ikon info, tanpa ikon centang', (tester) async {
    final snackBar = await show(tester, FeedbackSeverity.error);
    expect(snackBar.backgroundColor, colorsOf(tester).inverseSurface);
    expect(find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.info), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.check), findsNothing);
  });

  testWidgets('info: latar inverse-surface tanpa ikon', (tester) async {
    final snackBar = await show(tester, FeedbackSeverity.info);
    expect(snackBar.backgroundColor, colorsOf(tester).inverseSurface);
    expect(find.byType(AppIcon), findsNothing);
  });
}
