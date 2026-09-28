import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:saldough/core/presentation/spotlight/spotlight_host.dart';
import 'package:saldough/core/tutorial/tutorial.dart';

/// Visibilitas sebuah tab bagi [TourTrigger]. `IndexedStack` membiarkan
/// tab tersembunyi tetap "hidup" (termasuk `TickerMode`), jadi shell memberi
/// tahu sendiri tab mana yang tampil.
class TourVisibility extends InheritedWidget {
  /// Membuat [TourVisibility].
  const TourVisibility({required this.visible, required super.child, super.key});

  /// True saat subtree ini sedang tampil di layar.
  final bool visible;

  /// Visibilitas terdekat; tanpa [TourVisibility] dianggap tampil.
  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<TourVisibility>()?.visible ?? true;

  @override
  bool updateShouldNotify(TourVisibility oldWidget) => oldWidget.visible != visible;
}

/// Memulai [tour] sesudah frame pertama, hanya saat [ready] (data termuat
/// dan syarat tur terpenuhi), tab-nya tampil ([TourVisibility]), dan rutenya
/// di depan (ADR-021 §3.3). Memeriksa ulang setiap syarat itu berubah.
///
/// Tanpa `SpotlightHost` di atasnya, widget ini tidak melakukan apa pun.
class TourTrigger extends StatefulWidget {
  /// Membuat [TourTrigger].
  const TourTrigger({required this.tour, required this.ready, required this.child, super.key});

  /// Tur yang dipicu.
  final TourId tour;

  /// True saat layar siap ditur.
  final bool ready;

  /// Isi layar.
  final Widget child;

  @override
  State<TourTrigger> createState() => _TourTriggerState();
}

class _TourTriggerState extends State<TourTrigger> {
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  /// Setiap pembangunan ulang dengan data baru dicek lagi: elemen yang baru
  /// muncul (mis. kartu anggaran sesudah anggaran pertama) punya langkah
  /// sendiri yang belum dilihat.
  @override
  void didUpdateWidget(TourTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  bool _eligible() {
    if (!widget.ready || !TourVisibility.of(context)) return false;
    final route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  void _schedule() {
    if (_scheduled || SpotlightHost.maybeOf(context, listen: false) == null || !_eligible()) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  Future<void> _start() async {
    _scheduled = false;
    final controller = SpotlightHost.maybeOf(context, listen: false);
    if (!mounted || controller == null || !_eligible()) return;
    // Lembar yang masih meluncur masuk (mis. CATAT) membuat target berpindah
    // tempat; tunggu animasi rutenya selesai dulu.
    await _routeSettled();
    if (!mounted || !_eligible()) return;
    if (!await controller.wouldStart(widget.tour) || !mounted) return;
    // Daftar yang tergulir membuang item di luar layar, termasuk target di
    // puncaknya. Kembali ke atas dulu -- hanya saat tur memang akan tampil,
    // supaya langkah-langkahnya urut dari atas.
    final scrollable = _firstScrollable(context);
    if (scrollable != null && scrollable.position.pixels > scrollable.position.minScrollExtent) {
      scrollable.position.jumpTo(scrollable.position.minScrollExtent);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (mounted && _eligible()) await controller.maybeStart(widget.tour, navigator: Navigator.maybeOf(context));
  }

  Future<void> _routeSettled() {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) return Future.value();
    final settled = Completer<void>();
    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        animation.removeStatusListener(listener);
        if (!settled.isCompleted) settled.complete();
      }
    }

    animation.addStatusListener(listener);
    return settled.future;
  }

  /// `Scrollable` vertikal pertama di bawah pemicu ini, kalau ada.
  static ScrollableState? _firstScrollable(BuildContext context) {
    ScrollableState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is ScrollableState) {
        final state = element.state as ScrollableState;
        if (state.axisDirection == AxisDirection.down) {
          found = state;
          return;
        }
      }
      element.visitChildElements(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  @override
  Widget build(BuildContext context) {
    // Daftarkan ketergantungan agar perubahan visibilitas/rute memicu
    // `didChangeDependencies`.
    TourVisibility.of(context);
    ModalRoute.of(context);
    return widget.child;
  }
}
