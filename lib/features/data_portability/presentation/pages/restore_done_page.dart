import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';

/// Halaman "Data dipulihkan dari cadangan {tanggal}." sesudah aplikasi dimulai
/// ulang (`Pulihkan.dc.html`, keadaan selesai). Dibuka shell sekali.
class RestoreDonePage extends StatelessWidget {
  /// Membuat [RestoreDonePage].
  const RestoreDonePage({required this.report, super.key});

  /// Keterangan pemulihan yang baru selesai.
  final RestoreReport report;

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
                    if (report.mayNeedPermissions) ...[
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
