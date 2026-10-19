import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Pengungkapan sebelum membuka setelan akses notifikasi sistem (ADR-032
/// §3.8). `true` bila pengguna melanjutkan.
Future<bool> showAccessDisclosure(BuildContext context) async {
  final texts = t.notificationCapture;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(texts.disclosureTitle),
      content: SingleChildScrollView(child: Text(texts.disclosureBody)),
      actions: [
        AppButton.text(small: true, label: t.common.cancel, onPressed: () => Navigator.of(dialogContext).pop(false)),
        AppButton.text(
          small: true,
          label: texts.disclosureAccept,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return accepted ?? false;
}
