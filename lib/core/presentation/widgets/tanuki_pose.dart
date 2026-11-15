import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';

/// Pose Tanuki (rupa D8): selalu ramah, **tidak ada pose sedih atau kecewa**.
enum TanukiPoseKind {
  /// Biasa.
  neutral(ClayIcons.mascot),

  /// Senang: kartu dibagikan, stempel dicap, buku dibuka.
  happy(ClayIcons.mascotHappy),

  /// Menulis: ritual Tutup buku.
  writing(ClayIcons.mascotWriting),

  /// Tenang: halaman Kata Tanuki saat selisih negatif, jeda.
  calm(ClayIcons.mascotCalm);

  const TanukiPoseKind(this.asset);

  /// Aset clay pose ini.
  final String asset;
}

/// Tanuki dengan gerak diam yang sesuai pose (rupa D8): napas pelan (biasa dan
/// tenang), lompat kecil berulang (senang), menggoyang kepala saat menulis;
/// plus lompat `cheer` (900 ms) tiap [cheer] bertambah. Semua mati bila gerak
/// dikurangi (`DsMotion.reduced`); gambarnya `excludeSemantics`.
class TanukiPose extends StatefulWidget {
  /// Membuat [TanukiPose].
  const TanukiPose({required this.pose, this.size = 76, this.cheer = 0, this.semanticLabel, super.key});

  /// Pose.
  final TanukiPoseKind pose;

  /// Sisi gambar, dp.
  final double size;

  /// Naik tiap ada tindakan: memicu lompat.
  final int cheer;

  /// Label pembaca layar; `null` = dekoratif.
  final String? semanticLabel;

  @override
  State<TanukiPose> createState() => _TanukiPoseState();
}

class _TanukiPoseState extends State<TanukiPose> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: _idleDuration);
  late final AnimationController _jump = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  Duration get _idleDuration => switch (widget.pose) {
    TanukiPoseKind.happy => const Duration(milliseconds: 1100),
    TanukiPoseKind.writing => const Duration(milliseconds: 1300),
    TanukiPoseKind.neutral || TanukiPoseKind.calm => const Duration(milliseconds: 3200),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(TanukiPose old) {
    super.didUpdateWidget(old);
    if (old.pose != widget.pose) {
      _idle.duration = _idleDuration;
      _sync();
    }
    if (widget.cheer != old.cheer && !DsMotion.reduced(context)) {
      _jump.forward(from: 0);
    }
  }

  void _sync() {
    if (DsMotion.reduced(context)) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _jump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = SvgPicture.asset(widget.pose.asset, width: widget.size, height: widget.size);
    final body = AnimatedBuilder(
      animation: Listenable.merge([_idle, _jump]),
      builder: (context, child) {
        final b = Curves.easeInOut.transform(_idle.value);
        final j = _jump.value;
        final jumpY = dsKeyframes(j, [(0, 0), (0.18, 2), (0.45, -widget.size * 0.28), (0.65, -widget.size * 0.22), (0.85, 0), (1, 0)]);
        final jumpTilt = dsKeyframes(j, [(0, 0), (0.45, -8), (0.65, 8), (1, 0)]) * math.pi / 180;
        final sx = dsKeyframes(j, [(0, 1), (0.18, 1.12), (0.85, 1.08), (1, 1)]);
        final sy = dsKeyframes(j, [(0, 1), (0.18, 0.86), (0.85, 0.92), (1, 1)]);
        final (dy, tilt, breathY) = switch (widget.pose) {
          TanukiPoseKind.happy => (-widget.size * 0.06 * b, (b - 0.5) * 0.06, 0.0),
          TanukiPoseKind.writing => (0.0, (b - 0.5) * 0.09, 0.0),
          TanukiPoseKind.neutral || TanukiPoseKind.calm => (-widget.size * 0.05 * b, 0.0, 0.03 * b),
        };
        return Transform.translate(
          offset: Offset(0, dy + jumpY),
          child: Transform.rotate(
            angle: tilt + jumpTilt,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(sx, sy * (1 + breathY), 1),
              child: child,
            ),
          ),
        );
      },
      child: image,
    );
    if (widget.semanticLabel == null) return ExcludeSemantics(child: body);
    return Semantics(label: widget.semanticLabel, image: true, excludeSemantics: true, child: body);
  }
}
