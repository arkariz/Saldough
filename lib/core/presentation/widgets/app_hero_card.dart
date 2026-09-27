import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/fit_start.dart';
import 'package:saldough/core/presentation/widgets/kind_surfaces.dart';
import 'package:saldough/core/theme/theme.dart';

/// Kartu utama di puncak tiap tab navigasi bawah (Beranda, Anggaran,
/// Transaksi, Dompet): SATU angka yang menjawab pertanyaan utama layar itu,
/// dan titik mulai mata sebelum kartu-kartu rincian di bawahnya.
///
/// Dibedakan dari kartu biasa tanpa meminjam warna makna uang (ADR-016):
/// latar krem hangat [AppColorsSurfaces.surfaceMid] (`surfaceHigh` di mode
/// gelap; keduanya turunan warna latar,
/// jadi tetap satu keluarga dengan tema di kedua mode), garis tepi 2px, dan
/// bayangan keras lebih tebal ([AppElevation.pixelInteractive]) dari kartu
/// biasa ([AppElevation.pixelCard]). Kepalanya seragam di semua layar: kotak
/// ikon tab, label kapital, dan [trailing] (biasanya lencana).
///
/// Bidang di dalam kartu ini sebaiknya memakai [HeroInset], yang berlatar
/// kartu putih supaya terbaca di atas krem.
class AppHeroCard extends StatelessWidget {
  /// Membuat [AppHeroCard].
  const AppHeroCard({
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
    super.key,
  });

  /// Ikon tab layar ini, sama dengan ikon di navigasi bawah.
  final IconKey icon;

  /// Label kepala kartu, ditampilkan kapital.
  final String label;

  /// Isi kanan kepala, mis. lencana jumlah.
  final Widget? trailing;

  /// Isi kartu; biasanya [HeroAmount] lalu rinciannya.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        // Mode gelap: `surfaceMid` hampir sama dengan `cardBackground`, jadi
        // kartu utama tak lagi menonjol dan `HeroInset` di dalamnya hilang.
        // Satu tingkat lebih terang di sana (T-7.6).
        color: Theme.of(context).brightness == Brightness.dark ? colors.surfaceHigh : colors.surfaceMid,
        borderRadius: AppRadius.pixelSmAll,
        border: Border.all(color: colors.textPrimary, width: AppBorder.pixelThick),
        // Bawaan `hardShadow` = 4px, lebih tebal dari kartu biasa (3px).
        boxShadow: AppElevation.hardShadow(colors.textPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  border: Border.all(color: colors.textPrimary),
                ),
                child: AppIcon(icon),
              ),
              const SizedBox(width: AppSpacing.sm),
              // `Wrap`: lencana turun baris, bukan meluap, di layar sempit
              // atau teks diperbesar.
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: 4,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: transactionLabelStyle(context, size: 11, color: colors.textMuted),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Angka utama [AppHeroCard]: awalan "Rp" kecil redup dan angka besar,
/// mengecil sendiri kalau tidak muat. [color] mewarnai angkanya (mis. merah
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
    final match = RegExp(r'^([+−-]?)Rp(.*)$').firstMatch(formatted);
    final prefix = match == null ? '' : '${match[1]}Rp';
    final number = match == null ? formatted : match[2]!;
    final prefixStyle = PixelTypography.tabularMono(context, fontSize: 16, color: color ?? colors.textMuted);
    // Satu `Text.rich`: tetap terbaca sebagai satu nominal utuh (pembaca
    // layar, pencarian teks di uji) walau awalannya diperkecil.
    return FitStart(
      child: Text.rich(
        TextSpan(
          children: [
            if (prefix.isNotEmpty) ...[
              TextSpan(text: prefix.substring(0, prefix.length - 1), style: prefixStyle),
              // Jarak "Rp" ke angka lewat `letterSpacing` huruf terakhirnya,
              // bukan spasi, supaya teks nominalnya tetap utuh.
              TextSpan(text: prefix.substring(prefix.length - 1), style: prefixStyle.copyWith(letterSpacing: 4)),
            ],
            TextSpan(text: number),
          ],
        ),
        // Gaya angka utama di `Text.style`, supaya warna nominalnya (mis.
        // merah untuk saldo negatif) terbaca dari widget ini sendiri.
        style: PixelTypography.tabularMono(context, fontSize: 32, color: color ?? colors.textPrimary),
      ),
    );
  }
}

/// Bidang berlatar kartu di dalam [AppHeroCard], tanpa garis tepi.
class HeroInset extends StatelessWidget {
  /// Membuat [HeroInset].
  const HeroInset({required this.child, super.key});

  /// Isi.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: context.appColors.cardBackground, borderRadius: AppRadius.pixelSmAll),
      child: child,
    );
  }
}
