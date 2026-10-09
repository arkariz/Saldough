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

/// Beranda pertama kali (prototipe `BerandaKosong.dc.html`): tanpa dompet,
/// ilustrasi + "Mulai dari dompetmu"; lalu daftar tiga langkah (tambah
/// dompet, catat transaksi pertama, buat anggaran) dan satu tombol primer
/// untuk langkah yang sedang berjalan. Langkah yang selesai bertanda centang.
///
/// Tidak pernah membuat transaksi sendiri: "Catat transaksi" membuka alur
/// CATAT yang sama lewat [onRecord] (aturan 8).
class HomeFirstSteps extends StatelessWidget {
  /// Membuat [HomeFirstSteps].
  const HomeFirstSteps({
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
    final current = hasNoWallets ? 0 : 1;
    final steps = [
      (t.home.stepWalletTitle, t.home.stepWalletBody),
      (t.home.stepRecordTitle, t.home.stepRecordBody),
      (t.home.stepBudgetTitle, t.home.stepBudgetBody),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasNoWallets)
          AppEmptyState(art: EmptyArt.home, title: t.home.firstTitle, body: t.home.firstBody)
        else ...[
          AppEmptyState(title: t.home.emptyTitle, body: t.home.emptyBody),
          AppSectionHeader(t.home.stepsTitle),
        ],
        AppListCard(
          children: [
            for (final (index, (title, body)) in steps.indexed)
              _StepRow(number: index + 1, title: title, body: body, state: _stepState(index, current)),
          ],
        ),
        const SizedBox(height: AppSpacing.space6),
        if (hasNoWallets)
          AppButton(expand: true, icon: IconKey.add, label: t.home.createWalletAction, onPressed: onAddWallet)
        else ...[
          AppButton(expand: true, icon: IconKey.add, label: t.home.recordAction, onPressed: onRecord),
          // Anggaran butuh dompet; tanpa dompet tautan ini buntu (UX-7).
          const SizedBox(height: AppSpacing.space1),
          AppButton.text(expand: true, label: t.home.budgetLink, onPressed: onBudget),
        ],
      ],
    );
  }

  static _StepState _stepState(int index, int current) => index < current
      ? _StepState.done
      : index == current
      ? _StepState.current
      : _StepState.later;
}

enum _StepState { done, current, later }

/// Satu langkah: tile bernomor (`brand` untuk yang berjalan, centang hijau
/// untuk yang selesai, `slate` untuk yang belum), judul, dan keterangan.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.title, required this.body, required this.state});

  final int number;
  final String title;
  final String body;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (background, ink) = switch (state) {
      _StepState.current => (colors.brand, colors.onBrand),
      _StepState.done => colors.tile(TileTint.green),
      _StepState.later => colors.tile(TileTint.slate),
    };
    final tile = Container(
      width: AppSize.tile,
      height: AppSize.tile,
      alignment: Alignment.center,
      decoration: ShapeDecoration(color: background, shape: const PixelCornerBorder.small()),
      child: state == _StepState.done
          ? AppIcon(IconKey.check, color: ink)
          : Text('$number', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: ink)),
    );
    return Semantics(
      label: state == _StepState.done ? '$number. $title, ${t.home.stepDone}' : '$number. $title',
      excludeSemantics: true,
      child: AppListRow(
        leading: tile,
        title: title,
        subtitle: body,
        wrapTitle: true,
        wrapSubtitle: true,
      ),
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
