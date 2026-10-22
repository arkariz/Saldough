import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/data_portability/presentation/widgets/export_sheet.dart';

/// Bagian **Data kamu** di layar Akun (prototipe `AkunData.dc.html`): ekspor,
/// cadangkan, pulihkan. Disisipkan akar komposisi ke Akun (ADR-030), bukan
/// diimpor Akun, sama dengan baris Versi aplikasi.
class AccountDataSection extends StatelessWidget {
  /// Membuat [AccountDataSection].
  const AccountDataSection({required this.container, super.key});

  /// Kontainer DI akar.
  final GetIt container;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
              onTap: () => showExportSheet(context, container),
            ),
          ],
        ),
      ],
    );
  }
}
