import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Label langkah pemulihan: empat dari Akun, tiga dari onboarding (belum ada
/// data, jadi tanpa cadangan pengaman), mengikuti `Pulihkan.dc.html`.
List<String> restoreStepLabels({required bool onboarding}) {
  final steps = t.dataPortability.restoreSteps;
  return onboarding ? steps.sublist(1) : steps;
}

/// Daftar langkah proses pemulihan (`tk-steps`): selesai bercentang, yang
/// berjalan berputar, sisanya menunggu. [current] berbasis 1 pada [labels].
class RestoreSteps extends StatelessWidget {
  /// Membuat [RestoreSteps].
  const RestoreSteps({required this.labels, required this.current, super.key});

  /// Teks tiap langkah.
  final List<String> labels;

  /// Langkah yang sedang berjalan (1..labels.length); yang lebih kecil sudah
  /// selesai.
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
        child: Column(
          children: [
            for (final (i, label) in labels.indexed)
              Builder(
                builder: (context) {
                  final n = i + 1;
                  final done = n < current;
                  final active = n == current;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2, horizontal: AppSpacing.space2),
                    child: Row(
                      children: [
                        if (active)
                          AppSpin(child: AppIcon(IconKey.progressActivity, color: colors.brand))
                        else
                          AppIcon(
                            done ? IconKey.checkCircle : IconKey.stepWaiting,
                            color: done ? colors.positive : colors.ink3,
                          ),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: Text(
                            label,
                            style: textTheme.bodyMedium?.copyWith(
                              color: active || done ? colors.ink : colors.ink2,
                              fontWeight: active ? FontWeight.w700 : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
