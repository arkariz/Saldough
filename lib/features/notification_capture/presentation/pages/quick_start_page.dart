import 'dart:async';
import 'dart:typed_data';

import 'package:dependencies/dependencies.dart' hide State;
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/services/quick_start_apps.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/access_disclosure.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/plus_gate.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Paket aplikasi ini; tidak ditawarkan sebagai sumber notifikasi.
const _ownPackage = 'com.arkarizdev.tanukonomy';

/// Mulai cepat Catat dari notifikasi (FEATURE_DISCOVERY §5.1): daftar pendek
/// aplikasi terpasang yang punya pola bawaan (tercentang), satu langkah izin
/// akses, lalu selesai. Aplikasi lain membuka pemilih yang sudah ada.
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.common.genericErrorMessage)));
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
      appBar: AppBar(),
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
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
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
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.space4),
            children: [
              // Ilustrasi Mulai cepat (assets/illustration/mulai_cepat.png).
              ExcludeSemantics(
                child: Image.asset(
                  'assets/illustration/mulai_cepat.png',
                  height: 140,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(texts.title, style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.space2),
              Text(texts.body, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.space4),
              TextField(
                key: const ValueKey('quick-start-search'),
                decoration: InputDecoration(
                  hintText: t.notificationCapture.searchApps,
                  prefixIcon: const AppIcon(IconKey.search),
                ),
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
              ),
              const SizedBox(height: AppSpacing.space2),
              // Tombol Nyalakan mati selama belum ada pilihan: katakan kenapa.
              Text(
                key: const ValueKey('quick-start-hint'),
                selected.isEmpty
                    ? (hasSource ? texts.pickedCount(n: 0) : texts.pickHint)
                    : (missingWallet.isEmpty ? texts.pickedCount(n: selected.length) : texts.walletHint),
                style: textTheme.bodySmall?.copyWith(color: colors.ink2),
              ),
              if (!ActivePlan.isPlus) Text(texts.freeLimit, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
              const SizedBox(height: AppSpacing.space3),
              if (failed)
                Column(
                  children: [
                    Text(t.notificationCapture.appsLoadFailed, textAlign: TextAlign.center),
                    AppButton.text(
                      key: const ValueKey('quick-start-retry'),
                      label: t.common.retry,
                      onPressed: () => setState(() {
                        _apps = context.read<NotificationSettingsBloc>().loadInstalledApps();
                      }),
                    ),
                  ],
                )
              else if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.space6),
                  child: Text(t.notificationCapture.appsEmpty, textAlign: TextAlign.center),
                )
              else
                AppListCard(
                  children: [
                    for (final app in shown) ...[
                      AppListRow(
                        key: ValueKey('quick-start-${app.packageName}'),
                        leading: _icon(app),
                        title: app.label,
                        subtitle: app.packageName,
                        trailing: Checkbox(
                          value: selected.contains(app.packageName),
                          onChanged: (value) => _toggle(app.packageName, on: value ?? false),
                        ),
                        onTap: () => _toggle(app.packageName, on: !selected.contains(app.packageName)),
                      ),
                      // Banyak dompet: tiap aplikasi pilihan ditanya dompetnya.
                      if (selected.contains(app.packageName) && wallets.length > 1) _walletPicker(app, wallets),
                    ],
                  ],
                ),
            ],
          ),
        ),
        AppStickyBar(
          child: AppButton(
            key: const ValueKey('quick-start-turn-on'),
            label: needsAccess ? t.discovery.allowAccess : texts.turnOn,
            expand: true,
            loading: _busy,
            onPressed: canTurnOn ? () => unawaited(_turnOn(candidates)) : null,
          ),
        ),
      ],
    );
  }

  Widget _walletPicker(InstalledApp app, List<Wallet> wallets) {
    final chosen = _walletFor(app.packageName, wallets);
    final wallet = wallets.where((w) => w.id == chosen).firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.space4, 0, AppSpacing.space4, AppSpacing.space3),
      child: AppMenuSelectButton<String>(
        key: ValueKey('quick-start-wallet-${app.packageName}'),
        icon: wallet == null ? IconKey.wallets : walletIconKey(wallet.iconKey),
        label: wallet?.name ?? t.notificationCapture.walletLabel,
        isPlaceholder: wallet == null,
        wrapLabel: true,
        options: [for (final w in wallets) (value: w.id, label: w.name, icon: walletIconKey(w.iconKey))],
        onSelected: (id) => setState(() {
          if (id != null) _walletOf[app.packageName] = id;
          _saved = false;
        }),
      ),
    );
  }

  void _toggle(String packageName, {required bool on}) => setState(() {
    final next = {...?_selected};
    on ? next.add(packageName) : next.remove(packageName);
    _selected = next;
    // Pilihan berubah sesudah tersimpan: simpan ulang saat Nyalakan.
    _saved = false;
  });

  Widget _icon(InstalledApp app) {
    final icon = app.icon;
    return icon == null
        ? const AppIconTile(IconKey.walletEwallet)
        : Image.memory(Uint8List.fromList(icon), width: AppSize.tile, height: AppSize.tile);
  }
}
