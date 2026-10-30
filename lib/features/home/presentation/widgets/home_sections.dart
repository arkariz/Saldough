import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/presentation/home_placeholder.dart';
import 'package:saldough/features/home/presentation/widgets/home_summary.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Sapaan Beranda: "Halo, {nama}!" dan subjudul, dengan pil level tiruan
/// ([kHomePlaceholderPreview]) di kanan. Pil bergoyang bila [jiggle] naik.
class HomeGreeting extends StatelessWidget {
  /// Membuat [HomeGreeting].
  const HomeGreeting({required this.name, this.jiggle = 0, super.key});

  /// Nama depan pengguna, atau `null` bila belum masuk.
  final String? name;

  /// Naikkan untuk memutar goyangan pil level (klaim misi).
  final int jiggle;

  @override
  Widget build(BuildContext context) {
    return DsPageHeader(
      title: name == null ? t.home.greeting : t.home.greetingNamed(name: name!),
      subtitle: t.home.subtitle,
      trailing: kHomePlaceholderPreview
          ? DsJiggle(
              trigger: jiggle,
              child: DsStatusPill(label: t.home.preview.level),
            )
          : null,
    );
  }
}

/// Kartu mood maskot (tiruan, [kHomePlaceholderPreview]).
class HomeMoodCard extends StatelessWidget {
  /// Membuat [HomeMoodCard].
  const HomeMoodCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DsMascotCard(
      mascot: SvgPicture.asset(ClayIcons.mascot, width: 40, height: 40),
      title: t.home.preview.moodTitle,
      badge: DsBadge(label: t.home.preview.moodBadge, tone: DsBadgeTone.income),
      meterValue: kHomePlaceholderMood,
      meterLabel: t.home.preview.moodBadge,
      note: t.home.preview.moodNote,
      noteIcon: Icons.psychology_alt_outlined,
    );
  }
}

/// Carousel status "Perlu dicek" di atas kartu saldo (ADR-043): slide dari
/// [board] (rutin menunggu, tangkapan notifikasi, pengingat; yang perlu
/// dicek tampil dulu) lalu kartu mood tiruan ([showMood]). Setiap slide satu
/// baris yang membuka layar tujuannya; mencatat tidak pernah terjadi di sini
/// (aturan 8). Target tur `homeStatus` hanya terdaftar bila ada slide nyata.
class HomeStatusSection extends StatelessWidget {
  /// Membuat [HomeStatusSection].
  const HomeStatusSection({required this.board, required this.showMood, super.key});

  /// Papan status, atau `null`.
  final DsStatusBoard? board;

  /// Tampilkan kartu mood tiruan di belakang.
  final bool showMood;

  @override
  Widget build(BuildContext context) {
    final board = this.board ?? DsStatusBoard();
    return ListenableBuilder(
      listenable: board,
      builder: (context, _) {
        final carousel = DsStatusCarousel(
          board: board,
          trailing: showMood ? const HomeMoodCard() : null,
          previousLabel: t.home.statusCarouselPrevious,
          nextLabel: t.home.statusCarouselNext,
          dotLabel: (i) => t.home.statusCarouselDot(number: i + 1),
        );
        if (board.slides.isEmpty) return carousel;
        // Disorot sekali saat pertama tampil: slidenya datang sesudah layar.
        return TourTrigger(
          tour: TourId.home,
          ready: true,
          child: SpotlightTarget(spotlightKey: SpotlightKey.homeStatus, child: carousel),
        );
      },
    );
  }
}

/// Carousel "Wawasan & Rencana": slide anggaran nyata (bila ada), lalu
/// slide rutin dan hadiah tiruan ([kHomePlaceholderPreview]). Tanpa
/// setidaknya dua slide, hanya kartu anggarannya yang tampil.
///
/// Tinggi carousel mengikuti slide tertinggi (`DsCarousel`), jadi isi tidak
/// luap pada skala teks besar.
class HomeInsightCarousel extends StatelessWidget {
  /// Membuat [HomeInsightCarousel].
  const HomeInsightCarousel({required this.budget, required this.onOpenBudget, super.key});

  /// Ringkasan anggaran aktif, atau `null`.
  final BudgetOverview? budget;

  /// Membuka tab Rencana pada segmen Anggaran.
  final VoidCallback onOpenBudget;

