import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/account/presentation/widgets/setting_row.dart';

/// Baris setelan fitur dengan status Nyala / Mati / Izin belum diberikan di
/// layar Akun (FEATURE_DISCOVERY §7.1). Status dibaca dari [FeatureStatuses]
/// dan dibaca ulang saat setelan berubah, aplikasi kembali ke depan (izin
/// bisa dicabut di sistem), dan layar tujuan ditutup. Tanpa [FeatureStatuses]
/// (uji, kontainer minimal) baris tampil tanpa status.
class FeatureStatusSettingRow extends StatefulWidget {
  /// Membuat [FeatureStatusSettingRow].
  const FeatureStatusSettingRow({
    required this.feature,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  /// Fitur yang statusnya ditampilkan.
  final DiscoveredFeature feature;

  /// Ikon baris.
  final IconKey icon;

  /// Judul baris.
  final String title;

  /// Keterangan bawaan; diganti jumlah aplikasi aktif bila fiturnya Catat
  /// dari notifikasi dan ada aplikasi aktif.
  final String subtitle;

  /// Membuka layar setelan; selesai (layar ditutup) memicu baca ulang.
  final Future<void> Function() onTap;

  @override
  State<FeatureStatusSettingRow> createState() => _FeatureStatusSettingRowState();
}

class _FeatureStatusSettingRowState extends State<FeatureStatusSettingRow> with WidgetsBindingObserver {
  FeatureStatuses? _statuses;
  StreamSubscription<void>? _changes;
  FeatureStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_statuses != null) return;
    final container = ScopeProvider.of(context);
    if (!container.isRegistered<FeatureStatuses>()) return;
    _statuses = container<FeatureStatuses>();
    _changes = _statuses!.changes.listen((_) => unawaited(_load()));
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_changes?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_load());
  }

  Future<void> _load() async {
    final statuses = _statuses;
    if (statuses == null) return;
    final status = await statuses.read(widget.feature);
    if (mounted && status != _status) setState(() => _status = status);
  }

  Future<void> _open() async {
    await widget.onTap();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final texts = t.discovery;
    final badge = switch (status?.state) {
      null || FeatureState.unsupported => null,
      FeatureState.active => AppBadge(texts.status.on, tone: AppTone.positive),
      FeatureState.permissionNeeded => AppBadge(
        texts.status.permissionNeeded,
        tone: AppTone.warning,
        icon: IconKey.warning,
      ),
      FeatureState.off || FeatureState.unset => AppBadge(texts.status.off),
    };
    final count = status?.activeCount ?? 0;
    final subtitle = widget.feature == DiscoveredFeature.notification && count > 0
        ? texts.notification.activeApps(n: count)
        : widget.subtitle;
    return SettingRow(
      key: ValueKey('feature-status-${widget.feature.name}'),
      icon: widget.icon,
      title: widget.title,
      subtitle: subtitle,
      badge: badge,
      onTap: () => unawaited(_open()),
    );
  }
}
