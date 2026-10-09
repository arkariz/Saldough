import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/account/presentation/widgets/setting_row.dart';

/// Sakelar sembunyikan nominal di layar Akun (ADR-034 §4): setelan yang sama
/// dengan tombol mata di Beranda, tersimpan dan berlaku di semua nominal.
class HideAmountsSettingEntry extends StatelessWidget {
  /// Membuat [HideAmountsSettingEntry].
  const HideAmountsSettingEntry({super.key});

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: SettingRow(
      icon: IconKey.visibilityOff,
      title: t.home.hideAmounts,
      subtitle: t.account.hideAmountsBody,
      trailing: Switch(
        key: const ValueKey('hide-amounts-setting'),
        value: AmountVisibility.hidden,
        onChanged: (hidden) => AmountVisibility.notifier.value = hidden,
      ),
    ),
  );
}
