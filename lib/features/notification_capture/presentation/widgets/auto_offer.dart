import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/app_action_snack_bar.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/plus_gate.dart';

/// Tawaran "Catat otomatis dari {aplikasi}?" (ADR-044 §3.7, E3) sebagai
/// snackbar. Isinya hanya nama aplikasi dan akibatnya, bukan teks
/// notifikasinya: teks asli bercampur dengan pesan sistem dan sulit dibedakan.
/// **Ya, otomatis**: Plus menjalankan [approve] (menyetujui bentuknya, dengan
/// Batalkan), Gratis membuka pratinjau Plus. Mengembalikan pengendali snackbar
/// tawarannya.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAutoOffer(
  BuildContext context, {
  required String appLabel,
  required Future<Future<void> Function()?> Function() approve,
}) {
  final texts = t.notificationCapture;
  return ScaffoldMessenger.of(context).showSnackBar(
    actionSnackBar(
      context,
      tone: DsSnackTone.info,
      content: DsSnackMessage(
        title: texts.autoOfferTitle(app: appLabel),
        message: texts.autoOfferBody,
      ),
      action: SnackBarAction(
        label: texts.autoOfferYes,
        onPressed: () => unawaited(_onYes(context, appLabel, approve)),
      ),
    ),
  );
}

Future<void> _onYes(BuildContext context, String appLabel, Future<Future<void> Function()?> Function() approve) async {
  if (!ActivePlan.isPlus) {
    await openNotificationPaywall(context);
    return;
  }
  final undo = await approve();
  if (undo == null || !context.mounted) return;
  final texts = t.notificationCapture;
  ScaffoldMessenger.of(context).showSnackBar(
    actionSnackBar(
      context,
      content: DsSnackMessage(
        title: texts.autoApprovedTitle(app: appLabel),
        message: texts.autoApprovedBody,
      ),
      action: SnackBarAction(label: texts.rememberedUndo, onPressed: () => unawaited(undo())),
    ),
  );
}