  @override
  Widget build(BuildContext context) {
    final overview = budget;
    final slides = <Widget>[
      if (overview != null) HomeBudgetCard(overview: overview, onOpen: onOpenBudget),
      if (kHomePlaceholderPreview) ...[const _BillSlide(), const _RewardSlide()],
    ];
    if (slides.isEmpty) return const SizedBox.shrink();
    if (slides.length == 1) return slides.single;
    return DsCarousel(
      title: t.home.insightTitle.toUpperCase(),
      titleIcon: Icons.trending_up,
      previousLabel: t.home.carouselPrevious,
      nextLabel: t.home.carouselNext,
      dotLabel: (i) => t.home.carouselDot(number: i + 1),
      children: [for (final slide in slides) Align(alignment: Alignment.topCenter, child: slide)],
    );
  }
}

class _BillSlide extends StatelessWidget {
  const _BillSlide();

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideHeader(
            leading: Icon(Icons.event_note_outlined, size: 17, color: c.error),
            title: t.home.preview.billTitle,
            badge: DsPulse(
              child: DsBadge(label: t.home.preview.billBadge, tone: DsBadgeTone.danger),
            ),
          ),
          const SizedBox(height: 10),
          Text(t.home.preview.billName, style: ds.typography.bodyMd),
          const SizedBox(height: 2),
          Text(t.home.preview.billDue, style: ds.typography.bodySm.copyWith(color: c.textMuted)),
          const SizedBox(height: 8),
          Text(t.home.preview.billAmount, style: ds.typography.amount),
        ],
      ),
    );
  }
}

class _RewardSlide extends StatelessWidget {
  const _RewardSlide();

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideHeader(
            leading: DsIdleMotion(
              kind: DsIdleKind.float,
              child: SvgPicture.asset(ClayIcons.tierCoin, width: 20, height: 20),
            ),
            title: t.home.preview.rewardTitle,
            badge: DsPulse(
              kind: DsPulseKind.gold,
              child: DsBadge(label: t.home.preview.rewardBadge, tone: DsBadgeTone.warning),
            ),
          ),
          const SizedBox(height: 10),
          Text(t.home.preview.rewardAmount, style: ds.typography.amount),
          const SizedBox(height: 2),
          Text(t.home.preview.rewardNote, style: ds.typography.bodySm.copyWith(color: c.textMuted)),
        ],
      ),
    );
  }
}

/// Kepala slide: ikon + judul, badge di kanan. Pada skala teks besar badge
/// turun ke baris sendiri (`Wrap`) alih-alih memeras judul per kata.
class _SlideHeader extends StatelessWidget {
  const _SlideHeader({required this.leading, required this.title, required this.badge});

  final Widget leading;
  final String title;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            Flexible(child: Text(title, style: context.ds.typography.titleMd.copyWith(fontSize: 15))),
          ],
        ),
        badge,
      ],
    );
  }
}

/// Empat tile aksi cepat bergambar clay: Catat Transfer, Scan Struk (belum
/// ada, nonaktif berlabel "Segera"), Laporan, dan Misi Hemat (tiruan,
/// [kHomePlaceholderPreview]).
class HomeQuickActions extends StatelessWidget {
  /// Membuat [HomeQuickActions].
  const HomeQuickActions({required this.onRecordTransfer, required this.onOpenReport, super.key});

  /// Membuka alur CATAT (aturan 8).
  final VoidCallback onRecordTransfer;

  /// Membuka Analisis periode berjalan.
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      DsQuickActionTile(
        key: const ValueKey('home-action-transfer'),
        tile: DsIconTile.asset(asset: ClayIcons.transfer),
        label: t.home.actionTransfer,
        onPressed: onRecordTransfer,
      ),
      // Scan Struk belum ada: tile pudar, tidak bisa diketuk, dan diberi
      // lencana "Segera" supaya tidak tampak rusak.
      Stack(
        clipBehavior: Clip.none,
        children: [
          DsQuickActionTile(
            key: const ValueKey('home-action-scan'),
            tile: DsIconTile.asset(asset: ClayIcons.scan, tone: DsIconTileTone.income),
            label: t.home.actionScan,
            onPressed: null,
          ),
          Positioned(
            top: -6,
            right: -2,
            child: DsBadge(label: t.home.soon, tone: DsBadgeTone.warm),
          ),
        ],
      ),
      DsQuickActionTile(
        key: const ValueKey('home-action-report'),
        tile: DsIconTile.asset(asset: ClayIcons.report, tone: DsIconTileTone.info),
        label: t.home.actionReport,
        onPressed: onOpenReport,
      ),
      if (kHomePlaceholderPreview)
        DsQuickActionTile(
          key: const ValueKey('home-action-mission'),
          tile: DsIconTile.asset(asset: ClayIcons.trophy, tone: DsIconTileTone.warning),
          label: t.home.actionMission,
          onPressed: () {},
        ),
    ];
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

