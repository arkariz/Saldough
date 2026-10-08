import 'package:flutter/material.dart';
import 'package:saldough/core/currency/active_currency.dart';
import 'package:saldough/core/presentation/spotlight/tutorial_info_button.dart';
import 'package:saldough/core/presentation/widgets/app_card.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/fit_start.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';

/// Kartu ringkasan di puncak tab yang belum dirombak ke pola layar baru
/// (peralihan Fase 14): satu angka utama dan rinciannya di kartu `surface`
/// bersudut piksel, kepala label huruf biasa.
///
/// Layar yang sudah memakai pola baru menaruh angka utamanya di atas `bg`
/// tanpa kartu (design system bagian Pola layar) atau, khusus Beranda, di
/// [AppHeroCard]. Hapus begitu tidak ada pemakainya (T-14.6–T-14.9).
class AppSummaryCard extends StatelessWidget {
  /// Membuat [AppSummaryCard].
  const AppSummaryCard({
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
    this.tour,
    super.key,
  });

  /// Ikon tab layar ini.
  final IconKey icon;

  /// Label kepala kartu.
  final String label;

  /// Isi kanan kepala, mis. lencana jumlah.
  final Widget? trailing;

  /// Tur layar ini; kalau diisi, ikon info (putar ulang tur) tampil di ujung
  /// kanan kepala (KO-4, ADR-021 §3.5).
  final TourId? tour;

  /// Isi kartu; biasanya [HeroAmount] lalu rinciannya.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // `Wrap`: lencana turun baris, bukan meluap, di layar sempit
              // atau teks diperbesar.
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.space1,
                  runSpacing: 4,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink2)),
                    ?trailing,
                  ],
                ),
              ),
              if (tour case final tour?) TutorialInfoButton(tour: tour),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          child,
        ],
      ),
    );
  }
}

/// Kartu saldo terakota dengan kepala tanuki mengintip dari tepi bawah
/// (komponen HeroCard, ADR-034). Satu per layar, hanya di Beranda dan
/// halaman ringkasan.
///
/// Latar `brand`, semua teks `onBrand`: label `body-sm`, angka
/// `amount-hero` dengan simbol mata uang diperkecil, lalu tautan ke
/// rinciannya ([linkLabel]). Kepala tanuki 96px di kanan bawah, skala
/// sepertiga gambar aslinya supaya pikselnya tetap tajam.
class AppHeroCard extends StatelessWidget {
  /// Membuat [AppHeroCard].
  const AppHeroCard({
    required this.label,
    required this.amount,
    this.linkLabel,
    this.onLinkTap,
    super.key,
  });

  /// Label di atas angka ("Total saldo").
  final String label;

  /// Angka utama; biasanya [HeroAmount] dengan `onBrand`, atau `AppMoneyText`
  /// tersembunyi.
  final Widget amount;

  /// Tautan ke rincian ("Di 4 dompet").
  final String? linkLabel;

  /// Dipanggil saat tautan diketuk.
  final VoidCallback? onLinkTap;

  /// Lebar tampil kepala tanuki (gambar asli 288×226, skala 1/3).
  static const mascotWidth = 96.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space2, 0),
      decoration: ShapeDecoration(color: colors.brand, shape: const PixelCornerBorder()),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.bodyMedium?.copyWith(color: colors.onBrand)),
                  const SizedBox(height: 2),
                  DefaultTextStyle.merge(style: TextStyle(color: colors.onBrand), child: amount),
                  if (linkLabel case final link?)
                    Semantics(
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onLinkTap,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: AppSize.touch),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(link, style: textTheme.labelLarge?.copyWith(color: colors.onBrand)),
                              ),
                              AppIcon(IconKey.chevronRight, size: AppSize.iconSm, color: colors.onBrand),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          ExcludeSemantics(
            child: Image.asset(
              'assets/illustration/mascot_head.png',
              width: mascotWidth,
              filterQuality: FilterQuality.none,
            ),
          ),
        ],
      ),
    );
  }
}

/// Angka utama `amount-hero`: simbol mata uang diperkecil di depan angka
/// besar (`.tk-amt__cur`), mengecil sendiri kalau tidak muat. [color] mewarnai angkanya (mis. merah
/// untuk saldo negatif); bawaan warna teks utama.
class HeroAmount extends StatelessWidget {
  /// Membuat [HeroAmount] dari teks nominal yang sudah diformat, mis.
  /// `Rp848.250`, `−Rp1.000` atau `+Rp5.000`.
  const HeroAmount(this.formatted, {this.color, super.key});

  /// Nominal terformat lewat `AppMoneyFormatter`.
  final String formatted;

  /// Warna angka.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final symbol = ActiveCurrency.value.symbol;
    final match = RegExp('^([+−-]?)${RegExp.escape(symbol)}(.*)\$').firstMatch(formatted);
    final prefix = match == null ? '' : '${match[1]}$symbol';
    final number = match == null ? formatted : match[2]!;
    final heroStyle = context.numberStyles.amountHero;
    final prefixStyle = heroStyle.copyWith(
      fontSize: heroStyle.fontSize! * 0.56,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: color ?? colors.ink2,
    );
    // Satu `Text.rich`: tetap terbaca sebagai satu nominal utuh (pembaca
    // layar, pencarian teks di uji) walau awalannya diperkecil.
    return FitStart(
      child: Text.rich(
        TextSpan(
          children: [
            if (prefix.isNotEmpty) ...[
              TextSpan(text: prefix.substring(0, prefix.length - 1), style: prefixStyle),
              // Jarak simbol ke angka lewat `letterSpacing` huruf terakhirnya,
              // bukan spasi, supaya teks nominalnya tetap utuh.
              TextSpan(text: prefix.substring(prefix.length - 1), style: prefixStyle.copyWith(letterSpacing: 4)),
            ],
            TextSpan(text: number),
          ],
        ),
        // Gaya angka utama di `Text.style`, supaya warna nominalnya (mis.
        // merah untuk saldo negatif) terbaca dari widget ini sendiri.
        style: context.numberStyles.amountHero.copyWith(color: color ?? colors.ink),
      ),
    );
  }
}

/// Bidang cekung `surface2` di dalam [AppSummaryCard].
class HeroInset extends StatelessWidget {
  /// Membuat [HeroInset].
  const HeroInset({required this.child, super.key});

  /// Isi.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space2),
      decoration: ShapeDecoration(color: context.appColors.surface2, shape: const PixelCornerBorder.small()),
      child: child,
    );
  }
}
