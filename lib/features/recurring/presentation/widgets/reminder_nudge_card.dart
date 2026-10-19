import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/recurring/presentation/widgets/reminder_status_builder.dart';

/// Kartu tombol permanen **pengingat rutin** (komponen FeatureNudge,
/// FEATURE_DISCOVERY P-1): "Nyalakan pengingat rutin" saat sakelar mati, atau
/// "Pengingat rutin / Izin belum diberikan" dengan **Izinkan** saat izin
/// hilang. Tanpa tutup, tunda, atau "Nanti"; hilang begitu efektif. Tanpa
/// warna peringatan, juga untuk Izinkan. Disisipkan akar komposisi ke
/// Beranda dan dipakai segmen Rutin.
class ReminderNudgeCard extends StatelessWidget {
  /// Membuat [ReminderNudgeCard].
  const ReminderNudgeCard({required this.container, this.bottomGap = false, this.spotlight = false, super.key});

  /// Kontainer akar.
  final GetIt container;

  /// Jarak bawah, bila kartu di dalam daftar.
  final bool bottomGap;

  /// Kartu ini target tur Beranda (T-21.6): disorot sekali saat pertama
  /// tampil. Hanya satu pemakaian yang boleh membawa kunci spotlight.
  final bool spotlight;

  @override
  Widget build(BuildContext context) => ReminderStatusBuilder(
    container: container,
    builder: (context, state, enable) {
      final texts = t.discovery;
      final needsPermission = state == FeatureState.permissionNeeded;
      final textTheme = Theme.of(context).textTheme;
      final colors = context.appColors;
      final card = AppCard(
        key: const ValueKey('reminder-nudge'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space3),
        child: Row(
          children: [
            AppIconTile(IconKey.schedule, background: colors.brandSoft),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    needsPermission ? t.recurring.remindersTitle : texts.reminder.button,
                    style: textTheme.titleSmall,
                  ),
                  Text(
                    needsPermission ? texts.status.permissionNeeded : texts.reminder.body,
                    style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            AppButton.secondary(
              key: const ValueKey('reminder-nudge-action'),
              small: true,
              label: needsPermission ? texts.allowAccess : texts.turnOn,
              onPressed: () => unawaited(enable()),
            ),
          ],
        ),
      );
      final padded = Padding(
        padding: EdgeInsets.only(top: bottomGap ? 0 : AppSpacing.space6, bottom: bottomGap ? AppSpacing.space4 : 0),
        child: spotlight ? SpotlightTarget(spotlightKey: SpotlightKey.homeReminder, child: card) : card,
      );
      return spotlight ? TourTrigger(tour: TourId.home, ready: true, child: padded) : padded;
    },
  );
}

/// Catatan di bawah sakelar "Ingatkan" per rutin (FEATURE_DISCOVERY §5):
/// sakelar tampil menyala, tetapi pengingat global belum efektif, jadi satu
/// kalimat dan tombol **Nyalakan** / **Izinkan** menjelaskannya.
class ReminderRuleNote extends StatelessWidget {
  /// Membuat [ReminderRuleNote].
  const ReminderRuleNote({required this.container, super.key});

  /// Kontainer akar.
  final GetIt container;

  @override
  Widget build(BuildContext context) => ReminderStatusBuilder(
    container: container,
    builder: (context, state, enable) {
      final texts = t.discovery;
      return Padding(
        key: const ValueKey('reminder-rule-note'),
        padding: const EdgeInsets.fromLTRB(AppSpacing.space4, 0, AppSpacing.space4, AppSpacing.space3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                texts.reminder.rowNote,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appColors.ink2),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            AppButton.secondary(
              key: const ValueKey('reminder-rule-note-action'),
              small: true,
              label: state == FeatureState.permissionNeeded ? texts.allowAccess : texts.turnOn,
              onPressed: () => unawaited(enable()),
            ),
          ],
        ),
      );
    },
  );
}
