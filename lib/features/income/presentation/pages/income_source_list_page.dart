import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/income/presentation/bloc/income_source_bloc.dart';
import 'package:saldough/features/income/presentation/bloc/income_source_state.dart';
import 'package:saldough/features/income/presentation/widgets/income_source_edit_sheet.dart';
import 'package:saldough/shared/income/income.dart';
import 'package:state_management/state_management.dart';

/// Layar pengelolaan sumber pemasukan (FR-INC-001 sampai FR-INC-003).
class IncomeSourceListPage extends StatelessWidget {
  /// Membuat [IncomeSourceListPage].
  const IncomeSourceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.income.pageTitle)),
      body: EffectListener<IncomeSourceBloc, IncomeSourceState>(
        child: BlocBuilder<IncomeSourceBloc, IncomeSourceState>(
          builder: (context, state) {
            if (state.isLoading && state.sources.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final bloc = context.read<IncomeSourceBloc>();
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AppButton(
                  label: t.income.worklogEntryPointLabel,
                  icon: Icons.access_time,
                  onPressed: () => bloc.add(const WorklogEntryPointTapped()),
                ),
                const SizedBox(height: AppSpacing.md),
                if (state.sources.isEmpty) Text(t.income.emptySources),
                for (final source in state.sources)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _IncomeSourceTile(source: source),
                  ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: t.income.addSourceTitle,
                  icon: Icons.add,
                  onPressed: () async {
                    final result = await IncomeSourceEditSheet.show(context);
                    if (result != null) bloc.add(IncomeSourceSaved(result));
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IncomeSourceTile extends StatelessWidget {
  const _IncomeSourceTile({required this.source});

  final IncomeSource source;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<IncomeSourceBloc>();
    final subtitle = switch (source.kind) {
      .fixedSalary => AppMoneyFormatter.format(source.fixedAmount ?? 0),
      .hourlyFreelance => t.income.hourlyRateSubtitle(rate: AppMoneyFormatter.format(source.hourlyRate ?? 0)),
      .adHoc => t.income.kindAdHoc,
    };
    return AppCard(
      child: InkWell(
        onTap: () async {
          final result = await IncomeSourceEditSheet.show(context, initial: source);
          if (result != null) bloc.add(IncomeSourceSaved(result));
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(source.name, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => bloc.add(IncomeSourceDeleted(source.id)),
            ),
          ],
        ),
      ),
    );
  }
}
