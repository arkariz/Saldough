import 'dart:async';
import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
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
  const ReminderNudgeCard({
    required this.container,
    this.bottomGap = false,
    this.spotlight = false,
    this.board,
    super.key,
  });

  /// Kontainer akar.
  final GetIt container;

  /// Jarak bawah, bila kartu di dalam daftar.
  final bool bottomGap;

  /// Kartu ini target tur Beranda (T-21.6): disorot sekali saat pertama
  /// tampil. Hanya satu pemakaian yang boleh membawa kunci spotlight.
  final bool spotlight;

  /// Papan status Beranda (mode ringkas, ADR-043): tanpa menggambar kartu,
  /// hanya melapor satu slide yang hilang begitu pengingat menyala.
  final DsStatusBoard? board;

  static const _statusId = 'reminder';

  @override
  Widget build(BuildContext context) => ReminderStatusBuilder(
    container: container,
    surface: bottomGap ? 'rutin_segment' : 'home',
    hiddenBuilder: board == null ? null : (_) => DsStatusReport(board: board!, id: _statusId, data: null),
    builder: (context, state, enable) {
      final texts = t.discovery;
      final needsPermission = state == FeatureState.permissionNeeded;
      if (board != null) {
        return DsStatusReport(
          board: board!,
          id: _statusId,
          data: DsStatusSlideData(
            id: _statusId,
            icon: Icons.schedule,
            asset: ClayIcons.alarm,
            title: needsPermission ? t.recurring.remindersTitle : texts.reminder.button,
            subtitle: needsPermission ? texts.status.permissionNeeded : texts.reminder.body,
            actionLabel: needsPermission ? texts.allowAccess : texts.turnOn,
            onAction: () => unawaited(enable()),
            order: 2,
          ),
        );
      }
      final ds = context.ds;
      final card = DsReveal(
        child: DsCard(
          key: const ValueKey('reminder-nudge'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              DsIdleMotion(
                kind: DsIdleKind.float,
                child: DsIconTile.asset(asset: ClayIcons.alarm, tone: DsIconTileTone.info, size: DsIconTileSize.sm),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      needsPermission ? t.recurring.remindersTitle : texts.reminder.button,
                      style: ds.typography.titleMd,
                    ),
                    Text(
                      needsPermission ? texts.status.permissionNeeded : texts.reminder.body,
                      style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 112,
                child: DsInlineAction(
                  key: const ValueKey('reminder-nudge-action'),
                  tone: DsInlineActionTone.primary,
                  label: needsPermission ? texts.allowAccess : texts.turnOn,
                  onPressed: () => unawaited(enable()),
                ),
              ),
            ],
          ),
        ),
      );
      final padded = Padding(
        padding: EdgeInsets.only(top: bottomGap ? 0 : 24, bottom: bottomGap ? 16 : 0),
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
    surface: 'rutin_detail',
    builder: (context, state, enable) {
      final texts = t.discovery;
      final ds = context.ds;
      return Padding(
        key: const ValueKey('reminder-rule-note'),
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(texts.reminder.rowNote, style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary)),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 112,
              child: DsInlineAction(
                key: const ValueKey('reminder-rule-note-action'),
                tone: DsInlineActionTone.primary,
                label: state == FeatureState.permissionNeeded ? texts.allowAccess : texts.turnOn,
                onPressed: () => unawaited(enable()),
              ),
            ),
          ],
        ),
      );
    },
  );
}
