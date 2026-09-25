import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:state_management/state_management.dart';

/// Mendaftarkan penangan [ShowDialogEffect].
///
/// Tiap [DialogActionConfig] sudah membawa `onPressed`-nya sendiri (diisi
/// bloc saat membuat efek) — handler ini hanya menjalankannya lalu menutup
/// dialog, tidak perlu memetakan `intentId` secara terpisah.
void registerDialogEffectHandler(EffectRegistry registry) {
  registry.register<ShowDialogEffect>((context, effect) {
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: effect.isDismissible,
      builder: (dialogContext) => AlertDialog(
        title: Text(effect.title),
        content: Text(effect.message),
        actions: effect.actions
            .map(
              (action) => TextButton(
                onPressed: () {
                  action.onPressed?.call();
                  Navigator.of(dialogContext).pop();
                },
                style: action.action == DialogAction.destructive
                    ? TextButton.styleFrom(foregroundColor: dialogContext.appColors.expense)
                    : null,
                child: Text(action.effectiveLabel),
              ),
            )
            .toList(growable: false),
      ),
    ));
  });
}
