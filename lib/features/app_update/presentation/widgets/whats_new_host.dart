import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/widgets/whats_new_sheet.dart';

/// Pemicu lembar "Apa yang baru" di Beranda (APP_UPDATE F3, B-10): tidak
/// menggambar apa pun, hanya membuka [WhatsNewSheet] sekali bila ada catatan
/// yang menunggu. Menunggu bila Beranda bukan tab aktif, ada layar atau
/// lembar lain di atasnya (mis. Catat), atau tur spotlight sedang tampil,
/// lalu mencoba lagi begitu keadaannya berubah.
///
/// Menutup lembar dengan cara apa pun (Oke, scrim, geser) = sudah dilihat.
class WhatsNewHost extends StatefulWidget {
  /// Membuat [WhatsNewHost]; [active] true bila Beranda tab yang tampil.
  const WhatsNewHost({required this.container, required this.active, super.key});

  /// Container akar tempat bloc pembaruan terdaftar.
  final GetIt container;

  /// Beranda adalah tab aktif.
  final bool active;

  @override
  State<WhatsNewHost> createState() => _WhatsNewHostState();
}

class _WhatsNewHostState extends State<WhatsNewHost> {
  AppUpdateBloc? _bloc;
  StreamSubscription<Object?>? _states;
  SpotlightController? _tour;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    if (!widget.container.isRegistered<AppUpdateBloc>()) return;
    _bloc = widget.container<AppUpdateBloc>();
    _states = _bloc!.stream.listen((_) => _maybeShow());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tour = SpotlightHost.maybeOf(context, listen: false);
    if (tour == _tour) return;
    _tour?.removeListener(_maybeShow);
    _tour = tour?..addListener(_maybeShow);
  }

  @override
  void didUpdateWidget(WhatsNewHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  void _maybeShow() {
    final bloc = _bloc;
    if (!mounted || bloc == null || _showing || !widget.active) return;
    final notes = bloc.state.whatsNew;
    if (notes.isEmpty) return;
    if (_tour?.isActive ?? false) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _showing = true;
    bloc.add(const AppUpdateWhatsNewOpened(UpdateActionSource.home));
    unawaited(
      showAppSheet<void>(
        context,
        isScrollControlled: true,
        builder: (context) => WhatsNewSheet(notes: notes, onClose: () => Navigator.of(context).pop()),
      ).whenComplete(() {
        _showing = false;
        bloc.add(const AppUpdateWhatsNewSeen());
      }),
    );
  }

  @override
  void dispose() {
    _tour?.removeListener(_maybeShow);
    unawaited(_states?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
