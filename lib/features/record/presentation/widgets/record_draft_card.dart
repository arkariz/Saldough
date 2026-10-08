import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/capture/capture.dart';

/// Kartu di atas formulir CATAT yang terisi dari Catat Cerdas (ADR-027 §3.4):
/// teks yang tertangkap, dan hal yang perlu diperiksa sebelum menekan Catat.
class RecordDraftCard extends StatelessWidget {
  /// Membuat [RecordDraftCard] untuk [draft].
  const RecordDraftCard({required this.draft, super.key});

  /// Draf yang mengisi formulir.
  final RecordDraft draft;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (draft.issues.isNotEmpty) {
      return AppHardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.record.draftCheckTitle, style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.space1),
            for (final issue in DraftIssue.values)
              if (draft.issues.contains(issue))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppIcon(IconKey.info, size: 18),
                      const SizedBox(width: AppSpacing.space1),
                      Expanded(child: Text(draftIssueMessage(issue), style: textTheme.bodyMedium)),
                    ],
                  ),
                ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

/// Teks pengguna untuk [issue].
String draftIssueMessage(DraftIssue issue) => switch (issue) {
  DraftIssue.amountMissing => t.record.draftIssue.amountMissing,
  DraftIssue.amountMultiple => t.record.draftIssue.amountMultiple,
  DraftIssue.amountWithoutUnit => t.record.draftIssue.amountWithoutUnit,
  DraftIssue.amountAmbiguous => t.record.draftIssue.amountAmbiguous,
  DraftIssue.currencyUnsupported => t.record.draftIssue.currencyUnsupported,
  DraftIssue.walletUnknown => t.record.draftIssue.walletUnknown,
  DraftIssue.transferSourceMissing => t.record.draftIssue.transferSourceMissing,
  DraftIssue.transferTargetMissing => t.record.draftIssue.transferTargetMissing,
  DraftIssue.categoryUnknown => t.record.draftIssue.categoryUnknown,
  DraftIssue.dateUnclear => t.record.draftIssue.dateUnclear,
  DraftIssue.kindUnclear => t.record.draftIssue.kindUnclear,
};
