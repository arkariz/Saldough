import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/app/period_book/period_book_gate.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/period_book/domain/services/period_book_shelf.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Id slide ajakan akhir periode di papan status Beranda.
const periodInvitationStatusId = 'period_book_invite';

/// Ajakan **Tutup buku** di Beranda (rupa D3, BP-2, BP-9, BP-13): satu slide di
/// papan status, hanya untuk Plus pada periode tepat sebelum periode berjalan
/// dengan ≥3 transaksi. "Nanti" menutupnya untuk periode itu; buku tetap
/// menunggu di Rak (BP-9).
///
/// **Satu kartu pada satu waktu (BP-13):** bila banner pembaruan atau catatan
/// "Apa yang baru" tampil, slide ini tidak dilaporkan. Ajakan Gratis (Kartu
/// Periode) belum ada: menunggu T-27.8, jadi pengguna Gratis tidak melihat
/// apa-apa di sini.
///
/// Menggambar nol widget. Memeriksa ulang saat Beranda dibuka, transaksi
/// berubah, dan papan status berubah.
class PeriodInvitationHost extends StatefulWidget {
  /// Membuat [PeriodInvitationHost].
  const PeriodInvitationHost({required this.container, required this.board, required this.onOpenRitual, super.key});

  /// Container akar tempat gerbang terdaftar.
  final GetIt container;

  /// Papan status Beranda tujuan slide.
  final DsStatusBoard board;

  /// Membuka ritual Tutup buku untuk periode [periodId].
  final void Function(String periodId) onOpenRitual;

  @override
  State<PeriodInvitationHost> createState() => _PeriodInvitationHostState();
}

class _PeriodInvitationHostState extends State<PeriodInvitationHost> {
  PeriodBookGate? _gate;
  StreamSubscription<Object?>? _ledger;
  PeriodInvitation? _invitation;

  @override
  void initState() {
    super.initState();
    if (!widget.container.isRegistered<PeriodBookGate>()) return;
    _gate = widget.container<PeriodBookGate>();
    if (widget.container.isRegistered<LedgerChanges>()) {
      _ledger = widget.container<LedgerChanges>().changes.listen((_) => unawaited(_refresh()));
    }
    widget.board.addListener(_rebuild);
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final invitation = await _gate?.invitation();
    if (!mounted) return;
    setState(() => _invitation = invitation);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  bool get _blocked {
    if (widget.board.slides.any((s) => s.id == 'app_update')) return true;
    final c = widget.container;
    return c.isRegistered<AppUpdateBloc>() && c<AppUpdateBloc>().state.whatsNew.isNotEmpty;
  }

  @override
  void dispose() {
    widget.board.removeListener(_rebuild);
    unawaited(_ledger?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invitation = _invitation;
    final show = invitation != null && invitation.kind == InvitationKind.book && !_blocked;
    final texts = t.book.card;
    final data = show
        ? DsStatusSlideData(
            id: periodInvitationStatusId,
            icon: Icons.menu_book_outlined,
            title: texts.title(period: invitation.period.period.name),
            subtitle: texts.subtitle,
            actionLabel: texts.close,
            onAction: () => widget.onOpenRitual(invitation.period.id),
            dismissLabel: texts.later,
            onDismiss: () async {
              await _gate?.dismissCard(invitation.period.id);
              await _refresh();
            },
            order: 4,
          )
        : null;
    return DsStatusReport(board: widget.board, id: periodInvitationStatusId, data: data);
  }
}
