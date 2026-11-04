import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/account/presentation/navigation/account_route_keys.dart';
import 'package:saldough/features/analysis/presentation/navigation/analysis_route_keys.dart';
import 'package:saldough/features/freelance/presentation/navigation/freelance_route_keys.dart';
import 'package:saldough/features/home/presentation/bloc/home_bloc.dart';
import 'package:saldough/features/home/presentation/bloc/home_state.dart';
import 'package:saldough/features/home/presentation/home_placeholder.dart';
import 'package:saldough/features/home/presentation/widgets/home_cards.dart';
import 'package:saldough/features/home/presentation/widgets/home_sections.dart';
import 'package:saldough/features/home/presentation/widgets/home_skeleton.dart';
import 'package:saldough/features/home/presentation/widgets/home_summary.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/auth/auth_presentation.dart';
import 'package:state_management/state_management.dart';

/// Beranda (Fase 6, FR-HOME-001..005), rujukan visual `pixel_kas_beranda` dan
/// `pixel_kas_beranda_belum_ada_data`.
///
/// Perpindahan ke tab lain dan alur CATAT dioper [AppShellPage] lewat
/// callback, supaya bloc tab-tab itu ikut disegarkan dengan cara yang sama
/// seperti saat tabnya dipilih dari navigasi bawah. Ajakan mencatat membuka
/// alur CATAT yang SAMA (aturan 8), bukan formulir tersendiri.
class HomePage extends StatefulWidget {
  /// Membuat [HomePage].
  const HomePage({
    required this.onRecord,
    required this.onShowBudgets,
    required this.onShowTransactions,
    required this.onShowWallets,
    this.updateHost,
    this.notice,
    this.pendingRecurring,
    this.featureNudge,
    this.forecast,
    this.statusBoard,
    this.notificationAction,
    super.key,
  });

  /// Tile aksi cepat Catat dari notifikasi, disisipkan akar komposisi (`null` = tidak ada).
  final Widget? notificationAction;

  /// Membuka alur CATAT.
  final Future<void> Function() onRecord;

  /// Pindah ke tab Anggaran.
  final VoidCallback onShowBudgets;

  /// Pindah ke tab Transaksi.
  final VoidCallback onShowTransactions;

  /// Pindah ke tab Dompet (membuat dompet pertama).
  final VoidCallback onShowWallets;

  /// Widget tanpa tampilan untuk pembaruan aplikasi, disisipkan akar
  /// komposisi: pengumumannya masuk sebagai slide di papan status dan lembar
  /// "Apa yang baru" dibuka darinya (APP_UPDATE, ADR-043 §3.6). `null` = tidak
  /// ada.
  final Widget? updateHost;

  /// Kartu pemberitahuan di bawah total saldo, disisipkan akar komposisi
  /// (mis. kotak masuk Catat dari notifikasi, ADR-032); `null` = tidak ada.
  final Widget? notice;

  /// Kartu Menunggu dicatat (T-15.6), disisipkan akar komposisi supaya
  /// `home` tidak mengimpor fitur `recurring`; tampil hanya bila ada isinya.
  final Widget? pendingRecurring;

  /// Kartu tombol permanen pengingat rutin (Fase 21, P-6: sesudah Menunggu
  /// dicatat dan kotak masuk), disisipkan akar komposisi; kosong bila
  /// pengingat sudah efektif.
  final Widget? featureNudge;

  /// Baris perkiraan saldo akhir bulan (T-15.13), disisipkan akar komposisi.
  final Widget? forecast;

  /// Papan status (ADR-043): slot [notice], [pendingRecurring], dan
  /// [featureNudge] melapor ke sini (tanpa menggambar kartu) dan Beranda
  /// menampilkannya sebagai carousel "Perlu dicek" di atas kartu saldo.
  /// `null` = tanpa carousel status.
  final DsStatusBoard? statusBoard;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scroll = ScrollController();

