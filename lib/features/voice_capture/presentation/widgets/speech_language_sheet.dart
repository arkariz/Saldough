import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Menanyakan bahasa ucapan sekali sebelum lembar rekam pertama (ADR-028
/// §3.8). Mengembalikan bahasa terpilih, atau `null` kalau ditutup.
Future<AppLocale?> showSpeechLanguageSheet(BuildContext context) => showAppSheet<AppLocale>(
  context,
  isScrollControlled: true,
  builder: (_) => const SpeechLanguageSheet(),
);

/// Isi lembar pilihan bahasa ucapan: judul, satu keterangan kecil, pilihan
/// bahasa (bahasa aktif sudah terpilih), dan "Lanjut".
class SpeechLanguageSheet extends StatefulWidget {
  /// Membuat [SpeechLanguageSheet].
  const SpeechLanguageSheet({super.key});

  @override
  State<SpeechLanguageSheet> createState() => _SpeechLanguageSheetState();
}

class _SpeechLanguageSheetState extends State<SpeechLanguageSheet> {
  AppLocale _selected = ActiveLanguage.value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(t.record.voice.languageTitle, style: textTheme.titleLarge)),
            const SizedBox(height: AppSpacing.space1),
            Text(t.record.voice.languageBody, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
            const SizedBox(height: AppSpacing.space4),
            for (final locale in AppLocale.values) ...[
              Semantics(
                selected: locale == _selected,
                inMutuallyExclusiveGroup: true,
                child: AppTappable(
                  key: ValueKey('speech-language-${locale.languageCode}'),
                  label: languageName(locale),
                  onTap: () => setState(() => _selected = locale),
                  child: AppCard(
                    color: locale == _selected ? colors.brandSoft : null,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space2),
                    child: Row(
                      children: [
                        Expanded(child: Text(languageName(locale), style: textTheme.titleSmall)),
                        if (locale == _selected) AppIcon(IconKey.check, color: colors.brand),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
            ],
            const SizedBox(height: AppSpacing.space4),
            AppButton(
              key: const ValueKey('speech-language-continue'),
              label: t.record.voice.languageContinue,
              onPressed: () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }
}
