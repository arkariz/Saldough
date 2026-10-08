import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/recurring/domain/recurring_starters.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Chip pembuka rutin (J1, T-15.3). Ketuk → CATAT mode jadwal dengan jenis,
/// kategori, catatan, tanggal lazim, dan Ulangi sudah terisi; pengguna cukup
/// mengisi nominal dan dompet. Chip yang sudah punya rutin bernama sama
/// bertanda centang.
class RecurringStarterChips extends StatelessWidget {
  /// Membuat [RecurringStarterChips].
  const RecurringStarterChips({this.existingNames = const {}, this.now = DateTime.now, super.key});

  /// Nama (catatan) rutin yang sudah ada, huruf kecil.
  final Set<String> existingNames;

  /// Jam untuk tanggal bawaan; diganti di uji.
  final DateTime Function() now;

  /// Label chip [starter].
  static String labelOf(RecurringStarter starter) => switch (starter) {
    RecurringStarter.salary => t.recurring.starters.salary,
    RecurringStarter.rent => t.recurring.starters.rent,
    RecurringStarter.electricity => t.recurring.starters.electricity,
    RecurringStarter.internet => t.recurring.starters.internet,
    RecurringStarter.bpjs => t.recurring.starters.bpjs,
    RecurringStarter.installment => t.recurring.starters.installment,
    RecurringStarter.paylater => t.recurring.starters.paylater,
    RecurringStarter.subscription => t.recurring.starters.subscription,
    RecurringStarter.parents => t.recurring.starters.parents,
    RecurringStarter.arisan => t.recurring.starters.arisan,
    RecurringStarter.savings => t.recurring.starters.savings,
  };

  /// Input CATAT untuk [starter] per [today].
  static RecordSheetInput inputFor(RecurringStarter starter, DateTime today) => RecordSheetInput(
    initialChoice: switch (starter.kind) {
      RecurringKind.income => RecordChoice.income,
      RecurringKind.expense => RecordChoice.expense,
      RecurringKind.transfer => RecordChoice.transfer,
    },
    draft: RecordDraft(
      kind: switch (starter.kind) {
        RecurringKind.income => DraftKind.income,
        RecurringKind.expense => DraftKind.expense,
        RecurringKind.transfer => DraftKind.transfer,
      },
      categoryId: starter.categoryId,
      note: labelOf(starter),
      date: starter.dateFrom(today),
    ),
    repeat: starter.pattern,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Wrap(
      spacing: AppSpacing.space1,
      runSpacing: AppSpacing.space1,
      children: [
        for (final starter in RecurringStarter.values)
          if (existingNames.contains(labelOf(starter).toLowerCase()))
            AppQuickChip(
              label: '✓ ${labelOf(starter)}',
              color: colors.tinted(colors.positive, 0.2),
              onTap: () => context.pushRoute(RecordRouteKeys.sheet, inputFor(starter, now())),
            )
          else
            AppQuickChip(
              label: labelOf(starter),
              onTap: () => context.pushRoute(RecordRouteKeys.sheet, inputFor(starter, now())),
            ),
      ],
    );
  }
}
