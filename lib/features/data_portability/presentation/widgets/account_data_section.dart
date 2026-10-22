import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/data_portability/domain/backup_gateway.dart';
import 'package:saldough/features/data_portability/presentation/widgets/backup_sheet.dart';
import 'package:saldough/features/data_portability/presentation/widgets/export_sheet.dart';

/// Bagian **Data kamu** di layar Akun (prototipe `AkunData.dc.html`): ekspor,
/// cadangkan, pulihkan. Disisipkan akar komposisi ke Akun (ADR-030), bukan
/// diimpor Akun, sama dengan baris Versi aplikasi.
class AccountDataSection extends StatefulWidget {
  /// Membuat [AccountDataSection].
  const AccountDataSection({required this.container, super.key});

  /// Kontainer DI akar.
  final GetIt container;

  @override
  State<AccountDataSection> createState() => _AccountDataSectionState();
}

class _AccountDataSectionState extends State<AccountDataSection> {
  /// Kapan terakhir dicadangkan; `null` = belum pernah (atau belum terbaca).
  DateTime? _lastBackup;

  BackupGateway get _backup => widget.container<BackupGateway>();

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    final result = await _backup.lastBackupAt();
    if (!mounted) return;
    setState(() => _lastBackup = result.getOrElse((_) => null));
  }

  Future<void> _openBackup() async {
    await showBackupSheet(context, widget.container);
    await _loadLastBackup();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final last = _lastBackup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(t.dataPortability.sectionTitle),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space1, 0, AppSpacing.space1, AppSpacing.space2),
          child: Text(
            t.dataPortability.sectionBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink2),
          ),
        ),
        AppListCard(
          dividerIndent: AppListCard.iconIndent,
          children: [
            AppListRow(
              key: const ValueKey('data-export'),
              compact: true,
              leading: AppIcon(IconKey.tableView, color: colors.ink2),
              title: t.dataPortability.exportTitle,
              subtitle: t.dataPortability.exportSub,
              chevron: true,
              onTap: () => showExportSheet(context, widget.container),
            ),
            AppListRow(
              key: const ValueKey('data-backup'),
              compact: true,
              leading: AppIcon(IconKey.backup, color: colors.ink2),
              title: t.dataPortability.backupTitle,
              subtitle: last == null
                  ? t.dataPortability.backupNever
                  : t.dataPortability.backupLast(date: CycleMonthFormatter.formatDateShort(last)),
              chevron: true,
              onTap: _openBackup,
            ),
          ],
        ),
      ],
    );
  }
}