/// Banner misi harian tiruan ([kHomePlaceholderPreview]). "KLAIM" memicu
/// perayaan dan memberi tahu [onClaimed] (pil level bergoyang); status
/// hanya di layar ini dan tidak disimpan.
class HomeMissionBanner extends StatefulWidget {
  /// Membuat [HomeMissionBanner].
  const HomeMissionBanner({required this.onClaimed, super.key});

  /// Dipanggil sekali per klaim.
  final VoidCallback onClaimed;

  @override
  State<HomeMissionBanner> createState() => _HomeMissionBannerState();
}

class _HomeMissionBannerState extends State<HomeMissionBanner> {
  bool _claimed = false;

  void _claim(BuildContext buttonContext) {
    if (_claimed) return;
    final box = buttonContext.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      DsCelebration.burst(
        context,
        origin: box.localToGlobal(box.size.center(Offset.zero)),
        label: t.home.preview.missionReward,
      );
    }
    setState(() => _claimed = true);
    widget.onClaimed();
    // Dikembalikan setelah 4,5 detik supaya bisa dicoba lagi (tiruan).
    Future<void>.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) setState(() => _claimed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DsInlineBanner(
      icon: Icons.explore_outlined,
      eyebrow: t.home.preview.missionEyebrow,
      message: t.home.preview.missionBody,
      action: Builder(
        builder: (buttonContext) => DsButton.compact(
          label: _claimed ? t.home.preview.missionClaimed : t.home.preview.missionClaim,
          onPressed: _claimed ? null : () => _claim(buttonContext),
        ),
      ),
    );
  }
}

/// Satu baris transaksi terbaru: ikon clay bila kategorinya sudah
/// digambar, ikon piksel lama di tile datar bila belum (KT-DS5), judul,
/// nominal bertanda, dompet dan jam, serta nama kategori.
class HomeRecentRow extends StatelessWidget {
  /// Membuat [HomeRecentRow].
  const HomeRecentRow({required this.transaction, required this.walletsById, this.onTap, super.key});

  /// Transaksi yang ditampilkan.
  final Transaction transaction;

  /// Peta `id` dompet -> [Wallet].
  final Map<String, Wallet> walletsById;

  /// Dipanggil saat baris diketuk.
  final VoidCallback? onTap;

  String _walletName(String id) => walletsById[id]?.name ?? '—';

  String get _subtitle {
    final time = transactionTime(transaction.date);
    return switch (transaction) {
      TransferTransaction(:final fromWalletId, :final toWalletId) =>
        '${_walletName(fromWalletId)} → ${_walletName(toWalletId)} · $time',
      IncomeTransaction(:final walletId) || ExpenseTransaction(:final walletId) => '${_walletName(walletId)} · $time',
    };
  }

  @override
  Widget build(BuildContext context) {
    final (moneyKind, rowKind, txKind) = switch (transaction) {
      IncomeTransaction() => (MoneyKind.income, DsLedgerKind.income, TransactionKind.income),
      ExpenseTransaction() => (MoneyKind.expense, DsLedgerKind.expense, TransactionKind.expense),
      TransferTransaction() => (MoneyKind.transfer, DsLedgerKind.transfer, TransactionKind.transfer),
    };
    final iconKey = TransactionIcon.iconKeyFor(
      kind: txKind,
      categoryId: transaction.categoryId,
      title: transaction.note,
    );
    final clay = transaction.sourceIconId == null ? ClayIcons.forIcon(iconKey) : null;
    final category = txKind == TransactionKind.transfer ? null : ActiveCategories.byId(transaction.categoryId);
    return DsLedgerRow(
      leading: clay != null
          ? DsIconTile.asset(
              asset: clay,
              tone: txKind == TransactionKind.income ? DsIconTileTone.income : DsIconTileTone.neutral,
            )
          : SizedBox.square(
              dimension: 40,
              child: Center(child: TransactionIcon.of(transaction, ringColor: context.ds.colors.surfaceCard)),
            ),
      title: transactionTitle(transaction),
      amount: AppMoneyText.format(transaction.amount, moneyKind),
      subtitle: _subtitle,
      badge: category == null
          ? null
          : DsBadge(
              label: category.name,
              tone: txKind == TransactionKind.income ? DsBadgeTone.income : DsBadgeTone.category,
            ),
      kind: rowKind,
      onTap: onTap,
    );
  }
}
