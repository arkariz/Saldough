import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/onboarding/presentation/widgets/onboarding_scene.dart';

/// Satu layar onboarding: adegan clay di atas, kartu judul dan isi di bawah.
/// Adegan berparalaks setengah kecepatan geser (ADR-021 §3.7).
class OnboardingSlide extends StatelessWidget {
  /// Membuat [OnboardingSlide].
  const OnboardingSlide({required this.index, required this.active, required this.controller, super.key});

  /// Urutan layar, 0..[onboardingSlideCount] - 1.
  final int index;

  /// True saat layar ini yang tampil — hanya layar aktif yang bergerak.
  final bool active;

  /// Controller `PageView`, sumber posisi paralaks.
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    final (title, body) = onboardingText(index);
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: LayoutBuilder(
              builder: (context, constraints) => AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  final page = controller.hasClients && controller.position.haveDimensions
                      ? controller.page ?? index.toDouble()
                      : index.toDouble();
                  // Paralaks: adegan tertinggal setengah dari geseran halaman.
                  final dx = (page - index) * constraints.maxWidth * 0.5;
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: ExcludeSemantics(
                  child: OnboardingScene(index: index, active: active),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            flex: 2,
            child: SingleChildScrollView(
              child: DsCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(title, style: ds.typography.headlineMd.copyWith(fontSize: 22)),
                    ),
                    const SizedBox(height: 8),
                    Text(body, style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kepala langkah wajib (bahasa, mata uang, awal periode, pengingat): ikon
/// clay besar di lingkaran bercahaya, judul, dan keterangan, rata tengah.
class OnboardingStepHeader extends StatelessWidget {
  /// Membuat [OnboardingStepHeader].
  const OnboardingStepHeader({required this.asset, required this.title, required this.body, this.footer, super.key});

  /// Ikon clay.
  final String asset;

  /// Judul langkah.
  final String title;

  /// Keterangan langkah.
  final String body;

  /// Isi tambahan di bawah keterangan.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Column(
      children: [
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [c.actionPrimary.withValues(alpha: 0.18), c.actionPrimary.withValues(alpha: 0.04)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: DsIdleMotion(kind: DsIdleKind.float, child: SvgPicture.asset(asset, width: 72, height: 72)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          header: true,
          child: Text(title, textAlign: TextAlign.center, style: ds.typography.headlineMd.copyWith(fontSize: 22)),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: ds.typography.bodyMd.copyWith(color: c.textSecondary),
        ),
        if (footer != null) ...[const SizedBox(height: 12), footer!],
      ],
    );
  }
}

/// Indikator halaman: titik berbentuk pil; yang aktif memanjang dan berisi
/// warna aksi preset.
class OnboardingPageIndicator extends StatelessWidget {
  /// Membuat [OnboardingPageIndicator].
  const OnboardingPageIndicator({required this.count, required this.current, super.key});

  /// Jumlah halaman.
  final int count;

  /// Halaman aktif, dari 0.
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final duration = DsMotion.reduced(context) ? Duration.zero : DsMotion.standard;
    return Semantics(
      label: t.onboarding.pageIndicatorLabel(current: current + 1, total: count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == current ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == current ? c.actionPrimary : c.outlineSubtle,
                  borderRadius: DsRadius.fullAll,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Latar onboarding: kanvas yang bergeser lembut per halaman dengan daun dan
/// kilau melayang (`DsAmbientLayer`).
class OnboardingBackdrop extends StatelessWidget {
  /// Membuat [OnboardingBackdrop].
  const OnboardingBackdrop({required this.controller, super.key});

  /// Controller `PageView`, sumber warna per halaman.
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final tones = [c.surfaceCanvas, c.surfaceSunken, c.surfaceSunken, c.surfaceSunken, c.surfaceContainerHigh];
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final page = controller.hasClients && controller.position.haveDimensions ? controller.page ?? 0 : 0.0;
          final lower = page.floor().clamp(0, tones.length - 1);
          final upper = (lower + 1).clamp(0, tones.length - 1);
          final tone = Color.lerp(tones[lower], tones[upper], page - page.floor())!;
          return ColoredBox(color: tone, child: child);
        },
        child: const DsAmbientLayer(opacity: 0.45),
      ),
    );
  }
}

/// Pilihan satu dari beberapa di langkah onboarding: kartu dengan garis aksi
/// dan centang saat terpilih. [leading] untuk penanda di depan teks,
/// [detail] untuk keterangan kecil.
class OnboardingChoice extends StatelessWidget {
  /// Membuat [OnboardingChoice].
  const OnboardingChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
    this.leading,
    super.key,
  });

  /// Teks pilihan.
  final String label;

  /// Pilihan sedang terpilih.
  final bool selected;

  /// Dipanggil saat diketuk.
  final VoidCallback onTap;

  /// Keterangan kecil.
  final String? detail;

  /// Penanda di depan teks.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: DsPressable(
        semanticLabel: label,
        onPressed: onTap,
        builder: (context, _) => AnimatedContainer(
          duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.standard,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.actionPrimary.withValues(alpha: 0.06) : c.surfaceCard,
            borderRadius: DsRadius.lgAll,
            border: Border.all(color: selected ? c.actionPrimary : c.outlineSubtle, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: ds.typography.titleMd.copyWith(fontSize: 15)),
                    if (detail != null) Text(detail!, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: c.actionPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
