import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Pengungkapan sebelum membuka setelan akses notifikasi sistem (ADR-032
/// §3.8), sebagai lembar bawah v2: judul bertile, daftar yang dibaca dan ke
/// mana perginya (satu baris per hal, berikon), langkah sesudah Lanjut, lalu
/// Lanjut dan Batal. `true` bila pengguna melanjutkan.
Future<bool> showAccessDisclosure(BuildContext context) async {
  final accepted = await showAppSheet<bool>(
    context,
    isScrollControlled: true,
    builder: (sheetContext) => const _AccessDisclosureSheet(),
  );
  return accepted ?? false;
}

class _AccessDisclosureSheet extends StatelessWidget {
  const _AccessDisclosureSheet();

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    final c = ds.colors;
    final points = [
      (Icons.apps_rounded, texts.disclosurePointApps),
      (Icons.visibility_off_outlined, texts.disclosurePointOtp),
      (Icons.auto_awesome_outlined, texts.disclosurePointGemini),
      (Icons.schedule_rounded, texts.disclosurePointRetention),
      (Icons.bolt_rounded, texts.disclosurePointBackground),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DsIconTile.child(
                size: DsIconTileSize.md,
                child: Icon(Icons.shield_outlined, size: 22, color: c.actionPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(texts.disclosureTitle, style: ds.typography.headlineSm)),
            ],
          ),
          const SizedBox(height: 12),
          Text(texts.disclosureIntro, style: ds.typography.bodyMd.copyWith(color: c.textSecondary)),
          const SizedBox(height: 14),
          DsCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                for (final (i, point) in points.indexed) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DsIconTile.child(
                        size: DsIconTileSize.xs,
                        child: Icon(point.$1, size: 14, color: c.actionPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(point.$2, style: ds.typography.bodyMd)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.baseAll),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: c.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(texts.disclosureNext, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DsButton(
            key: const ValueKey('access-disclosure-accept'),
            label: texts.disclosureAccept,
            expand: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 4),
          DsButton.ghost(label: t.common.cancel, expand: true, onPressed: () => Navigator.of(context).pop(false)),
        ],
      ),
    );
  }
}
