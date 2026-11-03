import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';

/// Transisi saat menggulir: anak yang masuk dari tepi bawah layar memudar
/// masuk sambil naik dan membesar sedikit, dan yang keluar lewat tepi atas
/// meredup dan mengecil sedikit. Mengikuti posisi gulir (bukan waktu), jadi
/// ikut terbalik saat menggulir balik. Anak yang sudah terlihat saat pertama
/// tampil tidak beranimasi. Diam saat gerak dikurangi atau tanpa `Scrollable`.
class DsScrollReveal extends StatefulWidget {
  /// Membuat [DsScrollReveal].
  const DsScrollReveal({required this.child, this.distance = 28, super.key});

  /// Isi.
  final Widget child;

  /// Jarak naik (px) saat masuk.
  final double distance;

  @override
  State<DsScrollReveal> createState() => _DsScrollRevealState();
}

class _DsScrollRevealState extends State<DsScrollReveal> {
  ScrollPosition? _position;

  /// 0 (belum masuk) .. 1 (penuh) di tepi bawah.
  double _enter = 1;

  /// 0 (di tepi atas, hampir keluar) .. 1 (penuh).
  double _exit = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_update);
      _position = position;
      _position?.addListener(_update);
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure(initial: true));
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_update);
    super.dispose();
  }

  // Posisi anak terakhir yang diukur dari tata letak, dan gulir saat itu;
  // gerak berikutnya dihitung dari selisih gulir supaya tidak tertinggal satu
  // frame di belakang tata letak.
  double? _baseTop;
  double _basePixels = 0;
  double _childHeight = 0;
  double _viewportHeight = 0;
  bool _measureQueued = false;

  void _measure({bool initial = false}) {
    _measureQueued = false;
    if (!mounted) return;
    final box = context.findRenderObject();
    final scrollable = Scrollable.maybeOf(context);
    if (box is! RenderBox || !box.attached || !box.hasSize || scrollable == null) return;
    final viewport = scrollable.context.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return;
    _baseTop = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    _basePixels = scrollable.position.pixels;
    _childHeight = box.size.height;
    _viewportHeight = viewport.size.height;
    _apply(initial: initial);
  }

  void _update() {
    if (!mounted || _baseTop == null) return;
    _apply();
    if (!_measureQueued) {
      _measureQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _apply({bool initial = false}) {
    final position = _position;
    final base = _baseTop;
    if (position == null || base == null) return;
    final top = base - (position.pixels - _basePixels);
    final height = _viewportHeight;
    final band = height * 0.22;
    // Masuk: penuh begitu bagian atas anak naik setinggi band dari tepi bawah.
    var enter = ((height - top) / band).clamp(0.0, 1.0);
    // Keluar: meredup saat bagian bawah anak mendekati tepi atas.
    var exit = ((top + _childHeight) / (band * 0.9)).clamp(0.0, 1.0);
    // Anak yang sudah terlihat saat pertama tampil tidak dianimasikan.
    if (initial) {
      if (top < height) enter = 1;
      exit = 1;
    }
    if ((enter - _enter).abs() > 0.01 || (exit - _exit).abs() > 0.01) {
      setState(() {
        _enter = enter;
        _exit = exit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (DsMotion.reduced(context) || _position == null) return widget.child;
    final enter = Curves.easeOutCubic.transform(_enter);
    final exit = Curves.easeOut.transform(_exit);
    final opacity = (enter * (0.35 + 0.65 * exit)).clamp(0.0, 1.0);
    final scale = (0.94 + 0.06 * enter) * (0.97 + 0.03 * exit);
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, (1 - enter) * widget.distance),
        child: Transform.scale(scale: scale, child: widget.child),
      ),
    );
  }
}
