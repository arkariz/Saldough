import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/data_portability/domain/export_gateway.dart';
import 'package:saldough/features/data_portability/domain/export_models.dart';
import 'package:saldough/features/data_portability/domain/file_transfer.dart';
import 'package:saldough/features/data_portability/presentation/bloc/export_bloc.dart';
import 'package:saldough/features/data_portability/presentation/bloc/export_state.dart';
import 'package:state_management/state_management.dart';

/// Membuka lembar **Ekspor ke spreadsheet** (prototipe `LembarEkspor.dc.html`).
/// [container] adalah kontainer DI akar; fitur tidak membuat scope sendiri
/// karena layanannya tanpa state.
Future<void> showExportSheet(BuildContext context, GetIt container) => showAppSheet<void>(
  context,
  isScrollControlled: true,
  shape: fullScreenSheetShape,
  builder: (_) => BlocProvider(
    create: (_) =>
        ExportBloc(service: container<ExportGateway>(), transfer: container<FileTransfer>())
          ..add(const ExportStarted()),
    child: const EffectListener<ExportBloc, ExportState>(child: ExportSheet()),
  ),
);

/// Isi lembar ekspor: format → ringkasan → Ekspor, lalu proses (bisa batal),
/// lalu berkas siap dengan Simpan ke… dan Bagikan.
class ExportSheet extends StatelessWidget {
  /// Membuat [ExportSheet].
  const ExportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExportBloc, ExportState>(
      listenWhen: (previous, current) => !previous.finished && current.finished,
      listener: (context, _) => Navigator.of(context).maybePop(),
      builder: (context, state) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space4,
          AppSpacing.space4,
          AppSpacing.space4 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFormHeader(title: t.dataPortability.exportTitle),
            const SizedBox(height: AppSpacing.space4),
            switch (state.phase) {
              ExportPhase.loading => const _Loading(),
              ExportPhase.form || ExportPhase.empty => _Form(state: state),
              ExportPhase.busy => const _Busy(),
              ExportPhase.ready => _Ready(state: state),
            },
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
    child: Center(
      child: AppSpin(child: AppIcon(IconKey.progressActivity, color: context.appColors.ink2)),
    ),
  );
}

class _Form extends StatelessWidget {
  const _Form({required this.state});

  final ExportState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final empty = state.phase == ExportPhase.empty;
    final preview = state.preview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.dataPortability.exportFormat, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.space2),
        AppSegmentedControl<ExportFormat>(
          options: [
            (ExportFormat.xlsx, t.dataPortability.formatXlsx),
            (ExportFormat.csv, t.dataPortability.formatCsv),
          ],
          selected: state.format,
          onChanged: (format) => context.read<ExportBloc>().add(ExportFormatChanged(format)),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          state.format == ExportFormat.xlsx ? t.dataPortability.xlsxHelp : t.dataPortability.csvHelp,
          style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
        ),
        const SizedBox(height: AppSpacing.space4),
        Semantics(
          liveRegion: true,
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: Row(
                children: [
                  AppIcon(empty ? IconKey.eventBusy : IconKey.tableView, color: colors.ink2),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      empty || preview == null ? t.dataPortability.exportEmpty : _summary(preview),
                      style: textTheme.bodyMedium?.copyWith(color: empty ? colors.ink2 : colors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!empty) ...[
          const SizedBox(height: AppSpacing.space3),
          _Note(t.dataPortability.exportScope),
        ],
        const SizedBox(height: AppSpacing.space4),
        AppButton(
          key: const ValueKey('export-go'),
          label: t.dataPortability.exportAction,
          expand: true,
          onPressed: empty ? null : () => context.read<ExportBloc>().add(const ExportRequested()),
        ),
      ],
    );
  }

  /// "142 transaksi, 3 Jun – 22 Okt 2026": tahun awal dihilangkan bila sama.
  static String _summary(ExportPreview preview) {
    final first = preview.firstDate!;
    final last = preview.lastDate!;
    final lastText = CycleMonthFormatter.noBreak(CycleMonthFormatter.formatDateShort(last));
    // Semua transaksi di satu hari: satu tanggal saja, bukan "22 Okt – 22 Okt".
    if (first.year == last.year && first.month == last.month && first.day == last.day) {
      return t.dataPortability.exportSummaryDay(n: preview.count, date: lastText);
    }
    final firstText = first.year == last.year
        ? CycleMonthFormatter.formatDayMonth(first)
        : CycleMonthFormatter.formatDateShort(first);
    return t.dataPortability.exportSummary(
      n: preview.count,
      first: CycleMonthFormatter.noBreak(firstText),
      last: lastText,
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              AppSpin(child: AppIcon(IconKey.progressActivity, color: colors.brand)),
              const SizedBox(width: AppSpacing.space3),
              Expanded(child: Text(t.dataPortability.exportBusy, style: Theme.of(context).textTheme.titleMedium)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        _Note(t.dataPortability.exportBusyNote),
        const SizedBox(height: AppSpacing.space4),
        AppButton.text(
          key: const ValueKey('export-cancel'),
          label: t.dataPortability.cancel,
          expand: true,
          onPressed: () => context.read<ExportBloc>().add(const ExportCancelRequested()),
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.state});

  final ExportState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final file = state.file!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.brandSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: AppIcon(IconKey.checkCircle, color: colors.brandInk, size: 32),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(t.dataPortability.fileReady, textAlign: TextAlign.center, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.space4),
        AppCard(
          child: Row(
            children: [
              const AppIconTile(IconKey.description),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(file.name, style: textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(
                      t.dataPortability.fileMeta(
                        n: file.rowCount,
                        format: file.format == ExportFormat.xlsx ? 'Excel' : 'CSV',
                      ),
                      style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (state.notSaved) ...[
          const SizedBox(height: AppSpacing.space3),
          Semantics(liveRegion: true, child: _Note(t.dataPortability.fileNotSaved)),
        ],
        const SizedBox(height: AppSpacing.space4),
        AppButton(
          key: const ValueKey('export-save'),
          label: t.dataPortability.saveTo,
          expand: true,
          onPressed: () => context.read<ExportBloc>().add(const ExportSaveRequested()),
        ),
        const SizedBox(height: AppSpacing.space2),
        AppButton.secondary(
          key: const ValueKey('export-share'),
          label: t.dataPortability.share,
          expand: true,
          onPressed: () => context.read<ExportBloc>().add(const ExportShareRequested()),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(IconKey.info, color: colors.ink2, size: 18),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink2)),
        ),
      ],
    );
  }
}
