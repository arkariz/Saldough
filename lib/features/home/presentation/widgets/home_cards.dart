import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/features/home/presentation/home_placeholder.dart';

// Keadaan awal Beranda (FR-HOME-005, ADR-043): kartu misi tiga langkah dan
// kartu buku kas kosong. Kartu berisi angka (saldo, anggaran, Freelance) ada
// di `home_summary.dart`.

/// Beranda pertama kali (acuan `empty-state.html`): maskot tanuki tidur
/// bernapas, judul misi, hadiah (tiruan, [kHomePlaceholderPreview]), batang
/// kemajuan tiga segmen, lalu tiga langkah (dompet, transaksi pertama,
/// anggaran). Langkah yang sedang berjalan bertombol dan berdenyut lembut;
/// yang selesai bercentang; yang belum bisa dibuka (butuh dompet) diam.
///
/// Urutan mengikuti alur produk (dompet, catat, anggaran opsional), bukan
/// urutan acuan, karena anggaran bukan syarat mencatat. Tidak pernah membuat
/// transaksi sendiri: "Catat transaksi" membuka alur CATAT yang sama lewat
/// [onRecord] (aturan 8).
class HomeFirstSteps extends StatelessWidget {
  /// Membuat [HomeFirstSteps].
  const HomeFirstSteps({
    required this.hasNoWallets,
    required this.onRecord,
    required this.onAddWallet,
    required this.onBudget,
    this.hasBudget = false,
    super.key,
  });

  /// Belum ada dompet sama sekali.
  final bool hasNoWallets;

  /// Sudah ada anggaran aktif (langkah anggaran dianggap selesai).
  final bool hasBudget;

  /// Membuka alur CATAT.
  final VoidCallback onRecord;

  /// Membuka jalan membuat dompet pertama.
  final VoidCallback onAddWallet;

  /// Membuka layar Anggaran.
  final VoidCallback onBudget;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final steps = [
      _Step(
        number: 1,
        title: t.home.stepWalletTitle,
        body: t.home.stepWalletBody,
        action: t.home.createWalletAction,
        done: !hasNoWallets,
        locked: false,
        onTap: onAddWallet,
        badge: t.home.stepNext,
      ),
      _Step(
        number: 2,
        title: t.home.stepRecordTitle,
        body: t.home.stepRecordBody,
        action: t.home.recordAction,
        done: false,
        locked: hasNoWallets,
        onTap: onRecord,
        badge: t.home.stepNext,
      ),
      _Step(
        number: 3,
        title: t.home.stepBudgetTitle,
        body: t.home.stepBudgetBody,
        action: t.home.budgetAction,
        done: hasBudget,
        locked: hasNoWallets,
        onTap: onBudget,
        badge: hasNoWallets ? t.home.stepLast : t.home.stepOptional,
      ),
    ];
    final doneCount = steps.where((s) => s.done).length;
    final currentIndex = steps.indexWhere((s) => !s.done && !s.locked);
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: DsRadius.xlAll,
        border: Border.all(color: c.outlineSubtle),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SleepingTanuki(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          t.home.firstLabel.toUpperCase(),
                          style: ds.typography.pixelCaption.copyWith(color: c.actionPrimary),
                        ),
                        DsBadge(
                          label: t.home.stepsProgress(done: doneCount, total: steps.length).toUpperCase(),
                          tone: doneCount == 0 ? DsBadgeTone.warning : DsBadgeTone.income,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text(
                        t.home.questTitle,
                        style: ds.typography.titleMd.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (kHomePlaceholderPreview) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(t.home.questReward, style: ds.typography.bodySm.copyWith(color: c.textMuted)),
                          DsBadge(label: t.home.questRewardXp, tone: DsBadgeTone.income),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    _SegmentedProgress(done: doneCount, total: steps.length),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: c.outlineSubtle),
          const SizedBox(height: 14),
          for (final (index, step) in steps.indexed) ...[
            if (index > 0) const SizedBox(height: 10),
            _StepCard(step: step, current: index == currentIndex),
          ],
        ],
      ),
    );
  }
}

/// Data satu langkah misi.
class _Step {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    required this.action,
    required this.done,
    required this.locked,
    required this.onTap,
    required this.badge,
  });

  final int number;
  final String title;
  final String body;
  final String action;
  final bool done;
  final bool locked;
  final VoidCallback onTap;
  final String badge;
}

/// Maskot tidur: bernapas pelan, dengan "z" yang naik dan memudar.
class _SleepingTanuki extends StatefulWidget {
  const _SleepingTanuki();

  @override
  State<_SleepingTanuki> createState() => _SleepingTanukiState();
}

