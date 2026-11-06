import 'dart:async';
import 'dart:typed_data';

import 'package:dependencies/dependencies.dart' hide State;
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/services/quick_start_apps.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/access_disclosure.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/plus_gate.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/source_app_tile.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wallet/wallet_presentation.dart';
import 'package:state_management/state_management.dart';

/// Paket aplikasi ini; tidak ditawarkan sebagai sumber notifikasi.
const _ownPackage = 'com.arkarizdev.tanukonomy';

/// Mulai cepat Catat dari notifikasi (FEATURE_DISCOVERY §5.1), tampilan v2:
/// semua aplikasi terpasang (tanpa daftar bank tertanam, ADR-044 §3.4), kartu
/// per aplikasi berikon asli, satu langkah izin akses, lalu selesai.
///
/// Sumber disimpan sebelum pengguna keluar ke setelan akses sistem, jadi
/// kembali (atau proses dimatikan sistem) tidak kehilangan pilihan; tombol
/// berubah menjadi **Izinkan** selama akses belum ada.
class QuickStartPage extends StatefulWidget {
  /// Membuat [QuickStartPage].
  const QuickStartPage({super.key});

  @override
  State<QuickStartPage> createState() => _QuickStartPageState();
}

class _QuickStartPageState extends State<QuickStartPage> with WidgetsBindingObserver {
  late Future<Either<Failure, List<InstalledApp>>> _apps = context.read<NotificationSettingsBloc>().loadInstalledApps();
  Set<String>? _selected;

