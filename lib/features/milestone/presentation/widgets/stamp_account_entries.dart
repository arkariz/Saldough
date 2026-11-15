import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';
import 'package:saldough/features/milestone/domain/services/celebration_policy.dart';
import 'package:saldough/features/milestone/presentation/navigation/milestone_route_keys.dart';
import 'package:saldough/features/milestone/presentation/stamp_book_access.dart';

/// Baris Akun untuk stempel (rupa buku-stempel §4.6): **Buku Stempel** dan
/// sakelar **Perayaan stempel**, di grup Aplikasi. Sakelar mati menutup baris
/// Buku Stempel (G-8); menyalakan lagi membukanya tanpa merayakan ulang.
/// Judul dan keterangan tanpa hitungan (KT-G1).
List<Widget> stampAccountEntries(MilestoneBookAccess access) => [
  _BookEntry(access: access),
  _SwitchEntry(access: access),
];

class _BookEntry extends StatelessWidget {
  const _BookEntry({required this.access});

  final MilestoneBookAccess access;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MilestoneLedger>(
      valueListenable: access.ledger,
      builder: (context, ledger, _) {
        final row = ledger.celebrationEnabled ? _row(context, ledger) : const SizedBox(width: double.infinity);
        // `AnimatedSize` berdurasi nol melanggar pernyataan layout Flutter, jadi
        // gerak dikurangi memakai baris biasa.
        if (DsMotion.reduced(context)) return row;
        return AnimatedSize(duration: const Duration(milliseconds: 350), alignment: Alignment.topCenter, child: row);
      },
    );
  }

  Widget _row(BuildContext context, MilestoneLedger ledger) {
    final texts = t.stamps.account;
    return DsSettingRow(
      title: texts.entryTitle,
      subtitle: texts.entrySubtitle,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.verified_outlined),
          if (hasUnseenStamps(ledger))
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: context.ds.colors.actionPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.ds.colors.surfaceCard, width: 2),
                ),
              ),
            ),
        ],
      ),
      onTap: () => context.pushRoute(MilestoneRouteKeys.book, const StampBookInput()),
    );
  }
}

class _SwitchEntry extends StatelessWidget {
  const _SwitchEntry({required this.access});

  final MilestoneBookAccess access;

  @override
  Widget build(BuildContext context) {
    final texts = t.stamps.account;
    return ValueListenableBuilder<MilestoneLedger>(
      valueListenable: access.ledger,
      builder: (context, ledger, _) => DsSwitchRow(
        title: texts.switchTitle,
        subtitle: ledger.celebrationEnabled ? texts.switchHintOn : texts.switchHintOff,
        value: ledger.celebrationEnabled,
        onChanged: (enabled) {
          AppAnalytics.log(MilestoneEvents.settingChanged(enabled: enabled));
          unawaited(access.setCelebrationEnabled(enabled: enabled));
        },
      ),
    );
  }
}
