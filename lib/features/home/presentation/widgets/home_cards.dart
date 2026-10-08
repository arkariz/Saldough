import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

// Keadaan kosong dan panduan Beranda (FR-HOME-005). Kartu berisi angka
// (saldo, bulan berjalan, anggaran, Freelance) ada di `home_summary.dart`
// (ADR-034, prototipe `Main.dc.html`).

/// Judul bagian, mis. "Transaksi terbaru" dengan tautan "Lihat semua"
/// (FR-HOME-004).
class HomeSectionHeader extends StatelessWidget {
  /// Membuat [HomeSectionHeader].
  const HomeSectionHeader({required this.icon, required this.title, this.trailing, super.key});

  /// Ikon judul.
  final IconKey icon;

  /// Judul.
  final String title;

  /// Isi kanan, mis. tautan atau keterangan.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, size: 22),
        const SizedBox(width: AppSpacing.space1),
        Expanded(
          child: Text(title, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
        ),
        // `Flexible`, bukan langsung `?trailing` -- label mikro naik ke
        // 11px minimum (ADR-020 §3.2) butuh sedikit lebih banyak ruang;
        // tanpa ini `trailing` panjang di teks 2x meluap (ketahuan uji
        // Freelance 360px + teks 2x, yang melewati `HomeGuide`).
        if (trailing != null) Flexible(child: trailing!),
      ],
    );
  }
}

/// Tautan teks kecil beraksen dengan panah, mis. "Lihat semua ›".
class HomeTextLink extends StatelessWidget {
  /// Membuat [HomeTextLink].
  const HomeTextLink({required this.label, required this.onTap, super.key});

  /// Teks tautan.
  final String label;

  /// Aksi.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _TextLink(label: label, onTap: onTap, chevron: true);
}

/// Keadaan kosong Beranda (FR-HOME-005): "Belum ada transaksi" dengan ajakan
/// yang membuka alur CATAT yang sama — atau, tanpa dompet sama sekali,
/// ajakan membuat dompet pertama lebih dulu.
class HomeEmptyTransactions extends StatelessWidget {
  /// Membuat [HomeEmptyTransactions].
  const HomeEmptyTransactions({
    required this.hasNoWallets,
    required this.onRecord,
    required this.onAddWallet,
    required this.onBudget,
    super.key,
  });

  /// Belum ada dompet sama sekali.
  final bool hasNoWallets;

  /// Membuka alur CATAT.
  final VoidCallback onRecord;

  /// Membuka jalan membuat dompet pertama.
  final VoidCallback onAddWallet;

  /// Membuka layar Anggaran.
  final VoidCallback onBudget;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: ShapeDecoration(color: colors.surface3, shape: const PixelCornerBorder.small()),
            // Peti kosong, sama dengan ilustrasi "Inventaris kosong" rujukan.
            child: const AppIcon(IconKey.empty, size: 80),
          ),
          const SizedBox(height: AppSpacing.space4),
          _Badge(t.home.emptyBadge, color: colors.ink2),
          const SizedBox(height: AppSpacing.space1),
          Text(t.home.emptyTitle, textAlign: TextAlign.center, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.space1),
          Text(
            hasNoWallets ? t.home.emptyNoWalletBody : t.home.emptyBody,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
          ),
          const SizedBox(height: AppSpacing.space6),
          SizedBox(
            width: double.infinity,
            child: hasNoWallets
                ? AppButton(label: t.home.createWalletAction, onPressed: onAddWallet)
                : AppButton(label: t.home.recordAction, onPressed: onRecord),
          ),
          // Anggaran butuh dompet; tanpa dompet tautan ini buntu di layar
          // Anggaran "Buat dompet dulu" (UX-7).
          if (!hasNoWallets) ...[
            const SizedBox(height: AppSpacing.space2),
            _TextLink(label: t.home.budgetLink, onTap: onBudget),
          ],
        ],
      ),
    );
  }
}

/// Panduan singkat tiga aturan utama di keadaan kosong Beranda.
class HomeGuide extends StatelessWidget {
  /// Membuat [HomeGuide].
  const HomeGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Warna kotak ikon mengikuti makna ADR-016: dompet menyimpan uang (hijau),
    // anggaran hanya rencana (netral), freelance berisi status tertunda
    // (amber).
    final rules = <(IconKey, String, String, String, Color?)>[
      (IconKey.wallets, t.home.guideWalletTitle, t.home.guideWalletTag, t.home.guideWalletBody, colors.positive),
      (IconKey.budget, t.home.guideBudgetTitle, t.home.guideBudgetTag, t.home.guideBudgetBody, null),
      (
        IconKey.freelance,
        t.home.guideFreelanceTitle,
        t.home.guideFreelanceTag,
        t.home.guideFreelanceBody,
        colors.warning,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(
          icon: IconKey.worklog,
          title: t.home.guideTitle,
          trailing: Text(
            t.home.guideCount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelSmStyle(context, color: colors.ink2),
          ),
        ),
        for (final (index, (icon, title, tag, body, color)) in rules.indexed) ...[
          const SizedBox(height: AppSpacing.space2),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBox(icon, color: color, size: 40),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.space1,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${(index + 1).toString().padLeft(2, '0')}. $title',
                            style: context.numberStyles.amountSm.copyWith(color: colors.ink),
                          ),
                          _Badge(tag, color: colors.ink2),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(body, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Lencana bersudut tegas bergaris tepi tipis, isian tipis [color].
class _Badge extends StatelessWidget {
  const _Badge(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1 + 2, vertical: 2),
      decoration: BoxDecoration(
        color: colors.tinted(color, 0.22),
        border: Border.all(color: colors.lineStrong),
      ),
      child: Text(label, style: labelSmStyle(context, color: colors.ink)),
    );
  }
}

/// Kotak ikon bergaris tepi, isian tipis [color] (netral kalau `null`).
class _IconBox extends StatelessWidget {
  const _IconBox(this.icon, {this.color, this.size = 24});

  final IconKey icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.iconTile(color),
        border: Border.all(color: colors.lineStrong),
      ),
      child: AppIcon(icon, size: size * 0.72),
    );
  }
}

/// Tautan teks kecil beraksen.
class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap, this.chevron = false});

  final String label;
  final VoidCallback onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final ink = context.appColors.brand;
    // Simpul semantik sendiri: tanpa `container`, tautan di kartu kosong
    // tergabung ke label kartu dan tidak bisa diaktifkan tersendiri (UX-12).
    return Semantics(
      container: true,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(label, style: context.numberStyles.amountSm.copyWith(color: ink)),
              ),
              if (chevron) AppIcon(IconKey.chevronRight, size: 16, color: ink),
            ],
          ),
        ),
      ),
    );
  }
}
