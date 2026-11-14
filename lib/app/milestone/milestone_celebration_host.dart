import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/app/milestone/milestone_coordinator.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/app_action_snack_bar.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';
import 'package:saldough/features/milestone/domain/services/celebration_policy.dart';
import 'package:saldough/features/milestone/presentation/widgets/legacy_banner_slide.dart';
import 'package:saldough/features/milestone/presentation/widgets/stamp_celebration.dart';

/// Tuan rumah perayaan stempel di Beranda (T-28.4, GAMIFICATION G-4, G-6, G-8).
///
/// Menggambar nol widget; menampilkan snackbar atau lembar pengenalan sesuai
/// rencana dari koordinator, dan melapor satu slide banner pengguna lama ke
/// [board]. Perayaan hanya tampil bila [active] (Beranda tab aktif), tidak ada
/// layar atau lembar lain di atasnya, tur tidak berjalan, dan tidak ada banner
/// pembaruan atau catatan "Apa yang baru" yang menunggu. Bila terhalang,
/// perayaan **tidak menunggu**; hanya titik di Akun yang tersisa.
class MilestoneCelebrationHost extends StatefulWidget {
  /// Membuat [MilestoneCelebrationHost].
  const MilestoneCelebrationHost({
    required this.container,
    required this.active,
    required this.board,
    required this.onOpenBook,
    required this.onOpenSettings,
    super.key,
  });

  /// Container akar tempat koordinator terdaftar.
  final GetIt container;

  /// Beranda adalah tab aktif.
  final bool active;

  /// Papan status Beranda tujuan slide banner.
  final DsStatusBoard board;

  /// Membuka Buku Stempel (sementara layar Akun sampai T-28.5).
  final VoidCallback onOpenBook;

  /// Membuka pengaturan Perayaan stempel di Akun.
  final VoidCallback onOpenSettings;

  @override
  State<MilestoneCelebrationHost> createState() => _MilestoneCelebrationHostState();
}

class _MilestoneCelebrationHostState extends State<MilestoneCelebrationHost> {
  MilestoneCoordinator? _coordinator;
  StreamSubscription<CelebrationPlan>? _plans;
  SpotlightController? _tour;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    if (!widget.container.isRegistered<MilestoneCoordinator>()) return;
    final coordinator = _coordinator = widget.container<MilestoneCoordinator>()..canCelebrate = _canCelebrate;
    _plans = coordinator.celebrations.listen(_show);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tour = SpotlightHost.maybeOf(context, listen: false);
  }

  bool _canCelebrate() {
    if (!mounted || !widget.active || _sheetOpen) return false;
    if (_tour?.isActive ?? false) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    if (widget.board.slides.any((s) => s.id == 'app_update')) return false;
    final container = widget.container;
    if (container.isRegistered<AppUpdateBloc>() && container<AppUpdateBloc>().state.whatsNew.isNotEmpty) return false;
    return true;
  }

  void _show(CelebrationPlan plan) {
    final coordinator = _coordinator;
    if (!mounted || coordinator == null || !_canCelebrate()) return;
    switch (plan.kind) {
      case CelebrationKind.snackbar:
        ScaffoldMessenger.of(context).showAppSnackBar(
          stampSnackBar(context, ids: plan.ids, onSee: widget.onOpenBook),
        );
      case CelebrationKind.firstSheet:
        _sheetOpen = true;
        unawaited(
          showFirstStampSheet(context, id: plan.ids.first, onSettings: widget.onOpenSettings).whenComplete(() {
            _sheetOpen = false;
            unawaited(coordinator.markIntroShown());
          }),
        );
      case CelebrationKind.legacyBanner || CelebrationKind.none:
        break;
    }
  }

  @override
  void dispose() {
    final coordinator = _coordinator;
    if (coordinator != null) coordinator.canCelebrate = () => false;
    unawaited(_plans?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = _coordinator;
    if (coordinator == null) return const SizedBox.shrink();
    return ValueListenableBuilder<MilestoneLedger>(
      valueListenable: coordinator.ledger,
      builder: (context, ledger, _) => DsStatusReport(
        board: widget.board,
        id: legacyBannerStatusId,
        data: legacyBannerVisible(ledger)
            ? legacyBannerSlide(
                onSee: () {
                  unawaited(coordinator.markIntroShown());
                  widget.onOpenBook();
                },
                onDismiss: () => unawaited(coordinator.markIntroShown()),
              )
            : null,
      ),
    );
  }
}
