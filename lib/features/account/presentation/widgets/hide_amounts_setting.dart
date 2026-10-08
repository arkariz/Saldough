import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Sakelar sembunyikan nominal di layar Akun (ADR-034 §4): setelan yang sama
/// dengan tombol mata di Beranda, tersimpan dan berlaku di semua nominal.
class HideAmountsSettingEntry extends StatelessWidget {
  /// Membuat [HideAmountsSettingEntry].
  const HideAmountsSettingEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space2),
      child: AppCard(
        child: MergeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.home.hideAmounts, style: textTheme.titleSmall),
                    Text(
                      t.account.hideAmountsBody,
                      style: textTheme.bodyMedium?.copyWith(
                        color: context.appColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: const ValueKey('hide-amounts-setting'),
                value: AmountVisibility.hidden,
                onChanged: (hidden) => AmountVisibility.notifier.value = hidden,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
