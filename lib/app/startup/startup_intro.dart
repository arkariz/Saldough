import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';

/// Intro pembuka sesudah splash native: animasi "Daun mendarat" (design
/// system v2, dipilih pemilik 6 Nov 2026).
///
/// Splash native menampilkan tanuki clay tanpa daun dan koin di latar
/// [lightBackground]/[darkBackground]. Frame pertama intro menggambar tubuh
/// yang sama di tengah layar dengan ukuran [mascotBoxSize], jadi peralihannya
/// tidak terlihat; lalu daun melayang jatuh ke kepala, tanuki memantul, koin
/// daun meletup, dan intro memudar ke aplikasi di bawahnya. Aplikasi sudah
/// dibangun di bawah lapisan ini sejak awal, jadi intro tidak menunda apa pun.
///
/// Diputar sekali per proses, hanya bila [preload] berhasil sebelum `runApp`
/// (boot ulang sesudah pemulihan cadangan tidak memanggilnya). Dilewati bila
/// gerak dikurangi; ketuk di mana saja untuk melompat ke akhir.
///
/// Gambar native dibangun `scripts/launcher_icon/build_splash.py`; ubah
/// ukuran atau warna di sini dan di skrip itu bersamaan.
class StartupIntro extends StatefulWidget {
  /// Membungkus [child] (isi `MaterialApp.builder`) dengan intro.
  const StartupIntro({required this.child, super.key});

  /// Aplikasi di bawah intro.
  final Widget child;

  /// Sisi kotak viewBox maskot (54 satuan) dalam dp; sama dengan `BOX_DP`
  /// di `build_splash.py`.
  static const double mascotBoxSize = 180;

  /// Latar mode terang, sama dengan `flutter_native_splash.color`.
  static const Color lightBackground = Color(0xFFDCF3E0);

  /// Latar mode gelap, sama dengan `flutter_native_splash.color_dark`.
  static const Color darkBackground = Color(0xFF111412);

  /// Lama seluruh intro, termasuk memudar keluar.
  static const Duration duration = Duration(milliseconds: 1900);

  /// Jeda diam sesudah frame pertama sebelum animasi mulai.
  static const Duration startDelay = Duration(milliseconds: 120);

  /// Tubuh tanuki tanpa daun (viewBox 54).
  static const String bodyAsset = 'assets/illustration/splash_tanuki_body.svg';

  /// Daun di kepala tanuki (viewBox 54).
  static const String leafAsset = 'assets/illustration/splash_tanuki_leaf.svg';

  /// Koin daun (viewBox 24), dipasang di kanan bawah seperti ikon peluncur.
  static const String coinAsset = 'assets/icons_clay/tier_coin.svg';

  static _IntroPictures? _pending;

  /// Memuat gambar maskot ke memori. Panggil sekali sebelum `runApp` agar
  /// frame pertama intro langsung tergambar; bila gagal, intro dilewati.
  static Future<void> preload([AssetBundle? bundle]) async {
    try {
      final pictures = await Future.wait([
        for (final asset in const [bodyAsset, leafAsset, coinAsset])
          vg.loadPicture(SvgAssetLoader(asset, assetBundle: bundle), null),
      ]);
      _pending = _IntroPictures(body: pictures[0], leaf: pictures[1], coin: pictures[2]);
    } on Object catch (e, st) {
      developer.log('Gambar intro gagal dimuat, intro dilewati', error: e, stackTrace: st, name: 'StartupIntro');
      _pending = null;
    }
  }

  /// Apakah intro siap diputar (dipakai uji).
  @visibleForTesting
  static bool get isPending => _pending != null;

  @override
  State<StartupIntro> createState() => _StartupIntroState();
}

class _StartupIntroState extends State<StartupIntro> with SingleTickerProviderStateMixin {
  // Diambil alih sekali; State berikutnya (mis. boot ulang) tidak memutar lagi.
  _IntroPictures? _pictures = StartupIntro._pending;

  late final AnimationController _controller = AnimationController(vsync: this, duration: StartupIntro.duration);

  late final Animation<double> _fade = ReverseAnimation(
    CurvedAnimation(parent: _controller, curve: const Interval(_Timeline.exitStart, 1, curve: Curves.easeOut)),
  );

