import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/app_action_snack_bar.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/plus_gate.dart';

/// Templat bentuk dalam bahasa pengguna: penanda diganti kata biasa.
String shapePreview(String template) {
  final texts = t.notificationCapture;
  return template
      .replaceAll('{amount}', texts.shapeTokenAmount)
      .replaceAll('{note}', texts.shapeTokenNote)
      .replaceAll('{*}', texts.shapeTokenAny);
}

/// Tawaran "Catat otomatis yang seperti ini?" (ADR-044 §3.7, E3) sebagai
/// snackbar. **Ya**: Plus menjalankan [approve] (menyetujui bentuknya, dengan
/// Batalkan), Gratis membuka pratinjau Plus. Mengembalikan pengendali snackbar
/// tawarannya.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAutoOffer(
  BuildContext context, {
  required String template,
  required Future<Future<void> Function()?> Function() approve,
}) {
  final texts = t.notificationCapture;
  return ScaffoldMessenger.of(context).showSnackBar(
    actionSnackBar(
      context,
      content: Text(texts.autoOfferSnack(shape: shapePreview(template))),
      action: SnackBarAction(
        label: texts.autoOfferYes,
        onPressed: () => unawaited(_onYes(context, approve)),
      ),
    ),
  );
}

Future<void> _onYes(BuildContext context, Future<Future<void> Function()?> Function() approve) async {
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
      content: Text(texts.autoApprovedSnack),
      action: SnackBarAction(label: texts.rememberedUndo, onPressed: () => unawaited(undo())),
    ),
  );
}
