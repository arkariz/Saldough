import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Baris sakelar: label, keterangan opsional, dan [Switch]. Dipakai di dalam
/// kartu kelompok setelan; [indent] menggeser baris turunan ke kanan.
class NotificationSwitchRow extends StatelessWidget {
  /// Membuat [NotificationSwitchRow].
  const NotificationSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.indent = false,
    super.key,
  });

  /// Label.
  final String label;

  /// Keterangan singkat di bawah label.
  final String? hint;

  /// Nilai.
  final bool value;

  /// Diubah.
  final ValueChanged<bool> onChanged;

  /// Baris turunan dari baris di atasnya.
  final bool indent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(left: indent ? AppSpacing.lg : 0, top: AppSpacing.xs, bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.titleSmall),
                if (hint != null) Text(hint!, style: textTheme.bodySmall?.copyWith(color: context.appColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// [NotificationSwitchRow] tunggal dalam kartu.
class NotificationSwitchCard extends StatelessWidget {
  /// Membuat [NotificationSwitchCard].
  const NotificationSwitchCard({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.footer,
    super.key,
  });

  /// Label.
  final String label;

  /// Keterangan singkat.
  final String? hint;

  /// Nilai.
  final bool value;

  /// Diubah.
  final ValueChanged<bool> onChanged;

  /// Isi tambahan di bawah baris, mis. status izin.
  final Widget? footer;

  @override
  Widget build(BuildContext context) => AppHardCard(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NotificationSwitchRow(label: label, hint: hint, value: value, onChanged: onChanged),
        ?footer,
      ],
    ),
  );
}

/// Kartu yang membuka layar lain: judul, keterangan, dan panah.
class NotificationNavCard extends StatelessWidget {
  /// Membuat [NotificationNavCard].
  const NotificationNavCard({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.subtitleColor,
    this.titleColor,
    super.key,
  });

  /// Judul.
  final String title;

  /// Keterangan di bawah judul.
  final String? subtitle;

  /// Warna keterangan (peringatan); bawaan redup.
  final Color? subtitleColor;

  /// Warna judul (mis. redup saat dijeda).
  final Color? titleColor;

  /// Diketuk.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppTappable(
        label: title,
        onTap: onTap,
        child: AppHardCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall?.copyWith(color: titleColor)),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall?.copyWith(color: subtitleColor ?? context.appColors.textMuted),
                      ),
                  ],
                ),
              ),
              const AppIcon(IconKey.chevronRight),
            ],
          ),
        ),
      ),
    );
  }
}
