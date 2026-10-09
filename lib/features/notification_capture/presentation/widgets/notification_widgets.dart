import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// [AppSwitchRow] tunggal dalam kartu: seluruh baris bisa diketuk dan
/// dibacakan sebagai satu sakelar berlabel (QA PR #43 F15).
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
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSwitchRow(title: label, subtitle: hint, value: value, onChanged: onChanged),
        if (footer case final footer?)
          Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4), child: footer),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: AppTappable(
        label: title,
        onTap: onTap,
        child: AppCard(
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
                        style: textTheme.bodySmall?.copyWith(color: subtitleColor ?? context.appColors.ink2),
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
