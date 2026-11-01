import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// Langkah pilih bahasa, langkah pertama onboarding pertama kali (ADR-028
/// §3.4). Bahasa saat ini sudah terpilih; mengetuk pilihan lain langsung
/// mengganti teks layar lewat [onSelected]. Tombol lanjut ada di
/// `OnboardingPage`.
class OnboardingLanguageStep extends StatelessWidget {
  /// Membuat [OnboardingLanguageStep].
  const OnboardingLanguageStep({required this.selected, required this.onSelected, super.key});

  /// Bahasa terpilih.
  final AppLocale selected;

  /// Dipanggil saat satu bahasa diketuk.
  final ValueChanged<AppLocale> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('onboarding-language-list'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        OnboardingStepHeader(
          asset: ClayIcons.globe,
          title: t.onboarding.languageTitle,
          body: t.onboarding.languageBody,
        ),
        const SizedBox(height: 20),
        for (final locale in AppLocale.values) ...[
          OnboardingChoice(
            key: ValueKey('onboarding-language-${locale.languageCode}'),
            label: languageName(locale),
            selected: locale == selected,
            onTap: () => onSelected(locale),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
