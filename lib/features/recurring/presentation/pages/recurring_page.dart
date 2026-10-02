import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/recurring/presentation/widgets/recurring_starter_chips.dart';

/// Segmen **Rutin** tab Rencana (PLAN_TAB_LAYOUT §6). Isi lengkapnya
/// (kartu utama, kelompok, baris) dikerjakan T-14.5; sementara ini chip
/// pembuka rutin.
class RecurringPage extends StatelessWidget {
  /// Membuat [RecurringPage].
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.fabClearance),
      children: const [AppHardCard(child: RecurringStarterChips())],
    );
  }
}
