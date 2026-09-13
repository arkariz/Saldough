import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/worklog/domain/entities/billing_book.dart';
import 'package:saldough/features/worklog/domain/entities/work_log_entry.dart';
import 'package:saldough/features/worklog/presentation/bloc/worklog_bloc.dart';
import 'package:saldough/features/worklog/presentation/bloc/worklog_state.dart';
import 'package:saldough/shared/income/income.dart';
import 'package:state_management/state_management.dart';

/// Layar catatan jam kerja dan buku jam — FR-TIME-001 sampai FR-TIME-004.
///
/// Laporan pemilik: alur sumber freelance → catat jam → tutup buku →
/// suntik ke siklus terasa membingungkan. Tiga perubahan utama di layar ini
/// menjawabnya: (1) "mulai buku baru" bukan lagi sakelar tersembunyi --
/// buku baru hanya dimulai otomatis begitu tidak ada buku terbuka, jadi
/// cukup tutup buku lama dulu; (2) menutup buku LANGSUNG menawarkan
/// penyuntikan lewat dialog, bukan menyuruh mencarinya di riwayat; (3)
/// rincian gaji kotor/potongan/bersih tampil permanen (perkiraan sebelum
/// ditutup, rincian sungguhan sesudahnya), bukan cuma lewat di snackbar.
class WorklogPage extends StatelessWidget {
  /// Membuat [WorklogPage].
  const WorklogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.worklog.pageTitle)),
      body: BlocListener<WorklogBloc, WorklogState>(
        // Buku yang baru saja ditutup (openBook berubah dari terisi jadi
        // null, untuk sumber yang sama) langsung ditawarkan penyuntikan --
        // laporan pemilik: sebelumnya harus mencarinya sendiri di "Riwayat
        // buku", tercampur dengan buku-buku lama yang tidak terkait.
        listenWhen: (previous, current) =>
            previous.sourceId == current.sourceId &&
            previous.openBook != null &&
            current.openBook == null,
        listener: (context, state) {
          // `listenWhen` di atas sudah memastikan TEPAT satu buku baru saja
          // tertutup (openBook berubah dari terisi jadi null) -- buku itu
          // adalah yang paling baru di `closedBooks` (terurut dari terbaru).
          final justClosed = state.closedBooks.firstOrNull;
          if (justClosed != null) {
            unawaited(_showBookClosedDialog(context, book: justClosed, state: state));
          }
        },
        child: EffectListener<WorklogBloc, WorklogState>(
          child: BlocBuilder<WorklogBloc, WorklogState>(
            builder: (context, state) {
              if (state.isLoading && state.sources.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.sources.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: .min,
                      children: [
                        Text(t.worklog.noFreelanceSource, textAlign: .center),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: t.worklog.goToIncomeSourcesButton,
                          icon: Icons.arrow_forward,
                          onPressed: () => context.push('/income/list'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _SourcePicker(state: state),
                  const SizedBox(height: AppSpacing.md),
                  if (state.openBook != null)
                    _OpenBookCard(book: state.openBook!, breakdown: state.openBookPreview)
                  else
                    const _EntryForm(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(t.worklog.historyTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.closedBooks.isEmpty) Text(t.worklog.emptyHistory),
                  for (final book in state.closedBooks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ClosedBookTile(
                        book: book,
                        breakdown: state.breakdownFor(book),
                        cycleIds: state.cycleIds,
                        otherBooks: state.books.where((b) => b.id != book.id).toList(),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Future<void> _showBookClosedDialog(
  BuildContext context, {
  required BillingBook book,
  required WorklogState state,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.worklog.bookClosedTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(t.worklog.totalHours(hours: book.totalHours)),
            const SizedBox(height: AppSpacing.sm),
            _NetPayBreakdownView(breakdown: state.breakdownFor(book)),
            const SizedBox(height: AppSpacing.md),
            _InjectForm(
              book: book,
              cycleIds: state.cycleIds,
              otherBooks: state.books.where((b) => b.id != book.id).toList(),
              onInjected: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(t.worklog.injectLaterButton),
        ),
      ],
    ),
  );
}

class _SourcePicker extends StatelessWidget {
  const _SourcePicker({required this.state});

  final WorklogState state;

  @override
  Widget build(BuildContext context) {
    if (state.sources.length < 2) return const SizedBox.shrink();
    final bloc = context.read<WorklogBloc>();
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final source in state.sources)
          AppChip(
            label: source.name,
            selected: source.id == state.sourceId,
            onTap: () => bloc.add(WorklogSourceSelected(source.id)),
          ),
      ],
    );
  }
}

class _EntryForm extends StatefulWidget {
  const _EntryForm();

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  DateTime _date = DateTime.now();
  final _hoursController = TextEditingController();

  /// Gerbang tombol Catat — dinonaktifkan (bukan diam-diam menolak submit)
  /// saat jam belum diisi atau bukan angka positif (UX-03).
  bool get _canSubmit {
    final hours = int.tryParse(_hoursController.text.trim());
    return hours != null && hours > 0;
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  void _submit() {
    final hours = int.tryParse(_hoursController.text.trim());
    if (hours == null || hours <= 0) return;
    context.read<WorklogBloc>().add(WorkLogEntryAdded(date: _date, hours: hours));
    setState(_hoursController.clear);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(t.worklog.addEntryTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: Text(CycleMonthFormatter.formatDate(_date)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _hoursController,
                  keyboardType: .number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: t.worklog.hoursFieldHint),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: t.worklog.addEntryButton,
            icon: Icons.add,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}

class _OpenBookCard extends StatelessWidget {
  const _OpenBookCard({required this.book, required this.breakdown});

  final BillingBook book;
  final NetPayBreakdown? breakdown;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<WorklogBloc>();
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text(t.worklog.openBookTitle, style: Theme.of(context).textTheme.titleMedium),
                  Text(t.worklog.totalHours(hours: book.totalHours)),
                ],
              ),
              Text(
                t.worklog.openSince(date: CycleMonthFormatter.formatDate(book.startDate)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final entry in book.entries) _EntryRow(bookId: book.id, entry: entry),
              const SizedBox(height: AppSpacing.sm),
              _NetPayBreakdownView(breakdown: breakdown, isEstimate: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _EntryForm(),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: t.worklog.closeBookButton,
          icon: Icons.lock_outline,
          onPressed: () => bloc.add(BillingBookClosed(book.id)),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.bookId, required this.entry});

  final String bookId;
  final WorkLogEntry entry;

  Future<void> _editHours(BuildContext context) async {
    final controller = TextEditingController(text: entry.hours.toString());
    final hours = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.worklog.editEntryTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: .number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: t.worklog.hoursFieldHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(int.tryParse(controller.text.trim())),
            child: Text(t.common.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (hours != null && hours > 0 && context.mounted) {
      context.read<WorklogBloc>().add(WorkLogEntryUpdated(bookId: bookId, entryId: entry.id, hours: hours));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(CycleMonthFormatter.formatDate(entry.date))),
          TextButton(
            onPressed: () => _editHours(context),
            child: Text(t.worklog.totalHours(hours: entry.hours)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () async {
              final confirmed = await showConfirmDelete(
                context,
                title: t.worklog.confirmDeleteEntryTitle,
                message: t.worklog.confirmDeleteEntryMessage,
              );
              if (confirmed && context.mounted) {
                context.read<WorklogBloc>().add(WorkLogEntryRemoved(bookId: bookId, entryId: entry.id));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _NetPayBreakdownView extends StatelessWidget {
  const _NetPayBreakdownView({required this.breakdown, this.isEstimate = false});

  final NetPayBreakdown? breakdown;

  /// True untuk buku yang masih terbuka — rinciannya PERKIRAAN (entri bisa
  /// masih berubah), beda dari buku tertutup yang rinciannya final.
  final bool isEstimate;

  @override
  Widget build(BuildContext context) {
    final breakdown = this.breakdown;
    if (breakdown == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Text(
          isEstimate ? t.worklog.estimateLabel : t.worklog.breakdownTitle,
          style: textTheme.labelSmall,
        ),
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(t.worklog.grossPayLabel),
            AppMoneyText(sen: breakdown.grossPay),
          ],
        ),
        for (final deduction in breakdown.deductions)
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(deduction.rule.label),
              Text('- ${AppMoneyFormatter.format(deduction.amount)}'),
            ],
          ),
        const Divider(),
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(t.worklog.netPayLabel, style: textTheme.titleSmall),
            AppMoneyText(sen: breakdown.netPay, style: textTheme.titleMedium),
          ],
        ),
      ],
    );
  }
}

class _ClosedBookTile extends StatelessWidget {
  const _ClosedBookTile({
    required this.book,
    required this.breakdown,
    required this.cycleIds,
    required this.otherBooks,
  });

  final BillingBook book;
  final NetPayBreakdown? breakdown;
  final List<String> cycleIds;
  final List<BillingBook> otherBooks;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                '${CycleMonthFormatter.formatDate(book.startDate)} – ${CycleMonthFormatter.formatDate(book.endDate!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              AppChip(
                label: book.isInjected ? t.worklog.injectedBadge : t.worklog.notInjectedBadge,
                selected: true,
                color: book.isInjected ? colors.income : colors.needsReview,
                shout: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(t.worklog.totalHours(hours: book.totalHours)),
          const SizedBox(height: AppSpacing.sm),
          _NetPayBreakdownView(breakdown: breakdown),
          if (book.isInjected)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(t.worklog.injectedInto(cycleId: CycleMonthFormatter.format(book.injectedCycleId!))),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: _InjectForm(book: book, cycleIds: cycleIds, otherBooks: otherBooks),
            ),
        ],
      ),
    );
  }
}

class _InjectForm extends StatefulWidget {
  const _InjectForm({
    required this.book,
    required this.cycleIds,
    required this.otherBooks,
    this.onInjected,
  });

  final BillingBook book;
  final List<String> cycleIds;

  /// Buku LAIN milik sumber yang sama — dipakai memperingatkan pemilik
  /// sebelum menimpa nominal yang sudah disuntikkan buku lain ke siklus
  /// yang sama (laporan pemilik: sebelumnya nominal buku pertama ditimpa
  /// diam-diam oleh buku kedua yang disuntik ke siklus yang sama, bukan
  /// dijumlahkan).
  final List<BillingBook> otherBooks;

  /// Dipanggil setelah penyuntikan diminta (bukan setelah benar-benar
  /// berhasil — hasilnya tetap lewat `ShowSnackBarEffect` seperti biasa).
  /// Dipakai dialog "buku ditutup" untuk menutup dirinya sendiri.
  final VoidCallback? onInjected;

  @override
  State<_InjectForm> createState() => _InjectFormState();
}

class _InjectFormState extends State<_InjectForm> {
  // UX-09: pemilik memilih dari siklus yang benar-benar ada, bukan mengetik
  // `YYYY-MM` dengan tangan. Bawaan siklus TERBARU dalam daftar (`cycleIds`
  // terurut menaik dari `CycleRepository.listCycleIds`).
  late String? _selectedCycleId = widget.cycleIds.isEmpty ? null : widget.cycleIds.last;

  Future<void> _submit() async {
    final cycleId = _selectedCycleId;
    if (cycleId == null) return;
    final conflict = widget.otherBooks.where((b) => b.injectedCycleId == cycleId).firstOrNull;
    if (conflict != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.worklog.overwriteWarningTitle),
          content: Text(
            t.worklog.overwriteWarningMessage(
              amount: AppMoneyFormatter.format(conflict.netPayAmount ?? 0),
              cycleId: CycleMonthFormatter.format(cycleId),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.common.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: dialogContext.appColors.expense),
              child: Text(t.worklog.overwriteConfirmButton),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    if (!mounted) return;
    context.read<WorklogBloc>().add(NetPayInjected(bookId: widget.book.id, cycleId: cycleId));
    widget.onInjected?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cycleIds.isEmpty) return Text(t.worklog.noCyclesForInject);
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCycleId,
            decoration: InputDecoration(labelText: t.worklog.targetCycleHint),
            items: [
              for (final id in widget.cycleIds)
                DropdownMenuItem(value: id, child: Text(CycleMonthFormatter.format(id))),
            ],
            onChanged: (value) => setState(() => _selectedCycleId = value),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          label: t.worklog.injectButton,
          onPressed: _selectedCycleId == null ? null : _submit,
        ),
      ],
    );
  }
}
