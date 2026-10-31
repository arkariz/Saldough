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
/// ([kHomePlaceholderPreview]) di kanan dan pil mood maskot di bawahnya. Pil
/// level bergoyang bila [jiggle] naik.
class HomeGreeting extends StatelessWidget {
  /// Membuat [HomeGreeting].
  const HomeGreeting({required this.name, this.jiggle = 0, this.firstRun = false, super.key});

  /// Nama depan pengguna, atau `null` bila belum masuk.
  final String? name;

  /// Naikkan untuk memutar goyangan pil level (klaim misi).
  final int jiggle;

  /// Belum ada transaksi: subjudul mengajak mulai, pil level pemula, dan
  /// tanpa pil mood (belum ada data yang dinilai).
  final bool firstRun;

  @override
  Widget build(BuildContext context) {
    final header = DsPageHeader(
      title: name == null ? t.home.greeting : t.home.greetingNamed(name: name!),
      subtitle: firstRun ? t.home.firstSubtitle : t.home.subtitle,
      trailing: kHomePlaceholderPreview
          ? DsJiggle(
              trigger: jiggle,
              child: DsStatusPill(label: firstRun ? t.home.preview.levelNew : t.home.preview.level),
            )
          : null,
    );
    if (!kHomePlaceholderPreview || firstRun) return header;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: DsSpacing.sm),
        const HomeMoodPill(),
      ],
    );
  }
}

/// Pil mood maskot (tiruan, [kHomePlaceholderPreview]): maskot kecil,
/// judul mood, dan persen sehat.
class HomeMoodPill extends StatelessWidget {
  /// Membuat [HomeMoodPill].
  const HomeMoodPill({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Semantics(
      label: '${t.home.preview.moodTitle}. ${t.home.preview.moodBadge}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
        decoration: BoxDecoration(
          color: c.surfaceCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.outlineSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(ClayIcons.mascot, width: 24, height: 24),
            const SizedBox(width: 6),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: t.home.preview.moodTitle),
                    TextSpan(
                      text: '  ${t.home.preview.moodBadge}',
                      style: TextStyle(color: c.income, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu carousel di bawah aksi cepat (ADR-043 §3.6): slide status dari
/// [board] (rutin menunggu, tangkapan notifikasi, pengingat, perkiraan; yang
/// perlu dicek tampil dulu), lalu slide wawasan: anggaran nyata (bila ada)
/// dan slide rutin dan hadiah tiruan ([kHomePlaceholderPreview]). Slide
/// status hanya membuka layar tujuannya; mencatat tidak pernah terjadi di
/// sini (aturan 8). Tinggi mengikuti slide aktif.
///
/// Target tur `homeStatus` hanya terdaftar bila ada slide status nyata, dan
/// `homeBudget` hanya bila anggaran nyata ada (slide tiruan tidak boleh
/// disorot). Keduanya membungkus carousel yang sama.
class HomeCarouselSection extends StatelessWidget {
  /// Membuat [HomeCarouselSection].
  const HomeCarouselSection({required this.board, required this.budget, required this.onOpenBudget, super.key});

  /// Papan status, atau `null`.
  final DsStatusBoard? board;

  /// Ringkasan anggaran aktif, atau `null`.
  final BudgetOverview? budget;

  /// Membuka tab Rencana pada segmen Anggaran.
  final VoidCallback onOpenBudget;

  @override
  Widget build(BuildContext context) {
    final board = this.board ?? DsStatusBoard();
    final overview = budget;
    return ListenableBuilder(
      listenable: board,
      builder: (context, _) {
        Widget carousel = DsStatusCarousel(
          board: board,
          extras: [
            if (overview != null) HomeBudgetCard(overview: overview, onOpen: onOpenBudget),
            if (kHomePlaceholderPreview) ...[const _BillSlide(), const _RewardSlide()],
          ],
          previousLabel: t.home.statusCarouselPrevious,
          nextLabel: t.home.statusCarouselNext,
          dotLabel: (i) => t.home.statusCarouselDot(number: i + 1),
        );
        if (overview != null) {
          carousel = SpotlightTarget(spotlightKey: SpotlightKey.homeBudget, child: carousel);
        }
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
/// [kHomePlaceholderPreview]). Misi Hemat berlencana "+50 XP"; mengetuknya
/// mengklaim: perayaan, lalu [onClaimed] (pil level bergoyang). Status klaim
/// hanya di layar ini dan tidak disimpan.
class HomeQuickActions extends StatefulWidget {
  /// Membuat [HomeQuickActions].
  const HomeQuickActions({
    required this.onRecordTransfer,
    required this.onOpenReport,
    this.onClaimed,
    super.key,
  });

  /// Membuka alur CATAT (aturan 8).
  final VoidCallback onRecordTransfer;

  /// Membuka Analisis periode berjalan.
  final VoidCallback onOpenReport;

  /// Dipanggil sekali per klaim misi.
  final VoidCallback? onClaimed;

  @override
  State<HomeQuickActions> createState() => _HomeQuickActionsState();
}

class _HomeQuickActionsState extends State<HomeQuickActions> {
  bool _claimed = false;

  void _claim(BuildContext tileContext) {
    if (_claimed) return;
    final box = tileContext.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      DsCelebration.burst(
        context,
        origin: box.localToGlobal(box.size.center(Offset.zero)),
        label: t.home.preview.missionReward,
      );
    }
    setState(() => _claimed = true);
    widget.onClaimed?.call();
    // Dikembalikan setelah 4,5 detik supaya bisa dicoba lagi (tiruan).
    Future<void>.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) setState(() => _claimed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      DsQuickActionTile(
        key: const ValueKey('home-action-transfer'),
        tile: DsIconTile.asset(asset: ClayIcons.transfer),
        label: t.home.actionTransfer,
        onPressed: widget.onRecordTransfer,
      ),
      // Scan Struk belum ada: tile pudar, tidak bisa diketuk, dan diberi
      // lencana "Segera" supaya tidak tampak rusak.
      _Badged(
        badge: DsBadge(label: t.home.soon, tone: DsBadgeTone.warm),
        child: DsQuickActionTile(
          key: const ValueKey('home-action-scan'),
          tile: DsIconTile.asset(asset: ClayIcons.scan, tone: DsIconTileTone.income),
          label: t.home.actionScan,
          onPressed: null,
        ),
      ),
      DsQuickActionTile(
        key: const ValueKey('home-action-report'),
        tile: DsIconTile.asset(asset: ClayIcons.report, tone: DsIconTileTone.info),
        label: t.home.actionReport,
        onPressed: widget.onOpenReport,
      ),
      if (kHomePlaceholderPreview)
        Builder(
          builder: (tileContext) => _Badged(
            badge: DsPulse(
              kind: DsPulseKind.gold,
              child: DsBadge(
                label: _claimed ? t.home.preview.missionClaimed : t.home.preview.missionReward,
                tone: DsBadgeTone.warning,
              ),
            ),
            child: DsQuickActionTile(
              key: const ValueKey('home-action-mission'),
              tile: DsIconTile.asset(asset: ClayIcons.trophy, tone: DsIconTileTone.warning),
              label: t.home.actionMission,
              onPressed: _claimed ? null : () => _claim(tileContext),
            ),
          ),
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

/// Lencana kecil di pojok kanan atas sebuah tile.
class _Badged extends StatelessWidget {
  const _Badged({required this.badge, required this.child});

  final Widget badge;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      child,
      Positioned(top: -6, right: -2, child: badge),
    ],
  );
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
