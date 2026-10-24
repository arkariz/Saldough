import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';

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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
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
                  padding: const EdgeInsets.all(AppSpacing.space6),
                  children: [
                    const SizedBox(height: AppSpacing.space6),
                    Image.asset('assets/illustration/penutup.png', height: 156, excludeFromSemantics: true),
                    const SizedBox(height: AppSpacing.space4),
                    Text(title, textAlign: TextAlign.center, style: textTheme.headlineSmall),
                    if (_needsPermission) ...[
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        d.restoreDoneNote,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                      ),
                    ],
                  ],
                ),
              ),
              AppStickyBar(
                child: AppButton(
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
