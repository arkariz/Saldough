import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Langkah pilih mata uang, gerbang terakhir onboarding pertama kali
/// (ADR-025 §3.7).
///
/// Tidak ada pilihan yang terpilih otomatis: [suggested] hanya ditaruh
/// paling atas dengan keterangan. Tombol lanjut ada di `OnboardingPage` dan
/// aktif setelah [selected] terisi.
class OnboardingCurrencyStep extends StatelessWidget {
  /// Membuat [OnboardingCurrencyStep].
  const OnboardingCurrencyStep({required this.selected, required this.onSelected, this.suggested, super.key});

  /// Pilihan pengguna, `null` sampai ada yang diketuk.
  final AppCurrency? selected;

  /// Saran dari wilayah perangkat, kalau ada.
  final AppCurrency? suggested;

  /// Dipanggil saat satu mata uang diketuk.
  final ValueChanged<AppCurrency> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final options = [?suggested, ...AppCurrency.values.where((c) => c != suggested)];
    // Satu gulungan untuk judul dan daftar: dengan teks besar, kartu judul
    // saja bisa setinggi layar.
    return ListView.separated(
      key: const ValueKey('onboarding-currency-list'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      itemCount: options.length + 1,
      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? AppSpacing.space4 : AppSpacing.space1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return AppHardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(t.onboarding.currencyTitle, style: textTheme.headlineSmall)),
                const SizedBox(height: AppSpacing.space2),
                Text(t.onboarding.currencyBody, style: textTheme.bodyMedium),
              ],
            ),
          );
        }
        final currency = options[index - 1];
        return _CurrencyOption(
          currency: currency,
          selected: currency == selected,
          suggested: currency == suggested,
          onTap: () => onSelected(currency),
        );
      },
    );
  }
}

class _CurrencyOption extends StatelessWidget {
  const _CurrencyOption({required this.currency, required this.selected, required this.suggested, required this.onTap});

  final AppCurrency currency;
  final bool selected;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final name = '${currency.code} · ${currencyName(currency)}';
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AppTappable(
        key: ValueKey('onboarding-currency-${currency.code}'),
        label: name,
        onTap: onTap,
        child: AppHardCard(
          pressed: selected,
          color: selected ? colors.tinted(colors.brand, 0.18) : null,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space2),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(currency.symbol, style: context.numberStyles.amount.copyWith(color: colors.brand)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: textTheme.titleSmall),
                    if (suggested)
                      Text(t.onboarding.currencySuggested, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
                  ],
                ),
              ),
              if (selected) const AppIcon(IconKey.check),
            ],
          ),
        ),
      ),
    );
  }
}
