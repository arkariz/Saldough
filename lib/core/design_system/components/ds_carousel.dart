import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_pressable.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_motion.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Carousel kartu satu per halaman: kepala (judul + panah), halaman, dan
/// titik indikator yang memanjang di halaman aktif.
///
/// Halaman memenuhi lebar penuh tanpa mengintip halaman sebelah. Tinggi
/// carousel mengikuti halaman **tertinggi** (diukur dari salinan tak
/// terlihat tanpa animasi), jadi tidak ada tebakan tinggi: isi tidak luap
/// pada skala teks besar dan tidak ada ruang kosong berlebih.
class DsCarousel extends StatefulWidget {
  /// Membuat carousel.
  const DsCarousel({
    required this.children,
    required this.previousLabel,
    required this.nextLabel,
    required this.dotLabel,
    this.title,
    this.titleIcon,
    this.onPageChanged,
    this.adaptiveHeight = false,
    super.key,
  });

  /// Halaman.
  final List<Widget> children;

  /// Judul kepala; tanpa judul, kepala (dan panah) tidak ditampilkan.
  final String? title;

  /// Ikon di depan judul.
  final IconData? titleIcon;

  /// Label pembaca layar tombol sebelumnya.
  final String previousLabel;

  /// Label pembaca layar tombol berikutnya.
  final String nextLabel;

  /// Label pembaca layar titik untuk halaman ke-[index] (mulai 0).
  final String Function(int index) dotLabel;

  /// Dipanggil saat halaman aktif berubah.
  final ValueChanged<int>? onPageChanged;

  /// Tinggi mengikuti halaman aktif (beranimasi) alih-alih halaman
  /// tertinggi. Dipakai bila halamannya jauh berbeda tinggi, mis. slide
  /// status satu baris bersama kartu anggaran.
  final bool adaptiveHeight;

  @override
  State<DsCarousel> createState() => _DsCarouselState();
}

class _DsCarouselState extends State<DsCarousel> {
  final PageController _controller = PageController();
  int _index = 0;
  List<double?> _heights = const [];

  void _reportHeight(int i, double height) {
    final next = List<double?>.generate(widget.children.length, (k) => k < _heights.length ? _heights[k] : null);
    if (next[i] == height) return;
    next[i] = height;
    setState(() => _heights = next);
  }

  double? get _currentHeight {
    if (!widget.adaptiveHeight || _index >= _heights.length) return null;
    return _heights[_index];
  }