  /// Dompet pilihan pengguna per paket (dipakai bila ada lebih dari satu dompet).
  final _walletOf = <String, String>{};
  bool _saved = false;
  bool _busy = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Kembali dari setelan akses sistem.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationSettingsBloc>().add(const NotificationSettingsResumed());
    }
  }

  /// Dompet bawaan sumber [packageName]: pilihan pengguna, atau satu-satunya
  /// dompet aktif. Dengan beberapa dompet dan belum dipilih: `null` (tidak
  /// menebak, jadi pengguna ditanya).
  String? _walletFor(String packageName, List<Wallet> wallets) {
    final chosen = _walletOf[packageName];
    if (chosen != null && wallets.any((w) => w.id == chosen)) return chosen;
    return wallets.length == 1 ? wallets.single.id : null;
  }

  Future<void> _turnOn(List<InstalledApp> candidates) async {
    if (_busy) return;
    final bloc = context.read<NotificationSettingsBloc>();
    if (!_saved) {
      setState(() => _busy = true);
      final wallets = bloc.state.wallets;
      final picked = [
        for (final app in candidates)
          if (_selected?.contains(app.packageName) ?? false)
            quickStartSource(app, walletId: _walletFor(app.packageName, wallets)),
      ];
      // Gratis: hanya satu aplikasi (ADR-041 §3.8); lebih dari itu membuka
      // paywall dan pengguna mengurangi pilihannya.
      if (exceedsFreeSources(picked.length - 1)) {
        setState(() => _busy = false);
        await openNotificationPaywall(context);
        return;
      }
      final result = await bloc.applyQuickStart(picked, askNotificationPermission: ActivePlan.isPlus);
      if (!mounted) return;
      setState(() => _busy = false);
      if (result == QuickStartResult.failed) {
        // Gagal menyimpan harus terlihat, bukan tombol yang diam saja.
        ScaffoldMessenger.of(context).showAppSnackBar(SnackBar(content: Text(t.common.genericErrorMessage)));
        return;
      }
      _saved = true;
      if (result == QuickStartResult.ready) {
        _completed(bloc);
        Navigator.of(context).pop(true);
        return;
      }
    }
    // Pengungkapan tampil tanpa indikator sibuk: dialog bukan pekerjaan latar.
    if (await showAccessDisclosure(context)) await bloc.openAccessSettings();
  }

  /// Mulai cepat selesai: fitur menyala lewat Mulai cepat (analitik).
  void _completed(NotificationSettingsBloc bloc) {
    AppAnalytics.log(DiscoveryEvents.quickStartCompleted(appsCount: bloc.quickStartAppsCount));
    AppAnalytics.log(DiscoveryEvents.featureEnabled(feature: 'notification', via: 'quick_start'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.discovery.quickStart.screenTitle, style: context.ds.typography.headlineMd),
        centerTitle: false,
      ),
      body: SafeArea(
        child: BlocListener<NotificationSettingsBloc, NotificationSettingsState>(
          listenWhen: (previous, current) => _saved && !previous.accessGranted && current.accessGranted,
          listener: (context, state) {
            _completed(context.read<NotificationSettingsBloc>());
            Navigator.of(context).pop(true);
          },
          child: FutureBuilder<Either<Failure, List<InstalledApp>>>(
            future: _apps,
            builder: (context, snapshot) {
              final result = snapshot.data;
              if (result == null) return const AppSkeletonPage();
              final candidates = quickStartApps(result.getOrElse((_) => const []), ownPackage: _ownPackage);
              _selected ??= <String>{};
              return BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
                builder: (context, state) => _content(context, state, candidates, failed: result.isLeft()),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    NotificationSettingsState state,
    List<InstalledApp> candidates, {
    required bool failed,
  }) {
    final texts = t.discovery.quickStart;
    final ds = context.ds;
    final c = ds.colors;
    final selected = _selected ?? const <String>{};
    final hasSource = state.settings.sources.any((source) => source.enabled);
    final wallets = state.wallets;
    // Dengan beberapa dompet, tiap aplikasi pilihan perlu dompet (tidak ditebak).
    final missingWallet = [
      for (final packageName in selected)
        if (_walletFor(packageName, wallets) == null && wallets.isNotEmpty) packageName,
    ];
    final canTurnOn = (selected.isNotEmpty && missingWallet.isEmpty) || (selected.isEmpty && hasSource);
    final needsAccess = _saved && !state.accessGranted;
    final shown = [
      for (final app in candidates)
        if (_query.isEmpty ||
            app.label.toLowerCase().contains(_query) ||
            app.packageName.toLowerCase().contains(_query))
          app,
    ];
    final hint = selected.isEmpty
        ? (hasSource ? texts.pickedCount(n: 0) : texts.pickHint)
        : (missingWallet.isEmpty ? texts.pickedCount(n: selected.length) : texts.walletHint);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              // Dua fase nyata: memilih aplikasi, lalu memberi izin akses. Tanpa
              // penunjuk bila izin sudah ada (hanya satu fase).
              if (!state.accessGranted) ...[
                _StepIndicator(step: _saved ? 2 : 1),
                const SizedBox(height: 16),
              ],
              Center(
                child: DsPill(label: texts.eyebrow.toUpperCase(), tone: DsPillTone.positive, dot: true),
              ),
              const SizedBox(height: 12),
              Text(texts.title, textAlign: TextAlign.center, style: ds.typography.headlineSm),
              const SizedBox(height: 6),
              Text(
                texts.body,
                textAlign: TextAlign.center,
                style: ds.typography.bodySm.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 16),
              DsSearchField(
                key: const ValueKey('quick-start-search'),
                query: _query,
                hint: t.notificationCapture.searchApps,
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
              ),
              const SizedBox(height: 10),
              // Tombol Nyalakan mati selama belum ada pilihan: katakan kenapa. Hitungan di
              // kiri, batas Gratis sebagai pil di kanan (acuan v2).
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      selected.isEmpty ? Icons.radio_button_unchecked_rounded : Icons.check_circle_rounded,
                      size: 16,
                      color: selected.isEmpty ? c.textMuted : c.actionPrimary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        hint,
                        key: const ValueKey('quick-start-hint'),
                        style: ds.typography.labelMd.copyWith(color: c.textSecondary, letterSpacing: 0),
                      ),
                    ),
                    if (!ActivePlan.isPlus) ...[
                      const SizedBox(width: 8),
                      DsPill(label: texts.freeLimit(n: ActivePlan.limits.value.freeNotificationSources)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (failed)
                DsErrorState(
                  title: t.notificationCapture.appsLoadFailed,
                  retryLabel: t.common.retry,
                  onRetry: () => setState(() {
                    _apps = context.read<NotificationSettingsBloc>().loadInstalledApps();
                  }),
                )
              else if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 32, color: c.textMuted),
                      const SizedBox(height: 8),
                      Text(
                        t.notificationCapture.appsEmpty,
                        textAlign: TextAlign.center,
                        style: ds.typography.bodyMd.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                for (final app in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AppCard(
                      app: app,
                      selected: selected.contains(app.packageName),
                      wallets: wallets,
                      walletId: _walletFor(app.packageName, wallets),
                      onToggle: (on) => _toggle(app.packageName, on: on),
                      onWallet: (id) => setState(() {
                        _walletOf[app.packageName] = id;
                        _saved = false;
                      }),
                    ),
                  ),
              if (!ActivePlan.isPlus && !failed) ...[
                const SizedBox(height: 6),
                DsCard(
                  child: Row(
                    children: [
                      DsIconTile.child(
                        tone: DsIconTileTone.warning,
                        size: DsIconTileSize.sm,
                        child: Icon(Icons.workspace_premium_outlined, size: 18, color: c.onWarningContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(texts.plusTeaser, style: ds.typography.titleMd.copyWith(fontSize: 14))),
                      const SizedBox(width: 8),
                      DsButton.compact(
                        label: texts.plusInfo,
                        onPressed: () => unawaited(openNotificationPaywall(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        DsStickyBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsButton(
                key: const ValueKey('quick-start-turn-on'),
                label: needsAccess ? t.discovery.allowAccess : texts.turnOn,
                expand: true,
                onPressed: canTurnOn && !_busy ? () => unawaited(_turnOn(candidates)) : null,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 14, color: c.textMuted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      texts.privacyLine,
                      textAlign: TextAlign.center,
                      style: ds.typography.bodySm.copyWith(color: c.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggle(String packageName, {required bool on}) => setState(() {
    final next = {...?_selected};
    on ? next.add(packageName) : next.remove(packageName);
    _selected = next;
    // Pilihan berubah sesudah tersimpan: simpan ulang saat Nyalakan.
    _saved = false;
  });
}

/// "Langkah n dari 2" dengan dua segmen kemajuan.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    Widget bar({required bool active}) => AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 28 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: active ? c.actionPrimary : c.surfaceContainerHighest,
        borderRadius: DsRadius.fullAll,
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DsPill(
          label: t.discovery.quickStart.stepLabel(n: step).toUpperCase(),
          tone: DsPillTone.positive,
          dot: true,
        ),
        Row(
          children: [
            bar(active: step == 1),
            const SizedBox(width: 4),
            bar(active: step == 2),
          ],
        ),
      ],
    );
  }
}

/// Kartu satu aplikasi: ikon asli, nama, paket, kotak centang; bila dicentang
/// dan ada beberapa dompet, pemilih dompet tujuan muncul di dalamnya.
class _AppCard extends StatelessWidget {
  const _AppCard({
    required this.app,
    required this.selected,
    required this.wallets,
    required this.walletId,
    required this.onToggle,
    required this.onWallet,
  });

  final InstalledApp app;
  final bool selected;
  final List<Wallet> wallets;
  final String? walletId;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onWallet;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final icon = app.icon;
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DsPressable(
            key: ValueKey('quick-start-${app.packageName}'),
            onPressed: () => onToggle(!selected),
            pressedScale: 0.995,
            dimWhenDisabled: false,
            builder: (context, _) => Row(
              children: [
                SourceAppTile(label: app.label, icon: icon == null ? null : Uint8List.fromList(icon), size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ds.typography.titleMd),
                      Text(
                        app.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: selected,
                  onChanged: (value) => onToggle(value ?? false),
                  shape: const RoundedRectangleBorder(borderRadius: DsRadius.baseAll),
                ),
              ],
            ),
          ),
          // Banyak dompet: tiap aplikasi pilihan ditanya dompetnya.
          if (selected && wallets.length > 1) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.baseAll),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.discovery.quickStart.walletTarget,
                          style: ds.typography.labelMd.copyWith(color: c.textSecondary, letterSpacing: 0),
                        ),
                      ),
                      Icon(Icons.lock_outline_rounded, size: 14, color: c.actionPrimary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  WalletSelectField(
                    key: ValueKey('quick-start-wallet-${app.packageName}'),
                    label: t.notificationCapture.walletLabel,
                    wallets: wallets,
                    selectedId: walletId,
                    useDs: true,
                    onSelected: onWallet,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.discovery.quickStart.walletNote,
                    style: ds.typography.bodySm.copyWith(color: c.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
