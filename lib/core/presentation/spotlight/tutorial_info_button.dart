import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saldough/core/foundation/navigation/app_route_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight_host.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';

enum _InfoAction { replayTour, showIntro, resetAll }

/// Ikon info kecil di kepala kartu utama tiap tab (KO-4, ADR-021 §3.5).
/// Membuka menu: putar ulang tur layar ini, lihat lagi pengenalan, dan
/// setel ulang semua tutorial (dengan konfirmasi).
///
/// Tanpa `SpotlightHost` di atasnya (uji lama), tombol ini tidak tampil.
class TutorialInfoButton extends StatelessWidget {
  /// Membuat [TutorialInfoButton] untuk [tour] layar ini.
  const TutorialInfoButton({required this.tour, super.key});

  /// Tur yang diputar ulang lewat "Tur layar ini".
  final TourId tour;

  Future<void> _onSelected(BuildContext context, _InfoAction action) async {
    final controller = SpotlightHost.maybeOf(context, listen: false);
    if (controller == null) return;
    switch (action) {
      case _InfoAction.replayTour:
        await controller.maybeStart(tour, force: true, navigator: Navigator.maybeOf(context));
      case _InfoAction.showIntro:
        await GoRouter.maybeOf(context)?.push<void>(AppRouteRegistry.onboardingPath, extra: OnboardingMode.review);
      case _InfoAction.resetAll:
        final messenger = ScaffoldMessenger.maybeOf(context);
        final confirmed = await showConfirmDelete(
          context,
          title: t.info.resetConfirmTitle,
          message: t.info.resetConfirmMessage,
          confirmLabel: t.info.resetConfirmAction,
        );
        if (!confirmed) return;
        await controller.resetAll();
        messenger?.showSnackBar(SnackBar(content: Text(t.info.resetDoneMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (SpotlightHost.maybeOf(context, listen: false) == null) return const SizedBox.shrink();
    final colors = context.appColors;
    return PopupMenuButton<_InfoAction>(
      tooltip: t.info.menuTooltip,
      padding: EdgeInsets.zero,
      color: colors.surface,
      shape: const PixelCornerBorder(),
      onSelected: (action) => unawaited(_onSelected(context, action)),
      itemBuilder: (_) => [
        PopupMenuItem(value: _InfoAction.replayTour, child: Text(t.info.replayTourAction)),
        PopupMenuItem(value: _InfoAction.showIntro, child: Text(t.info.showIntroAction)),
        PopupMenuItem(value: _InfoAction.resetAll, child: Text(t.info.resetAllAction)),
      ],
      // Target sentuh 44px; ikonnya kecil supaya tidak bersaing dengan angka.
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(child: AppIcon(IconKey.info, size: 20, color: colors.ink2)),
      ),
    );
  }
}