  @override
  void didUpdateWidget(DsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_heights.length > widget.children.length) _heights = _heights.sublist(0, widget.children.length);
    // Jumlah halaman bisa berubah (slide status datang dan pergi).
    final last = widget.children.length - 1;
    if (_index > last && last >= 0) {
      _index = last;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(last);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int index) {
    final target = index.clamp(0, widget.children.length - 1);
    if (DsMotion.reduced(context)) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(target, duration: DsMotion.carousel, curve: DsMotion.curve);
    }
  }

  /// Setengah jarak antarkartu saat digeser.
  static const double _pageGap = 8;

  /// Tinggi sementara mode adaptif sampai halaman pertama melapor.
  static const double _fallbackHeight = 72;

  Widget _pager(List<Widget> pages) => PageView(
    controller: _controller,
    onPageChanged: (i) {
      setState(() => _index = i);
      widget.onPageChanged?.call(i);
    },
    children: pages,
  );

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final last = widget.children.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null)
          Row(
            children: [
              if (widget.titleIcon != null) ...[
                Icon(widget.titleIcon, size: 16, color: c.textPrimary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(widget.title!, style: ds.typography.pixelLabel.copyWith(color: c.textPrimary)),
                ),
              ),
              _Arrow(
                icon: Icons.chevron_left,
                label: widget.previousLabel,
                onPressed: _index > 0 ? () => _go(_index - 1) : null,
              ),
              _Arrow(
                icon: Icons.chevron_right,
                label: widget.nextLabel,
                onPressed: _index < last ? () => _go(_index + 1) : null,
              ),
            ],
          ),
        if (widget.adaptiveHeight)
          // Tinggi mengikuti halaman aktif: tiap halaman melapor tingginya
          // sendiri (tanpa salinan pengukur) dan dibiarkan setinggi isinya di
          // dalam bingkai (terpotong saat bergeser).
          AnimatedContainer(
            duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.carousel,
            curve: DsMotion.curve,
            height: _currentHeight ?? _fallbackHeight,
            child: _pager([
              for (var i = 0; i < widget.children.length; i++)
                OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: _HeightReporter(onHeight: (h) => _reportHeight(i, h), child: widget.children[i]),
                ),
            ]),
          )
        else
          Stack(
            children: [
              // Pengukur: salinan tak terlihat semua halaman menentukan tinggi
              // Stack (yang tertinggi). Tanpa semantik dan tanpa animasi.
              for (final child in widget.children)
                ExcludeSemantics(
                  child: TickerMode(
                    enabled: false,
                    child: Visibility(
                      visible: false,
                      maintainSize: true,
                      maintainState: true,
                      maintainAnimation: true,
                      child: SizedBox(width: double.infinity, child: child),
                    ),
                  ),
                ),
              // Bingkai PageView selebar 8px lebih ke tiap sisi dan tiap halaman
              // diberi 8px di kedua sisinya: saat diam kartu persis selebar
              // konten, saat digeser ada jarak 16px antarkartu.
              Positioned(
                left: -_pageGap,
                right: -_pageGap,
                top: 0,
                bottom: 0,
                child: _pager([
                  for (final child in widget.children)
                    Padding(padding: const EdgeInsets.symmetric(horizontal: _pageGap), child: child),
                ]),
              ),
            ],
          ),
        const SizedBox(height: 4),
        DsCarouselDots(
          count: widget.children.length,
          index: _index,
          labelFor: widget.dotLabel,
          onSelected: _go,
        ),
      ],
    );
  }
}

/// Titik indikator carousel: titik aktif memanjang (24px), lainnya 8px.
class DsCarouselDots extends StatelessWidget {
  /// Membuat titik indikator.
  const DsCarouselDots({
    required this.count,
    required this.index,
    required this.labelFor,
    this.onSelected,
    super.key,
  });

  /// Jumlah halaman.
  final int count;

  /// Halaman aktif.
  final int index;

  /// Label pembaca layar titik ke-i.
  final String Function(int index) labelFor;

  /// Dipanggil saat titik diketuk.
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Semantics(
            button: true,
            selected: i == index,
            label: labelFor(i),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSelected == null ? null : () => onSelected!(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
                child: AnimatedContainer(
                  duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.carousel,
                  curve: DsMotion.curve,
                  width: i == index ? 24 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == index ? c.actionPrimary : c.surfaceContainerHigh,
                    borderRadius: DsRadius.fullAll,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return DsPressable(
      onPressed: onPressed,
      semanticLabel: label,
      pressedScale: 0.9,
      builder: (context, _) => SizedBox.square(
        dimension: 44,
        child: Center(
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: c.surfaceContainer, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: c.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Melaporkan tinggi anak sesudah tata letak; tanpa [onHeight] hanya
/// meneruskan anak.
class _HeightReporter extends StatefulWidget {
  const _HeightReporter({required this.child, this.onHeight});

  final Widget child;
  final ValueChanged<double>? onHeight;

  @override
  State<_HeightReporter> createState() => _HeightReporterState();
}

class _HeightReporterState extends State<_HeightReporter> {
  @override
  Widget build(BuildContext context) {
    if (widget.onHeight != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final box = context.findRenderObject();
        if (box is RenderBox && box.hasSize) widget.onHeight?.call(box.size.height);
      });
    }
    return widget.child;
  }
}
