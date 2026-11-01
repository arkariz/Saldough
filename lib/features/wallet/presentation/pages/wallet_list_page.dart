import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/features/wallet/presentation/navigation/wallet_route_keys.dart';
import 'package:saldough/features/wallet/presentation/wallet_shares.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_empty_states.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_form_sheet.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_hero_card.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_reorder_sheet.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_spread_card.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Layar Dompet (T-2.7; FR-WAL-001..003): total saldo dompet aktif, daftar
/// dompet dengan saldo tercatatnya, tambah dompet, serta dompet nonaktif di
/// bagian tersendiri.
///
/// `WalletBloc` dipasang di level shell (bukan di halaman ini) karena tab
/// persisten selama shell hidup (`IndexedStack` membangun seluruh tab sekali).
/// Halaman memuat dompet sekali saat dibuat; saldo disegarkan tiap tab ini
/// dibuka serta sesudah alur CATAT (lihat `AppShellPage`).
///
/// Mengetuk kartu dompet membuka [WalletDetailPage] (T-2.8) -- rincian
/// dompet, riwayat tersaring bulan berjalan, sunting/hapus, dan pintasan
/// CATAT. Formulir sunting tidak lagi dibuka langsung dari sini.
class WalletListPage extends StatefulWidget {
  /// Membuat [WalletListPage].
  const WalletListPage({super.key});

  @override
  State<WalletListPage> createState() => _WalletListPageState();
}

