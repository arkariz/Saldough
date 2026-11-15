import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/stamp_visuals.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';
import 'package:saldough/features/period_book/presentation/navigation/period_book_route_keys.dart';
import 'package:saldough/features/period_book/presentation/period_book_read_access.dart';
import 'package:saldough/features/period_book/presentation/widgets/book_cover.dart';

/// Sampul buku (rupa D5, T-27.6): buku melayang, stempel periode dicap satu per
/// satu (permainan, dipicu pengguna membuka buku sehingga boleh ramai, BP-13
/// revisi), lalu **Buka rapor**. Membuka layar ini menandai buku dibuka dan
/// mencetak stempel ke sampul secara permanen (di `access.open`). Tanpa
/// peringkat, skor, atau perbandingan dengan pengguna lain.
class BookCoverPage extends StatefulWidget {
  /// Membuat [BookCoverPage].
  const BookCoverPage({required this.access, required this.periodId, super.key});

  /// Pintu ke data.
  final PeriodBookReadAccess access;

  /// Id periode.
  final String periodId;

  @override
  State<BookCoverPage> createState() => _BookCoverPageState();
}

class _BookCoverPageState extends State<BookCoverPage> {
  BookLoad? _load;
  int _printed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    final load = await widget.access.open(widget.periodId);
    if (!mounted) return;
    setState(() => _load = load);
    if (load is! BookReady || load.stamps.isEmpty) return;
    if (DsMotion.reduced(context)) {
      setState(() => _printed = load.stamps.length);
      return;
    }
    // Dicap satu per satu: mulai 500 ms, selang 900 ms (rupa D5).
    _timer = Timer(const Duration(milliseconds: 500), () => _printNext(load.stamps.length));
  }

  void _printNext(int total) {
    if (!mounted) return;
    setState(() => _printed++);
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      DsCelebration.burst(context, origin: box.localToGlobal(box.size.center(Offset.zero)), count: 22);
    }
    if (_printed < total) _timer = Timer(const Duration(milliseconds: 900), () => _printNext(total));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final load = _load;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())),
      body: SafeArea(
        child: switch (load) {
          null => const Center(child: CircularProgressIndicator()),
          BookLocked() || BookFailed() => const SizedBox.shrink(),
          BookReady() => Column(
            children: [
              Expanded(
                child: Center(
                  child: FloatingBook(
                    child: BookCover(
                      eyebrow: t.book.cover.eyebrow,
                      title: load.content.period.period.name,
                      subtitle: _subtitle(load.content),
                      semanticLabel: [
                        t.book.cover.semantic(period: load.content.period.period.name),
                        for (final id in load.stamps.take(_printed)) stampName(id),
                      ].join('. '),
                      seals: [
                        for (final (i, id) in load.stamps.indexed)
                          if (i < _printed)
                            DsStampSeal(
                              asset: stampAsset(id),
                              semanticLabel: stampName(id),
                              rotation: stampRotation(id),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: DsButton(
                  label: t.book.cover.openReport,
                  expand: true,
                  onPressed: () => unawaited(
                    context.pushRoute(PeriodBookRouteKeys.report, BookInput(periodId: widget.periodId)),
                  ),
                ),
              ),
            ],
          ),
        },
      ),
      backgroundColor: ds.colors.surfaceCanvas,
    );
  }

  String _subtitle(PeriodBookContent content) {
    final period = content.period.period;
    return period.isTransition
        ? t.book.cover.transition(days: period.days)
        : '${period.start.year}';
  }
}
