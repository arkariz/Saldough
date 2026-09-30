import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/features/record/presentation/capture/speech_language_sheet.dart';

/// Lembar pilihan bahasa ucapan (ADR-028 §3.8).
void main() {
  Future<void> open(WidgetTester tester, void Function(AppLocale?) onResult) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => onResult(await showSpeechLanguageSheet(context)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('bahasa aktif terpilih lebih dulu; Lanjut mengembalikan pilihan', (tester) async {
    AppLocale? result;
    await open(tester, (r) => result = r);

    expect(find.text(t.record.voice.languageTitle), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('speech-language-continue')));
    await tester.pumpAndSettle();
    expect(result, ActiveLanguage.value);
  });

  testWidgets('memilih bahasa lain lalu Lanjut', (tester) async {
    AppLocale? result;
    await open(tester, (r) => result = r);

    await tester.tap(find.byKey(const ValueKey('speech-language-en')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('speech-language-continue')));
    await tester.pumpAndSettle();
    expect(result, AppLocale.en);
  });
}
