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
      appBar: AppBar(
        title: Text(t.income.pageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time),
            tooltip: t.income.worklogEntryPointLabel,
            onPressed: () => context.read<IncomeSourceBloc>().add(const WorklogEntryPointTapped()),
          ),
        ],
      ),
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
                if (state.sources.isEmpty) Text(t.income.emptySources),
                for (final source in state.sources)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _IncomeSourceTile(
                      source: source,
                      openBookHours: state.openBookHours[source.id],
                    ),
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
  const _IncomeSourceTile({required this.source, this.openBookHours});

  final IncomeSource source;

  /// Jumlah jam buku TERBUKA sumber ini, atau `null` kalau belum ada buku
  /// terbuka. Selalu `null` untuk sumber bukan freelance.
  final int? openBookHours;

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
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
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
                  onPressed: () async {
                    final confirmed = await showConfirmDelete(
                      context,
                      title: t.income.confirmDeleteSourceTitle(name: source.name),
                      message: t.income.confirmDeleteSourceMessage,
                    );
                    if (confirmed) bloc.add(IncomeSourceDeleted(source.id));
                  },
                ),
              ],
            ),
            // Laporan pemilik: sebelumnya satu-satunya jalan ke Catatan Jam
            // Kerja adalah ikon tanpa label di app bar, terlepas dari
            // daftar sumber -- tiap sumber freelance sekarang menampilkan
            // ringkasan buku berjalannya sendiri di sini, dengan tombol
            // yang langsung memilihnya di layar itu (bukan selalu lompat
            // ke sumber freelance pertama).
            if (source.kind == .hourlyFreelance) ...[
              const Divider(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      openBookHours == null
                          ? t.income.noOpenBook
                          : t.income.openBookSummary(hours: openBookHours!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => bloc.add(WorklogEntryPointTapped(sourceId: source.id)),
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(t.income.logHoursButton),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
