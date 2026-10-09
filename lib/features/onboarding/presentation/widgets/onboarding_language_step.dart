import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

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
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return ListView(
      key: const ValueKey('onboarding-language-list'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(t.onboarding.languageTitle, style: textTheme.headlineSmall)),
              const SizedBox(height: AppSpacing.space2),
              Text(t.onboarding.languageBody, style: textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        for (final locale in AppLocale.values) ...[
          Semantics(
            selected: locale == selected,
            inMutuallyExclusiveGroup: true,
            child: AppTappable(
              key: ValueKey('onboarding-language-${locale.languageCode}'),
              label: languageName(locale),
              onTap: () => onSelected(locale),
              child: AppCard(
                color: locale == selected ? colors.brandSoft : null,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space2),
                child: Row(
                  children: [
                    Expanded(child: Text(languageName(locale), style: textTheme.titleSmall)),
                    if (locale == selected) AppIcon(IconKey.check, color: colors.brand),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
        ],
      ],
    );
  }
}
