import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

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
    final ds = context.ds;
    final c = ds.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: DsIconTile.asset(asset: ClayIcons.globe, size: DsIconTileSize.lg),
            ),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                t.record.voice.languageTitle,
                textAlign: TextAlign.center,
                style: ds.typography.headlineMd.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.record.voice.languageBody,
              textAlign: TextAlign.center,
              style: ds.typography.bodySm.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 16),
            for (final locale in AppLocale.values) ...[
              Semantics(
                selected: locale == _selected,
                inMutuallyExclusiveGroup: true,
                child: DsPressable(
                  key: ValueKey('speech-language-${locale.languageCode}'),
                  semanticLabel: languageName(locale),
                  onPressed: () => setState(() => _selected = locale),
                  builder: (context, _) => AnimatedContainer(
                    duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.standard,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: locale == _selected ? c.actionPrimary.withValues(alpha: 0.06) : c.surfaceCard,
                      borderRadius: DsRadius.lgAll,
                      border: Border.all(
                        color: locale == _selected ? c.actionPrimary : c.outlineSubtle,
                        width: locale == _selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(languageName(locale), style: ds.typography.titleMd.copyWith(fontSize: 15)),
                        ),
                        if (locale == _selected) Icon(Icons.check_circle, color: c.actionPrimary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            DsButton(
              key: const ValueKey('speech-language-continue'),
              expand: true,
              label: t.record.voice.languageContinue,
              onPressed: () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }
}
