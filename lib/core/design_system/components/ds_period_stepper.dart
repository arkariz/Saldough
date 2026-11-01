import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_button.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Pemilih periode berbentuk pil (acuan Riwayat): panah mundur, nama periode
/// dengan ikon kalender di tengah, panah maju. Panah `null` dinonaktifkan.
/// [tag] (mis. "Peralihan 31 hari") tampil di bawah nama periode.
///
/// Kunci `period-previous`, `period-title`, dan `period-next` dipakai uji.
class DsPeriodStepper extends StatelessWidget {
  /// Membuat pemilih periode.
  const DsPeriodStepper({
    required this.title,
    required this.previousLabel,
    required this.nextLabel,
    required this.onPrevious,
    required this.onNext,
    this.tag,
    super.key,
  });

  /// Nama periode ("Mei 2024" atau "25 Okt – 24 Nov").
  final String title;

  /// Label pembaca layar panah mundur.
  final String previousLabel;

  /// Label pembaca layar panah maju.
  final String nextLabel;

  /// Mundur satu periode; `null` bila tidak ada yang lebih lama.
  final VoidCallback? onPrevious;

  /// Maju satu periode; `null` di periode berjalan.
  final VoidCallback? onNext;

  /// Keterangan kecil di bawah nama periode.
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DecoratedBox(
      decoration: ds.elevation.card.decoration().copyWith(
        borderRadius: DsRadius.fullAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          children: [
            DsIconButton(
              key: const ValueKey('period-previous'),
              icon: Icons.chevron_left,
              label: previousLabel,
              onPressed: onPrevious,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 16,
                        color: c.actionPrimary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          title,
                          key: const ValueKey('period-title'),
                          textAlign: TextAlign.center,
                          style: ds.typography.titleMd.copyWith(
                            fontSize: 15,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (tag != null)
                    Text(
                      tag!,
                      key: const ValueKey('period-transition-tag'),
                      textAlign: TextAlign.center,
                      style: ds.typography.bodySm.copyWith(
                        fontSize: 11,
                        color: c.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            DsIconButton(
              key: const ValueKey('period-next'),
              icon: Icons.chevron_right,
              label: nextLabel,
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}
