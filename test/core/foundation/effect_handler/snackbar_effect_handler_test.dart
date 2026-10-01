import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/foundation/effect_handler/src/snackbar_effect_handler.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:state_management/state_management.dart';

/// Warna snackbar per [FeedbackSeverity] (UX-17, ADR-016): sukses netral,
/// bukan hijau "uang masuk".
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

  AppColorsExtension colorsOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold))).extension<AppColorsExtension>()!;

  testWidgets('sukses: latar netral dengan ikon centang, bukan hijau pemasukan', (tester) async {
    final snackBar = await show(tester, FeedbackSeverity.success);
    final colors = colorsOf(tester);
    expect(snackBar.backgroundColor, colors.textPrimary);
    expect(snackBar.backgroundColor, isNot(colors.income));
    expect(find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.check), findsOneWidget);
  });

  testWidgets('galat tetap merah pengeluaran, tanpa ikon centang', (tester) async {
    final snackBar = await show(tester, FeedbackSeverity.error);
    expect(snackBar.backgroundColor, colorsOf(tester).expense);
    expect(find.byType(AppIcon), findsNothing);
  });

  testWidgets('info netral', (tester) async {
    final snackBar = await show(tester, FeedbackSeverity.info);
    expect(snackBar.backgroundColor, colorsOf(tester).textPrimary);
  });
}
