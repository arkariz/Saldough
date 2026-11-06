import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/capture_inbox_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/plus_gate.dart';

/// Tawaran "Catat otomatis dari {aplikasi}?" (ADR-044 §3.7, E3) sebagai banner
/// di atas daftar kotak masuk. Banner, bukan snackbar: ini **keputusan**, jadi
/// tidak boleh hilang sendiri atau mengantre di belakang pesan lain. Isinya
/// hanya nama aplikasi dan akibatnya, bukan teks notifikasinya.
class AutoOfferBanner extends StatelessWidget {
  /// Membuat [AutoOfferBanner].
  const AutoOfferBanner({required this.prompt, required this.onYes, required this.onLater, super.key});

  /// Tawarannya.
  final AutoOfferPrompt prompt;

  /// **Ya, otomatis**.
  final VoidCallback onYes;

  /// **Nanti**: menutup tawaran.
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DsCard(
        key: const ValueKey('inbox-auto-offer'),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DsIconTile.asset(asset: ClayIcons.bolt, tone: DsIconTileTone.income, size: DsIconTileSize.sm),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(texts.autoOfferTitle(app: prompt.appLabel), style: ds.typography.titleMd),
                  const SizedBox(height: 4),
                  Text(texts.autoOfferBody, style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary)),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      DsInlineAction(
                        key: const ValueKey('inbox-auto-offer-later'),
                        dense: true,
                        label: texts.autoOfferLater,
                        onPressed: onLater,
                      ),
                      DsInlineAction(
                        key: const ValueKey('inbox-auto-offer-yes'),
                        dense: true,
                        tone: DsInlineActionTone.primary,
                        label: texts.autoOfferYes,
                        onPressed: onYes,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// **Ya, otomatis**: Plus menyetujui bentuknya lalu memberi tahu dengan satu
/// snackbar ber-Batalkan; Gratis membuka pratinjau Plus (tawaran tetap ada).
Future<void> answerAutoOfferYes(BuildContext context, CaptureInboxBloc bloc, AutoOfferPrompt prompt) async {
  if (!ActivePlan.isPlus) {
    await openNotificationPaywall(context);
    return;
  }
  final undo = await bloc.approveOffer(prompt);
  if (undo == null || !context.mounted) return;
  final texts = t.notificationCapture;
  ScaffoldMessenger.of(context).showAppSnackBar(
    actionSnackBar(
      context,
      content: DsSnackMessage(
        title: texts.autoApprovedTitle(app: prompt.appLabel),
        message: texts.autoApprovedBody,
      ),
      action: SnackBarAction(label: texts.rememberedUndo, onPressed: () => unawaited(undo())),
    ),
  );
}
