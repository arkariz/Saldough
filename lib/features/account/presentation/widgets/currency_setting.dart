import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/account/presentation/bloc/account_bloc.dart';
import 'package:state_management/state_management.dart';

/// Contoh nominal di dialog konfirmasi: 50.000 satuan utama.
const _exampleSen = 5000000;

/// Nama mata uang di bahasa aktif.
String currencyName(AppCurrency currency) => switch (currency) {
  AppCurrency.idr => t.currency.names.idr,
  AppCurrency.usd => t.currency.names.usd,
  AppCurrency.eur => t.currency.names.eur,
  AppCurrency.gbp => t.currency.names.gbp,
  AppCurrency.jpy => t.currency.names.jpy,
  AppCurrency.cny => t.currency.names.cny,
  AppCurrency.krw => t.currency.names.krw,
  AppCurrency.inr => t.currency.names.inr,
  AppCurrency.sgd => t.currency.names.sgd,
  AppCurrency.myr => t.currency.names.myr,
  AppCurrency.thb => t.currency.names.thb,
  AppCurrency.php => t.currency.names.php,
  AppCurrency.vnd => t.currency.names.vnd,
  AppCurrency.aud => t.currency.names.aud,
};

/// Bagian "Pengaturan" layar Akun: pilihan mata uang (ADR-025 §3.6). Tampil
/// baik sudah maupun belum masuk — mata uang tidak butuh akun.
class CurrencySettingSection extends StatelessWidget {
  /// Membuat [CurrencySettingSection].
  const CurrencySettingSection({super.key});

  Future<void> _choose(BuildContext context) async {
    final current = ActiveCurrency.value;
    final picked = await showDialog<AppCurrency>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(t.currency.pickerTitle),
        children: [
          for (final currency in AppCurrency.values)
            SimpleDialogOption(
              key: ValueKey('currency-option-${currency.code}'),
              onPressed: () => Navigator.of(dialogContext).pop(currency),
              child: Row(
                children: [
                  Expanded(child: Text('${currency.code} · ${currencyName(currency)}')),
                  if (currency == current) const AppIcon(IconKey.check),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || picked == current || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.currency.changeTitle(code: picked.code)),
        content: Text(
          t.currency.changeBody(
            before: AppMoneyFormatter.format(_exampleSen),
            after: AppMoneyFormatter.format(_exampleSen, currency: picked),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(t.common.cancel)),
          TextButton(
            key: const ValueKey('currency-change-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.currency.changeAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<AccountBloc>().add(AccountCurrencyChangeRequested(picked));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return ValueListenableBuilder<AppCurrency>(
      valueListenable: ActiveCurrency.notifier,
      builder: (context, currency, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionLabel(t.currency.settingsTitle),
          const SizedBox(height: AppSpacing.xs),
          AppTappable(
            key: const ValueKey('currency-setting'),
            label: t.currency.label,
            onTap: () => _choose(context),
            child: AppHardCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.currency.label, style: textTheme.titleSmall),
                        Text(
                          '${currency.code} · ${currencyName(currency)}',
                          style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const AppIcon(IconKey.chevronRight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