class _SleepingTanukiState extends State<_SleepingTanuki> with SingleTickerProviderStateMixin {
  late final AnimationController _zzz = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  int _taps = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DsMotion.reduced(context)) {
      _zzz
        ..stop()
        ..value = 0;
    } else if (!_zzz.isAnimating) {
      _zzz.repeat();
    }
  }

  @override
  void dispose() {
    _zzz.dispose();
    super.dispose();
  }

  Widget _z(double phase, String text, double size) {
    final u = (_zzz.value + phase) % 1;
    final opacity = u < 0.3 ? u / 0.3 : (1 - (u - 0.3) / 0.7);
    return Positioned(
      right: 2 - u * 14,
      top: -2 - u * 26,
      child: Opacity(
        opacity: DsMotion.reduced(context) ? 0 : (opacity * 0.9).clamp(0, 1),
        child: Text(
          text,
          style: context.ds.typography.pixelCaption.copyWith(fontSize: size, color: context.ds.colors.warning),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return Semantics(
      image: true,
      label: t.home.firstLabel,
      child: GestureDetector(
        onTap: () => setState(() => _taps++),
        child: SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: DsRadius.lgAll,
                    border: Border.all(color: c.outlineSubtle),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [c.toneWarmContainer, c.surfaceSunken, c.incomeContainer],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: DsBounce(
                      trigger: _taps,
                      child: DsIdleMotion(
                        kind: DsIdleKind.float,
                        child: SvgPicture.asset(ClayIcons.mascotSleeping),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: c.warningContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.surfaceCard, width: 2),
                  ),
                  child: Icon(Icons.bedtime, size: 11, color: c.warning),
                ),
              ),
              AnimatedBuilder(
                animation: _zzz,
                builder: (context, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [_z(0, 'z', 11), _z(0.47, 'z', 9)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Batang kemajuan tiga segmen.
class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.carousel,
              height: 8,
              decoration: BoxDecoration(
                color: i < done ? c.actionPrimary : c.surfaceContainerHigh,
                borderRadius: DsRadius.fullAll,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Satu langkah: tile bernomor atau centang, judul, keterangan, dan tombol
/// (langkah berjalan), lencana (belum berjalan), atau "Selesai".
class _StepCard extends StatefulWidget {
  const _StepCard({required this.step, required this.current});

  final _Step step;
  final bool current;

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncGlow();
  }

  @override
  void didUpdateWidget(_StepCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncGlow();
  }

  void _syncGlow() {
    if (widget.current && !DsMotion.reduced(context)) {
      if (!_glow.isAnimating) _glow.repeat(reverse: true);
    } else {
      _glow
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final step = widget.step;
    final current = widget.current;
    final tappable = !step.done && !step.locked;
    final tile = Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: step.done || current ? c.actionPrimary : c.surfaceContainerHigh,
        borderRadius: DsRadius.mdAll,
      ),
      child: step.done
          ? Icon(Icons.check, size: 16, color: c.onActionPrimary)
          : Text(
              '${step.number}',
              style: ds.typography.pixelLabel.copyWith(
                fontSize: 12,
                color: current ? c.onActionPrimary : c.textMuted,
              ),
            ),
    );
    final texts = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: ds.typography.bodyMd.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation.weight(700)],
              color: step.locked ? c.textSecondary : c.textPrimary,
            ),
          ),
          Text(
            step.body,
            style: ds.typography.bodySm.copyWith(fontSize: 11, color: current ? c.onIncomeContainer : c.textMuted),
          ),
        ],
      ),
    );
    final trailing = step.done
        ? DsBadge(label: t.home.stepDone.toUpperCase(), tone: DsBadgeTone.income)
        : current
        ? DsButton.compact(label: step.action, onPressed: step.onTap)
        : DsBadge(label: step.badge.toUpperCase(), tone: DsBadgeTone.neutral);
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        final g = Curves.easeInOut.transform(_glow.value);
        return DsPressable(
          onPressed: tappable ? step.onTap : null,
          pressedScale: 0.99,
          dimWhenDisabled: false,
          semanticLabel: '${step.title}. ${step.body}',
          builder: (context, _) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: current ? c.incomeContainer.withValues(alpha: 0.55) : c.surfaceSunken.withValues(alpha: 0.6),
              borderRadius: DsRadius.lgAll,
              border: Border.all(
                color: current
                    ? Color.lerp(c.income.withValues(alpha: 0.45), c.actionPrimary.withValues(alpha: 0.5), g)!
                    : c.outlineSubtle,
              ),
              boxShadow: current
                  ? [
                      BoxShadow(
                        color: c.actionPrimary.withValues(alpha: 0.06 + 0.1 * g),
                        blurRadius: 8 + 8 * g,
                        spreadRadius: 3 * g,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: MediaQuery.textScalerOf(context).scale(1) > 1.3
          // Teks besar: tombol atau lencana turun ke baris sendiri, bukan
          // memeras judul langkah.
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [tile, const SizedBox(width: 12), texts]),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ExcludeSemantics(child: IgnorePointer(child: trailing)),
                ),
              ],
            )
          : Row(
              children: [
                tile,
                const SizedBox(width: 12),
                texts,
                const SizedBox(width: 8),
                // Tombol dan lencana tidak membaca ulang label; ketukan ke
                // seluruh kartu ditangani `DsPressable`.
                ExcludeSemantics(child: IgnorePointer(child: trailing)),
              ],
            ),
    );
  }
}

/// Isi bagian "Transaksi terbaru" bila belum ada transaksi: kartu kosong
/// bertile tray clay yang melayang pelan.
class HomeEmptyLedger extends StatelessWidget {
  /// Membuat [HomeEmptyLedger].
  const HomeEmptyLedger({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DsCard(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          DsIdleMotion(
            kind: DsIdleKind.float,
            child: DsIconTile.asset(asset: ClayIcons.emptyTray, size: DsIconTileSize.lg),
          ),
          const SizedBox(height: 12),
          Text(t.home.emptyTitle, textAlign: TextAlign.center, style: ds.typography.titleMd.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            t.home.emptyBody,
            textAlign: TextAlign.center,
            style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
