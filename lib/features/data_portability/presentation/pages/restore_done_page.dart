import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';
import 'package:saldough/features/data_portability/presentation/widgets/sheet_parts.dart';

/// Halaman "Data dipulihkan dari cadangan {tanggal}." sesudah aplikasi dimulai
/// ulang (`Pulihkan.dc.html`, keadaan selesai). Dibuka shell sekali.
///
/// Catatan izin hanya tampil bila cadangan memuat Catat dari notifikasi atau
/// pengingat DAN izin sistemnya memang belum ada di ponsel ini (dibaca dari
/// [statuses]); tanpa [statuses] catatan tidak tampil.
class RestoreDonePage extends StatefulWidget {
  /// Membuat [RestoreDonePage].
  const RestoreDonePage({required this.report, this.statuses, super.key});

  /// Keterangan pemulihan yang baru selesai.
  final RestoreReport report;

  /// Keadaan fitur di ponsel ini; `null` = tidak diperiksa.
  final FeatureStatuses? statuses;

  @override
  State<RestoreDonePage> createState() => _RestoreDonePageState();
}

class _RestoreDonePageState extends State<RestoreDonePage> {
  bool _needsPermission = false;

  RestoreReport get report => widget.report;

  @override
  void initState() {
    super.initState();
    if (report.mayNeedPermissions && widget.statuses != null) unawaited(_check(widget.statuses!));
  }

  Future<void> _check(FeatureStatuses statuses) async {
    final states = [
      for (final feature in DiscoveredFeature.values) (await statuses.read(feature)).state,
    ];
    if (mounted && states.contains(FeatureState.permissionNeeded)) setState(() => _needsPermission = true);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final reduced = DsMotion.reduced(context);
    final d = t.dataPortability;
    final date = report.backupCreatedAt;
    final title = report.kind == RestoreKind.undo || date == null
        ? d.undoDoneTitle
        : d.restoreDoneTitle(date: CycleMonthFormatter.formatDateShort(date));
    return PopScope(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 24),
                    Center(child: _Mascot(animate: !reduced)),
                    const SizedBox(height: 24),
                    Text(title, textAlign: TextAlign.center, style: ds.typography.headlineMd),
                    if (_needsPermission) ...[
                      const SizedBox(height: 16),
                      SheetNotice(message: d.restoreDoneNote),
                    ],
                  ],
                ),
              ),
              DsStickyBar(
                child: DsButton(
                  key: const ValueKey('restore-home'),
                  label: d.goHome,
                  expand: true,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Maskot clay di lingkaran cahaya: membal masuk, lalu diam.
class _Mascot extends StatelessWidget {
  const _Mascot({required this.animate});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final mascot = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [c.actionPrimary.withValues(alpha: 0.18), c.actionPrimary.withValues(alpha: 0)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SvgPicture.asset(ClayIcons.mascot, width: 132, height: 132, excludeFromSemantics: true),
      ),
    );
    if (!animate) return mascot;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: mascot,
    );
  }
}