  /// Naik tiap klaim misi tiruan; memutar goyangan pil level.
  int _claims = 0;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const HomeStarted());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Menjalankan [open] lalu menyegarkan Beranda — angka bisa berubah di
  /// layar yang dibukanya (mencatat, menerima pembayaran, menyunting).
  Future<void> _thenRefresh(Future<void> Function() open) async {
    final bloc = context.read<HomeBloc>();
    await open();
    bloc.add(const HomeRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // `DsTopBar` memakai `SafeArea` sendiri, jadi tingginya harus
      // memasukkan inset atas (berbeda dengan `AppBar`).
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56 + MediaQuery.paddingOf(context).top),
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: _topBar,
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) => switch (state) {
            HomeState(isLoading: true) => const HomeSkeleton(),
            HomeState(loadFailed: true) => _LoadError(
              onRetry: () => context.read<HomeBloc>().add(const HomeStarted()),
            ),
            _ => DsAmbientBackdrop(child: _content(context, state)),
          },
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, HomeState state) {
    final ds = context.ds;
    final c = ds.colors;
    return DsCollapsingTopBar(
      controller: _scroll,
      wordmark: t.app.title.toLowerCase(),
      logo: SvgPicture.asset(ClayIcons.mascot),
      badge: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: c.incomeContainer, shape: BoxShape.circle),
        child: DsIdleMotion(child: Icon(Icons.eco, size: 11, color: c.income)),
      ),
      collapsedTitle: state.hasNoWallets
          ? const SizedBox.shrink()
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.spa_outlined, size: 14, color: c.actionPrimary),
                const SizedBox(width: 6),
                Text(
                  AppMoneyFormatter.format(state.totalBalance),
                  style: ds.typography.pixelLabel.copyWith(fontSize: 13, color: c.actionPrimary),
                ),
              ],
            ),
      actions: [
        // Menu tur (KO-4, ADR-021 §3.5).
        const TutorialInfoButton(tour: TourId.home),
        // Titik masuk layar Akun (ADR-023/024) -- identitas opsional, bukan
        // navigasi bawah karena bukan aktivitas harian.
        AccountAvatarButton(onPressed: () => context.pushRoute(AccountRouteKeys.page, const EmptyInput())),
      ],
    );
  }

  Widget _content(BuildContext context, HomeState state) {
    final budget = state.budget;
    final freelance = state.freelance;
    const hasPreview = kHomePlaceholderPreview;
    Widget gap([double h = DsSpacing.stack]) => SizedBox(height: h);
    // TR-HOME (ADR-021 §3.4): mulai begitu ada dompet. Kartu yang baru
    // muncul belakangan (arus, anggaran, Freelance, transaksi terbaru)
    // disorot sendiri saat pertama tampil -- progres dicatat per langkah.
    return TourTrigger(
      tour: TourId.home,
      ready: !state.hasNoWallets,
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(DsSpacing.md, DsSpacing.sm, DsSpacing.md, DsSpacing.xl + DsSpacing.sm),
        children: [
          // Tanpa tampilan (slide pembaruan dan lembar Apa yang baru).
          ?widget.updateHost,
          AccountUserBuilder(
            builder: (context, user) =>
                HomeGreeting(name: _firstName(user), jiggle: _claims, firstRun: !state.hasTransactions),
          ),
          // Urutan `patterns.md`: total saldo → yang perlu tindakan → bulan
          // ini → anggaran → freelance → transaksi terbaru.
          // Tanpa dompet, Beranda langsung ke langkah awal (`BerandaKosong`):
          // total Rp0 tidak memberi informasi (FR-HOME-005).
          if (!state.hasNoWallets) ...[
            gap(),
            SpotlightTarget(
              spotlightKey: SpotlightKey.homeBalance,
              child: HomeBalanceCard(
                total: state.totalBalance,
                walletCount: state.activeWallets.length,
                cashFlow: state.hasTransactions ? state.cashFlow : null,
                footer: widget.forecast,
              ),
            ),
          ],
          // Banner kotak masuk membawa jarak atasnya sendiri (kosong = tidak ada).
          ?widget.notice,
          ?widget.pendingRecurring,
          ?widget.featureNudge,
          // Perkiraan saldo akhir periode ada di kartu saldo (footer). Tanpa
          // kartu saldo (belum ada dompet) widget ini tetap dipasang tak
          // terlihat supaya slide Siapkan dana dan Oktober dimulai tetap
          // dilaporkan ke carousel status.
          if (state.hasNoWallets && widget.forecast != null) Offstage(child: widget.forecast),
          // Urutan: saldo → aksi cepat → satu carousel (status, wawasan) →
          // Freelance → transaksi terbaru.
          if (!state.hasNoWallets) ...[
            gap(),
            HomeQuickActions(
              onRecordTransfer: () => _thenRefresh(widget.onRecord),
              onOpenReport: () => unawaited(
                context.pushRoute(AnalysisRouteKeys.open, const AnalysisInput(source: AnalysisSource.home)),
              ),
              notificationAction: widget.notificationAction,
              onClaimed: () => setState(() => _claims++),
            ),
          ],
          // Keadaan awal: kartu misi tiga langkah, tepat di bawah sapaan (tanpa
          // dompet) atau di bawah aksi cepat (sudah ada dompet).
          if (!state.hasTransactions) ...[
            gap(),
            HomeFirstSteps(
              hasNoWallets: state.hasNoWallets,
              hasBudget: budget != null,
              onRecord: () => _thenRefresh(widget.onRecord),
              onAddWallet: widget.onShowWallets,
              onBudget: widget.onShowBudgets,
            ),
          ],
          // Slide status nyata tampil walau belum ada dompet (seperti kartu
          // lama); slide wawasan tiruan hanya bila ada dompet.
          if (widget.statusBoard != null || budget != null || (hasPreview && !state.hasNoWallets)) ...[
            gap(DsSpacing.lg),
            HomeCarouselSection(
              board: widget.statusBoard,
              budget: budget,
              onOpenBudget: widget.onShowBudgets,
            ),
          ],
          if (freelance != null) ...[
            gap(DsSpacing.lg),
            DsSectionHeader(
              title: t.home.freelanceTitle,
              icon: Icons.work_outline,
              actionLabel: t.home.seeAll,
              onAction: () => _thenRefresh(() => context.pushRoute(FreelanceRouteKeys.overview, const EmptyInput())),
            ),
            const SizedBox(height: DsSpacing.sm),
            SpotlightTarget(
              spotlightKey: SpotlightKey.homeFreelance,
              child: HomeFreelanceCard(
                overview: freelance,
                onOpen: () => _thenRefresh(() => context.pushRoute(FreelanceRouteKeys.overview, const EmptyInput())),
              ),
            ),
          ],
          gap(DsSpacing.lg),
          if (state.hasTransactions) ...[
            SpotlightTarget(
              spotlightKey: SpotlightKey.homeRecent,
              child: DsSectionHeader(
                title: t.home.recentTitle,
                icon: Icons.receipt_long,
                actionLabel: t.home.seeAll,
                onAction: widget.onShowTransactions,
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
            DsListCard(
              children: [
                for (final transaction in state.recentTransactions)
                  HomeRecentRow(
                    transaction: transaction,
                    walletsById: state.walletsById,
                    onTap: () => _thenRefresh(
                      () => context.pushRoute(TransactionRouteKeys.detail, TransactionDetailInput(transaction)),
                    ),
                  ),
              ],
            ),
            DsFootnote(text: t.home.footnote.toUpperCase()),
          ] else ...[
            DsSectionHeader(title: t.home.recentTitle, icon: Icons.receipt_long),
            const SizedBox(height: DsSpacing.sm),
            const HomeEmptyLedger(),
            DsFootnote(text: t.home.footnote.toUpperCase()),
          ],
        ],
      ),
    );
  }

  /// Nama depan dari nama tampilan akun; `null` bila belum masuk atau kosong.
  static String? _firstName(AppUser? user) {
    final name = user?.displayName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      DsErrorState(
        title: t.home.loadErrorTitle,
        retryLabel: t.common.retry,
        onRetry: onRetry,
        illustration: SvgPicture.asset(ClayIcons.warning, width: 40, height: 40),
      );
}
