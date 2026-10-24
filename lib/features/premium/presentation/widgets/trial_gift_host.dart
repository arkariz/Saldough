import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/features/premium/domain/trial_gift.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';

/// Pemicu layar hadiah uji coba (D-1): tidak menggambar apa pun, hanya membuka
/// [PremiumRouteKeys.trialGift] sekali begitu uji coba aktif dan hadiahnya
/// belum pernah ditampilkan. Menunggu bila ada layar atau lembar lain di
/// atasnya, lalu mencoba lagi begitu paket atau layar berubah.
class TrialGiftHost extends StatefulWidget {
  /// Membuat [TrialGiftHost]; [active] true bila Beranda tab yang tampil.
  const TrialGiftHost({required this.container, required this.active, super.key});

  /// Container akar tempat [TrialGift] terdaftar.
  final GetIt container;

  /// Beranda adalah tab aktif.
  final bool active;

  @override
  State<TrialGiftHost> createState() => _TrialGiftHostState();
}

class _TrialGiftHostState extends State<TrialGiftHost> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    ActivePlan.notifier.addListener(_maybeShow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  @override
  void didUpdateWidget(TrialGiftHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  @override
  void dispose() {
    ActivePlan.notifier.removeListener(_maybeShow);
    super.dispose();
  }

  Future<void> _maybeShow() async {
    if (!mounted || _checking || !widget.active) return;
    if (ActivePlan.state is! TrialPlan || !widget.container.isRegistered<TrialGift>()) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _checking = true;
    try {
      final info = await widget.container<TrialGift>().pending();
      if (!mounted || info == null || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
      await context.pushRoute(PremiumRouteKeys.trialGift, TrialGiftInput(info));
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
