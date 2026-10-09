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
    final picked = await showDialog<AppLocale>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(t.language.pickerTitle),
        children: [
          for (final locale in AppLocale.values)
            SimpleDialogOption(
              key: ValueKey('language-option-${locale.languageCode}'),
              onPressed: () => Navigator.of(dialogContext).pop(locale),
              child: Row(
                children: [
                  Expanded(child: Text(languageName(locale))),
                  if (locale == current) const AppIcon(IconKey.check),
                ],
              ),
            ),
        ],
      ),
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
