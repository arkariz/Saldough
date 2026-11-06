import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Tombol tambah bergaris putus-putus: [icon] dan [label] di kiri, [trailing]
/// (mis. lencana Plus) di kanan. Untuk aksi "tambah" di bawah daftar.
class DsDashedButton extends StatelessWidget {
  /// Membuat tombol.
  const DsDashedButton({
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_circle_outline_rounded,
    this.trailing,
    super.key,
  });

  /// Teks.
  final String label;

  /// Ikon di depan teks.
  final IconData icon;

  /// Widget di ujung kanan.
  final Widget? trailing;

  /// Dipanggil saat diketuk.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DsPressable(
      onPressed: onPressed,
      builder: (context, _) => CustomPaint(
        painter: _DashedBorderPainter(color: c.outline.withValues(alpha: 0.6), fill: c.surfaceSunken),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: c.actionPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: ds.typography.titleMd.copyWith(fontSize: 14, color: c.actionPrimary)),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.fill});

  final Color color;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(DsRadius.md));
    canvas.drawRRect(rrect, Paint()..color = fill);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..addRRect(rrect.deflate(0.6));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), stroke);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.fill != fill;
}
