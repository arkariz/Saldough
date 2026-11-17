import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_action_snack_bar.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/core/presentation/widgets/tanuki_pose.dart';
import 'package:saldough/features/period_book/domain/services/period_book_shelf.dart';
import 'package:saldough/features/period_book/presentation/period_book_shelf_access.dart';
import 'package:saldough/features/period_book/presentation/widgets/book_cover.dart';
import 'package:saldough/features/period_book/presentation/widgets/book_visuals.dart';
import 'package:saldough/features/period_book/presentation/widgets/stagger_in.dart';

/// Rak Buku (rupa D7, T-27.7): segmen Buku di Riwayat. Kisi dua kolom sampul
/// kecil, terbaru di atas, dengan garis rak di bawah tiap baris.
///
/// - **Belum dibuka** (boleh): pita "Baru" emas yang berayun.
/// - **Sudah dibuka**: sampul sedikit pudar, tanpa pita.
/// - **Terkunci** (bukan Plus, belum pernah dibuka): gembok di tengah, sampul
///   diredam; mengetuk memunculkan pesan, bukan paywall.
/// - **Kosong**: Tanuki dan ajakan lembut, tanpa tombol.
///
/// **Tidak ada** hitungan "n buku menunggu" dan penanda belum-dibuka di tab
/// (BP-9). Buku dibuka lewat [onOpenBook] (rute sampul); rak dimuat ulang
/// sesudahnya.
class BookShelfView extends StatefulWidget {
  /// Membuat [BookShelfView].
  const BookShelfView({required this.access, required this.onOpenBook, super.key});

  /// Pintu ke data rak.
  final PeriodBookShelfAccess access;

  /// Membuka buku [periodId] (sampul); selesai saat layar sampul ditutup.
  final Future<void> Function(String periodId) onOpenBook;

  @override
  State<BookShelfView> createState() => _BookShelfViewState();
}

class _BookShelfViewState extends State<BookShelfView> {
  List<ShelfEntry>? _entries;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final entries = await widget.access.shelf();
    if (mounted) setState(() => _entries = entries);
  }

  Future<void> _tap(ShelfEntry entry) async {
    if (entry.status == ShelfStatus.locked) {
      ScaffoldMessenger.of(context).showAppSnackBar(SnackBar(content: Text(t.book.shelf.lockedToast)));
      return;
    }
    await widget.onOpenBook(entry.period.id);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    if (entries == null) return const Center(child: CircularProgressIndicator());
    if (entries.isEmpty) return const _EmptyShelf();
    final ds = context.ds;
    final rows = [for (var i = 0; i < entries.length; i += 2) entries.sublist(i, math.min(i + 2, entries.length))];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              ExcludeSemantics(child: SvgPicture.asset(ClayIcons.shelfBooks, width: 34, height: 34)),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(header: true, child: Text(t.book.shelf.title, style: ds.typography.headlineSm)),
              ),
            ],
          ),
        ),
        for (final (r, row) in rows.indexed) ...[
          StaggerIn(
            index: r,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in row)
                  Expanded(
                    child: _Cell(entry: entry, onTap: () => unawaited(_tap(entry))),
                  ),
                if (row.length == 1) const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
          // Garis rak.
          Container(
            height: 6,
            margin: const EdgeInsets.only(top: 4, bottom: 22),
            decoration: BoxDecoration(color: ds.colors.outlineStrong, borderRadius: BorderRadius.circular(3)),
          ),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.entry, required this.onTap});

  final ShelfEntry entry;
  final VoidCallback onTap;

  String get _status => switch (entry.status) {
    ShelfStatus.opened => t.book.shelf.opened,
    ShelfStatus.unopened => t.book.shelf.unopened,
    ShelfStatus.locked => t.book.shelf.locked,
  };

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final period = entry.period.period;
    final name = period.name;
    final status = period.isTransition ? t.book.cover.transition(days: period.days) : _status;
    Widget cover = BookCover(
      eyebrow: '',
      title: name,
      semanticLabel: t.book.shelf.semantic(period: name, status: _status),
      width: 124,
    );
    cover = switch (entry.status) {
      ShelfStatus.opened => Opacity(opacity: 0.86, child: cover),
      ShelfStatus.unopened => cover,
      ShelfStatus.locked => ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.55, 0.3, 0.05, 0, 0, //
          0.2, 0.65, 0.05, 0, 0,
          0.2, 0.3, 0.3, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: Opacity(opacity: 0.8, child: cover),
      ),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            SizedBox(
              width: 124,
              height: 171,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  cover,
                  if (entry.status == ShelfStatus.locked)
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                      child: const Icon(Icons.lock_outline, size: 28, color: Colors.white),
                    ),
                  if (entry.status == ShelfStatus.unopened)
                    Positioned(top: 8, right: -4, child: _NewRibbon(label: t.book.shelf.fresh)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              status,
              textAlign: TextAlign.center,
              style: ds.typography.bodySm.copyWith(color: c.textMuted, fontSize: 11, height: 14 / 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pita "Baru" emas yang berayun ±3° (rupa D7); diam bila gerak dikurangi.
class _NewRibbon extends StatefulWidget {
  const _NewRibbon({required this.label});

  final String label;

  @override
  State<_NewRibbon> createState() => _NewRibbonState();
}

class _NewRibbonState extends State<_NewRibbon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DsMotion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) =>
          Transform.rotate(angle: (Curves.easeInOut.transform(_c.value) - 0.5) * 6 * math.pi / 180, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c.stampGold, c.stampGoldDeep]),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          widget.label.toUpperCase(),
          style: context.ds.typography.pixelCaption.copyWith(
            color: const Color(0xFF78350F),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf();

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: BookScene(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TanukiPose(pose: TanukiPoseKind.calm, size: 120),
                const SizedBox(height: 12),
                Text(t.book.shelf.empty, style: ds.typography.headlineSm, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  t.book.shelf.emptyHint,
                  textAlign: TextAlign.center,
                  style: ds.typography.bodyMd.copyWith(color: ds.colors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