class _WalletListPageState extends State<WalletListPage> {
  /// Dompet yang dipilih di donat Sebaran saldo; barisnya ditandai di daftar.
  /// Tidak disimpan: meninggalkan layar mengembalikan kartu ke ringkas.
  String? _linked;

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(const WalletStarted());
  }

  /// Membuka formulir TAMBAH dompet baru. Sunting/hapus dompet yang sudah
  /// ada pindah ke [WalletDetailPage] (T-2.8) -- kartu dompet membuka layar
  /// rincian, bukan langsung formulir sunting.
  Future<void> _addWallet(BuildContext context) => openAddWalletSheet(context);

  /// Membuka lembar Urutkan dompet (B-34). Dompet nonaktif tetap di belakang
  /// dompet aktif dengan urutan relatifnya.
  Future<void> _reorderWallets(BuildContext context, WalletState state) async {
    final bloc = context.read<WalletBloc>();
    final ordered = await showFullScreenSheet<List<String>>(
      context,
      builder: (_) => WalletReorderSheet(wallets: state.activeWallets),
    );
    if (ordered == null) return;
    bloc.add(WalletsReordered([...ordered, for (final w in state.inactiveWallets) w.id]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.appShell.walletsTabLabel, style: context.ds.typography.headlineMd),
        centerTitle: false,
        actions: [
          const TutorialInfoButton(tour: TourId.wallet),
          DsIconButton(icon: Icons.add, label: t.wallet.addAction, onPressed: () => _addWallet(context)),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            if (state.isLoading) return const AppSkeletonPage();
            if (state.loadFailed) {
              return WalletLoadErrorState(
                onRetry: () =>
                    context.read<WalletBloc>().add(const WalletStarted()),
              );
            }
            if (state.wallets.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                children: [WalletEmptyState(onAdd: () => _addWallet(context))],
              );
            }

            final active = state.activeWallets;
            final inactive = state.inactiveWallets;
            final shares = walletShares(active);
            final multi = active.length > 1;
            final walletColorMap = walletColorsDs(context.ds.colors, active);
            final linked = multi ? _linked : null;
            // TR-WALLET (ADR-021 §3.4): ringkasan, dompet pertama, tambah.
            return TourTrigger(
              tour: TourId.wallet,
              ready: true,
              child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space2,
                AppSpacing.space4,
                AppSpacing.space12,
              ),
              children: [
                // Dompet v2 (ADR-043): hero total saldo, kartu Sebaran saldo
                // bila dompetnya dua atau lebih, lalu grid bento dompet.
                SpotlightTarget(
                  spotlightKey: SpotlightKey.walletSummary,
                  child: WalletHeroCard(total: state.totalBalance, activeCount: active.length),
                ),
                if (multi && shares.length > 1) ...[
                  const SizedBox(height: AppSpacing.space4),
                  WalletSpreadCard(
                    wallets: active,
                    shares: shares,
                    colors: walletColorMap,
                    total: state.totalBalance,
                    activeCount: active.length,
                    onSelected: (id) => setState(() => _linked = id),
                  ),
                ],
                const SizedBox(height: AppSpacing.space4),
                _WalletsHeader(
                  count: active.length,
                  onReorder: multi ? () => _reorderWallets(context, state) : null,
                ),
                const SizedBox(height: AppSpacing.space2),
                _WalletGrid(
                  wallets: active,
                  shares: multi ? shares : const {},
                  colors: multi ? walletColorMap : const {},
                  linked: linked,
                ),
                if (inactive.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  DsFieldGroup(
                    children: [
                      DsFieldRow(
                        key: const ValueKey('wallet-inactive-row'),
                        icon: Icons.inventory_2_outlined,
                        label: t.wallet.inactiveHeading,
                        title: t.wallet.inactiveRowSub(n: inactive.length),
                        chevron: true,
                        onTap: () => context.pushRoute(WalletRouteKeys.inactive, const EmptyInput()),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.space6),
                SpotlightTarget(
                  spotlightKey: SpotlightKey.walletAdd,
                  child: _AddSlot(label: t.wallet.addAction, onTap: () => _addWallet(context)),
                ),
              ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Membuka formulir TAMBAH dompet dan, kalau disimpan, menunggu sampai
/// [WalletBloc] selesai memproses simpanannya. Dipakai tab Dompet dan ajakan
/// "Buat Dompet Pertama" onboarding (ADR-021 §3.2) -- satu formulir yang sama,
/// bukan formulir baru. [context] harus berada di bawah `BlocProvider<WalletBloc>`.
Future<void> openAddWalletSheet(BuildContext context) async {
  final bloc = context.read<WalletBloc>();
  final result = await showFullScreenSheet<WalletFormResult>(
    context,
    builder: (_) => const WalletFormSheet(),
  );
  if (result case WalletFormSaved(
    :final name,
    :final iconKey,
    :final balance,
  )) {
    final processed = bloc.stream.first;
    bloc.add(
      WalletAdded(
        name: name,
        iconKey: iconKey,
        initialBalance: balance ?? 0,
      ),
    );
    await processed;
  }
}

/// Grid bento dompet: dompet pertama selebar penuh, sisanya dua kolom.
class _WalletGrid extends StatelessWidget {
  const _WalletGrid({required this.wallets, required this.shares, required this.colors, required this.linked});

  final List<Wallet> wallets;
  final Map<String, WalletShare> shares;
  final Map<String, Color> colors;
  final String? linked;

  @override
  Widget build(BuildContext context) {
    Widget card(Wallet wallet, int index, {bool wide = false}) => SpotlightTarget(
      // Hanya dompet pertama yang disorot.
      spotlightKey: index == 0 ? SpotlightKey.walletCard : null,
      child: WalletBentoCard(
        wallet: wallet,
        wide: wide,
        shareText: shares[wallet.id]?.text,
        swatchColor: colors[wallet.id],
        linked: linked == wallet.id,
        onTap: () => context.pushRoute(WalletRouteKeys.detail, WalletDetailInput(wallet)),
      ),
    );
    final rest = wallets.skip(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card(wallets.first, 0, wide: true),
        for (var i = 0; i < rest.length; i += 2) ...[
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card(rest[i], i + 1)),
                const SizedBox(width: 12),
                Expanded(child: i + 1 < rest.length ? card(rest[i + 1], i + 2) : const SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Kartu putus-putus "Tambah dompet" di bawah grid.
class _AddSlot extends StatelessWidget {
  const _AddSlot({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DsPressable(
      onPressed: onTap,
      semanticLabel: label,
      dimWhenDisabled: false,
      builder: (context, _) => CustomPaint(
        painter: _DashedBorderPainter(color: c.outline, radius: 24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: c.actionPrimary, shape: BoxShape.circle),
                child: Icon(Icons.add, color: c.onActionPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: ds.typography.titleMd)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Kepala daftar dompet (acuan Dompet v2): judul "Dompet aktif" dengan
/// lencana jumlah, keterangan satu baris, dan tombol Atur di kanan bila
/// dompetnya dua atau lebih.
class _WalletsHeader extends StatelessWidget {
  const _WalletsHeader({required this.count, required this.onReorder});

  final int count;
  final VoidCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Semantics(
                    header: true,
                    child: Text(t.wallet.listHeading, style: ds.typography.headlineSm),
                  ),
                  DsBadge(label: '$count', tone: DsBadgeTone.neutral),
                ],
              ),
              const SizedBox(height: 2),
              Text(t.wallet.listSubtitle, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
        if (onReorder != null) ...[
          const SizedBox(width: 8),
          DsButton.secondary(
            key: const ValueKey('wallet-reorder'),
            label: t.wallet.reorderAction,
            icon: Icons.tune,
            onPressed: onReorder,
          ),
        ],
      ],
    );
  }
}
