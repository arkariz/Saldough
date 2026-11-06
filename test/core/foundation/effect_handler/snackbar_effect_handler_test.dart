import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/effect_handler/src/snackbar_effect_handler.dart';
import 'package:state_management/state_management.dart';

/// Snackbar per [FeedbackSeverity] (design system v2): satu permukaan terbalik
/// dari tema; tingkat dibedakan lewat titik bernada di kiri, bukan warna latar.
void main() {
  final registry = EffectRegistry();
  registerSnackBarEffectHandler(registry);

  Future<void> show(WidgetTester tester, FeedbackSeverity severity) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
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
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('sukses: titik centang; latar tetap dari tema (bukan hijau pemasukan)', (tester) async {
    await show(tester, FeedbackSeverity.success);
    expect(find.text('Pengeluaran tercatat.'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor, isNull, reason: 'warna dari tema');
  });

  testWidgets('galat: titik silang, tanpa centang', (tester) async {
    await show(tester, FeedbackSeverity.error);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('peringatan: titik tanda seru', (tester) async {
    await show(tester, FeedbackSeverity.warning);
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
  });

  testWidgets('info: titik info', (tester) async {
    await show(tester, FeedbackSeverity.info);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
  });
}
