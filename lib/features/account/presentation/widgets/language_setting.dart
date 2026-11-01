import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/account/presentation/bloc/account_bloc.dart';
import 'package:saldough/features/account/presentation/widgets/setting_row.dart';
import 'package:state_management/state_management.dart';

/// Pilihan bahasa di bagian "Pengaturan" layar Akun (ADR-028 §3.5): satu
/// pilihan untuk tampilan aplikasi dan bahasa ucapan. Berlaku seketika.
class LanguageSettingEntry extends StatelessWidget {
  /// Membuat [LanguageSettingEntry].
  const LanguageSettingEntry({super.key});

  Future<void> _choose(BuildContext context) async {
    final current = ActiveLanguage.value;
    final picked = await showOptionSheet<AppLocale>(
      context,
      title: t.language.pickerTitle,
      current: current,
      options: [
        for (final locale in AppLocale.values)
          OptionSheetItem(
            key: ValueKey('language-option-${locale.languageCode}'),
            value: locale,
            label: languageName(locale),
          ),
      ],
    );
    if (picked == null || picked == current || !context.mounted) return;
    context.read<AccountBloc>().add(AccountLanguageChangeRequested(picked));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLocale>(
      valueListenable: ActiveLanguage.notifier,
      builder: (context, locale, _) => SettingRow(
        key: const ValueKey('language-setting'),
        icon: IconKey.translate,
        title: t.language.label,
        subtitle: '${languageName(locale)} · ${t.language.hint}',
        onTap: () => _choose(context),
      ),
    );
  }
}
