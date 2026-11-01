import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/onboarding/presentation/widgets/onboarding_widgets.dart';

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
    final options = [?suggested, ...AppCurrency.values.where((c) => c != suggested)];
    // Satu gulungan untuk judul dan daftar: dengan teks besar, kepala saja
    // bisa setinggi layar.
    return ListView.separated(
      key: const ValueKey('onboarding-currency-list'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: options.length + 1,
      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 20 : 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return OnboardingStepHeader(
            asset: ClayIcons.coins,
            title: t.onboarding.currencyTitle,
            body: t.onboarding.currencyBody,
          );
        }
        final currency = options[index - 1];
        final ds = context.ds;
        return OnboardingChoice(
          key: ValueKey('onboarding-currency-${currency.code}'),
          label: '${currency.code} · ${currencyName(currency)}',
          detail: currency == suggested ? t.onboarding.currencySuggested : null,
          selected: currency == selected,
          leading: SizedBox(
            width: 40,
            child: Text(currency.symbol, style: ds.typography.amount.copyWith(color: ds.colors.actionPrimary)),
          ),
          onTap: () => onSelected(currency),
        );
      },
    );
  }
}