  @override
  void initState() {
    super.initState();
    StartupIntro._pending = null;
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pictures == null) return;
    if (DsMotion.reduced(context)) {
      // Dipanggil tepat sebelum build, jadi cukup mengosongkan tanpa setState.
      _finish(rebuild: false);
    } else if (!_startScheduled) {
      _startScheduled = true;
      // Frame-frame awal berat (aplikasi di bawah ikut dibangun), jadi jam
      // animasi baru jalan sesudah frame pertama tergambar plus jeda diam
      // singkat; tanpa ini daun sudah mendarat sebelum sempat terlihat.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(StartupIntro.startDelay, () {
          if (mounted && _pictures != null && _controller.isDismissed) _controller.forward();
        });
      });
    }
  }

  bool _startScheduled = false;

  void _skip() {
    if (_controller.value < _Timeline.exitStart) _controller.forward(from: _Timeline.exitStart);
  }

  void _finish({bool rebuild = true}) {
    final pictures = _pictures;
    if (pictures == null) return;
    _controller.stop();
    if (rebuild) {
      setState(() => _pictures = null);
    } else {
      _pictures = null;
    }
    // Lepas gambar sesudah frame tanpa intro tergambar.
    WidgetsBinding.instance.addPostFrameCallback((_) => pictures.dispose());
  }

  @override
  void dispose() {
    _controller.dispose();
    _pictures?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pictures = _pictures;
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    // Susunan Stack selalu sama supaya [child] tidak dipasang ulang saat intro
    // dilepas.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (pictures != null)
          Positioned.fill(
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _skip,
                child: FadeTransition(
                  opacity: _fade,
                  child: ColoredBox(
                    color: dark ? StartupIntro.darkBackground : StartupIntro.lightBackground,
                    child: Center(
                      child: SizedBox.square(
                        dimension: StartupIntro.mascotBoxSize,
                        child: CustomPaint(painter: _MascotPainter(pictures, _controller)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _IntroPictures {
  const _IntroPictures({required this.body, required this.leaf, required this.coin});

  final PictureInfo body;
  final PictureInfo leaf;
  final PictureInfo coin;

  void dispose() {
    body.picture.dispose();
    leaf.picture.dispose();
    coin.picture.dispose();
  }
}

/// Jadwal intro sebagai pecahan [StartupIntro.duration] (1,9 dtk).
abstract final class _Timeline {
  static const double _ms = 1900;

  /// Daun jatuh, 150–950 ms.
  static const double leafStart = 150 / _ms;
  static const double leafEnd = 950 / _ms;

  /// Tubuh memantul saat daun mendarat, 760–1100 ms.
  static const double squashStart = 760 / _ms;
  static const double squashEnd = 1100 / _ms;

  /// Koin meletup, 950–1400 ms.
  static const double coinStart = 950 / _ms;
  static const double coinEnd = 1400 / _ms;

  /// Memudar ke aplikasi, 1550–1900 ms.
  static const double exitStart = 1550 / _ms;

  static double progress(double t, double start, double end) => ((t - start) / (end - start)).clamp(0.0, 1.0);
}

/// Bingkai kunci: pasangan (waktu 0–1, nilai), diinterpolasi easeInOut antar
/// bingkai.
double _keyframes(List<(double, double)> frames, double p) {
  if (p <= frames.first.$1) return frames.first.$2;
  for (var i = 1; i < frames.length; i++) {
    final (t1, v1) = frames[i];
    if (p <= t1) {
      final (t0, v0) = frames[i - 1];
      final local = Curves.easeInOut.transform((p - t0) / (t1 - t0));
      return v0 + (v1 - v0) * local;
    }
  }
  return frames.last.$2;
}

class _MascotPainter extends CustomPainter {
  _MascotPainter(this.pictures, this.animation) : super(repaint: animation);

  final _IntroPictures pictures;
  final Animation<double> animation;

  // Titik dalam satuan viewBox 54.
  static const Offset _bodyBase = Offset(27, 44);
  static const Offset _leafBase = Offset(28, 15);
  static const Offset _coinCenter = Offset(43, 39);
  static const double _coinSide = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final unit = size.width / 54;
    final exit = Curves.easeIn.transform(_Timeline.progress(t, _Timeline.exitStart, 1));
    final shrink = 1 - 0.1 * exit;

    final squash = _Timeline.progress(t, _Timeline.squashStart, _Timeline.squashEnd);
    final scaleX = _keyframes(const [(0, 1), (0.3, 1.08), (0.6, 0.96), (1, 1)], squash);
    final scaleY = _keyframes(const [(0, 1), (0.3, 0.92), (0.6, 1.05), (1, 1)], squash);

    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(shrink)
      ..translate(-size.width / 2, -size.height / 2);

    // Tubuh, dipantulkan dari dasar.
    final base = _bodyBase * unit;
    canvas
      ..save()
      ..translate(base.dx, base.dy)
      ..scale(scaleX, scaleY)
      ..translate(-base.dx, -base.dy);
    _draw(canvas, pictures.body, Offset.zero & size);
    canvas.restore();

    // Daun: melayang jatuh, lalu ikut turun-naik bersama kepala.
    final leaf = _Timeline.progress(t, _Timeline.leafStart, _Timeline.leafEnd);
    final dx = _keyframes(const [(0, -0.10), (0.45, 0.06), (0.65, -0.03), (0.78, 0), (1, 0)], leaf);
    final dy = _keyframes(const [(0, -0.9), (0.45, -0.45), (0.65, -0.1), (0.78, 0), (1, 0)], leaf);
    final turn = _keyframes(const [(0, -40), (0.45, 28), (0.65, -14), (0.78, 7), (0.9, -3), (1, 0)], leaf);
    final headDrop = (_leafBase.dy - _bodyBase.dy) * (scaleY - 1) * unit;
    final pivot = _leafBase * unit;
    final leafOpacity = _Timeline.progress(leaf, 0, 0.25);
    if (leafOpacity > 0) {
      canvas
        ..save()
        ..translate(pivot.dx + dx * size.width, pivot.dy + dy * size.height + headDrop)
        ..rotate(turn * math.pi / 180)
        ..translate(-pivot.dx, -pivot.dy);
      if (leafOpacity < 1) canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, leafOpacity));
      _draw(canvas, pictures.leaf, Offset.zero & size);
      if (leafOpacity < 1) canvas.restore();
      canvas.restore();
    }

    // Koin daun meletup di kanan bawah.
    final coin = _Timeline.progress(t, _Timeline.coinStart, _Timeline.coinEnd);
    final coinScale = _keyframes(const [(0, 0), (0.7, 1.25), (1, 1)], coin);
    if (coinScale > 0) {
      final center = _coinCenter * unit;
      final side = _coinSide * unit * coinScale;
      _draw(canvas, pictures.coin, Rect.fromCenter(center: center, width: side, height: side));
    }

    canvas.restore();
  }

  void _draw(Canvas canvas, PictureInfo info, Rect rect) {
    canvas
      ..save()
      ..translate(rect.left, rect.top)
      ..scale(rect.width / info.size.width, rect.height / info.size.height)
      ..drawPicture(info.picture)
      ..restore();
  }

  @override
  bool shouldRepaint(_MascotPainter oldDelegate) => oldDelegate.pictures != pictures;
}
