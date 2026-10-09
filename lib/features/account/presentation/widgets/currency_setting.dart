import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/account/presentation/bloc/account_bloc.dart';
import 'package:saldough/features/account/presentation/widgets/setting_row.dart';
import 'package:state_management/state_management.dart';

/// Contoh nominal di dialog konfirmasi: 50.000 satuan utama.
const _exampleSen = 5000000;

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
                  Expanded(
                    child: Text('${currency.code} · ${currencyName(currency)}'),
                  ),
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
          AppButton.text(
            small: true,
            label: t.common.cancel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton.text(
            key: const ValueKey('currency-change-confirm'),
            small: true,
            label: t.currency.changeAction,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<AccountBloc>().add(AccountCurrencyChangeRequested(picked));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppCurrency>(
      valueListenable: ActiveCurrency.notifier,
      builder: (context, currency, _) => SettingRow(
        key: const ValueKey('currency-setting'),
        icon: IconKey.payments,
        title: t.currency.label,
        subtitle: '${currency.code} · ${currencyName(currency)}',
        onTap: () => _choose(context),
      ),
    );
  }
}
