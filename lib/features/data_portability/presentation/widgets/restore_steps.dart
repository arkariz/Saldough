import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Label langkah pemulihan: empat dari Akun, tiga dari onboarding (belum ada
/// data, jadi tanpa cadangan pengaman), mengikuti `Pulihkan.dc.html`.
List<String> restoreStepLabels({required bool onboarding}) {
  final steps = t.dataPortability.restoreSteps;
  return onboarding ? steps.sublist(1) : steps;
}

/// Daftar langkah proses pemulihan: selesai bercentang clay, yang berjalan
/// berputar, sisanya menunggu. [current] berbasis 1 pada [labels].
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
    final ds = context.ds;
    final c = ds.colors;
    return Semantics(
      liveRegion: true,
      child: DsCard(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          children: [
            for (final (i, label) in labels.indexed)
              Builder(
                builder: (context) {
                  final n = i + 1;
                  final done = n < current;
                  final active = n == current;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Row(
                      children: [
                        SizedBox.square(
                          dimension: 24,
                          child: Center(
                            child: active
                                ? AppSpin(child: Icon(Icons.autorenew, size: 22, color: c.actionPrimary))
                                : done
                                ? SvgPicture.asset(ClayIcons.done, width: 24, height: 24)
                                : Icon(Icons.radio_button_unchecked, size: 20, color: c.textMuted),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: ds.typography.bodyMd.copyWith(
                              color: active || done ? c.textPrimary : c.textSecondary,
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
