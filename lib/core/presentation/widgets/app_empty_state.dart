import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_button.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';

/// Ilustrasi tanuki untuk keadaan kosong (design system EmptyState,
/// "Ilustrasi per layar").
enum EmptyArt {
  /// Riwayat.
  history('assets/illustration/onboarding_1.png'),

  /// Dompet.
  wallets('assets/illustration/onboarding_2.png'),

  /// Orientasi kategori.
  categories('assets/illustration/onboarding_3.png'),

  /// Anggaran dan Rencana.
  budget('assets/illustration/onboarding_4.png'),

  /// Beranda pertama kali.
  home('assets/illustration/onboarding_5.png'),

  /// Freelance.
  freelance('assets/illustration/mascot_head.png');

  const EmptyArt(this.asset);

  /// Berkas ilustrasi.
  final String asset;
}

/// Keadaan kosong (design system EmptyState): ilustrasi, judul yang menyebut
/// apa yang belum ada, satu kalimat manfaat, dan satu tindakan `primary`.
///
/// Tanpa [art] dipakai untuk kosong karena penyaring: judul "Tidak ada yang
/// cocok" dan tindakan berupa tombol teks ([textAction]).
class AppEmptyState extends StatelessWidget {
  /// Membuat [AppEmptyState].
  const AppEmptyState({
    required this.title,
    this.body,
    this.art,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.textAction = false,
    super.key,
  });

  /// Ilustrasi; `null` untuk kosong karena penyaring.
  final EmptyArt? art;

  /// Judul.
  final String title;

  /// Satu kalimat manfaat.
  final String? body;

  /// Label tindakan.
  final String? actionLabel;

  /// Tindakan; `null` menyembunyikan tombol.
  final VoidCallback? onAction;

  /// Ikon di tombol tindakan.
  final IconKey? actionIcon;

  /// Tindakan sebagai tombol teks (kosong karena penyaring).
  final bool textAction;

  /// Lebar ilustrasi (`tk-empty__art`).
  static const artWidth = 144.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final art = this.art;
    final label = actionLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (art != null) ...[
            ExcludeSemantics(
              child: Image.asset(art.asset, width: artWidth, filterQuality: FilterQuality.none),
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
          Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
          if (body case final body?) ...[
            const SizedBox(height: AppSpacing.space2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
              ),
            ),
          ],
          if (label != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.space4),
            if (textAction)
              AppButton.text(label: label, onPressed: onAction)
            else
              AppButton(label: label, icon: actionIcon, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// Keadaan galat pembacaan: ikon peringatan, judul, keterangan, dan
/// "Coba lagi". Dibedakan dari [AppEmptyState] supaya layar tidak
/// menampilkan "belum ada" yang menyesatkan saat pembacaan gagal.
class AppErrorState extends StatelessWidget {
  /// Membuat [AppErrorState].
  const AppErrorState({
    required this.title,
    required this.retryLabel,
    required this.onRetry,
    this.body,
    super.key,
  });

  /// Judul.
  final String title;

  /// Keterangan.
  final String? body;

  /// Label tombol coba lagi.
  final String retryLabel;

  /// Dipanggil saat coba lagi.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: ShapeDecoration(color: colors.dangerSoft, shape: const PixelCornerBorder()),
              child: AppIcon(IconKey.warning, color: colors.danger),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(title, textAlign: TextAlign.center, style: textTheme.titleMedium),
            if (body case final body?) ...[
              const SizedBox(height: AppSpacing.space1),
              Text(
                body,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
              ),
            ],
            const SizedBox(height: AppSpacing.space4),
            AppButton.secondary(label: retryLabel, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
