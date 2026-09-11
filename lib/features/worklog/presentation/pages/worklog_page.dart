import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/worklog/domain/entities/billing_book.dart';
import 'package:saldough/features/worklog/presentation/bloc/worklog_bloc.dart';
import 'package:saldough/features/worklog/presentation/bloc/worklog_state.dart';
import 'package:state_management/state_management.dart';

/// Layar catatan jam kerja dan buku jam — FR-TIME-001 sampai FR-TIME-004.
class WorklogPage extends StatelessWidget {
  /// Membuat [WorklogPage].
  const WorklogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.worklog.pageTitle)),
      body: EffectListener<WorklogBloc, WorklogState>(
        child: BlocBuilder<WorklogBloc, WorklogState>(
          builder: (context, state) {
            if (state.isLoading && state.sources.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.sources.isEmpty) {
              return Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(t.worklog.noFreelanceSource)));
            }
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _SourcePicker(state: state),
                const SizedBox(height: AppSpacing.md),
                _EntryForm(state: state),
                const SizedBox(height: AppSpacing.lg),
                if (state.openBook != null) _OpenBookCard(book: state.openBook!),
                const SizedBox(height: AppSpacing.lg),
                Text(t.worklog.historyTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                if (state.closedBooks.isEmpty) Text(t.worklog.emptyHistory),
                for (final book in state.closedBooks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ClosedBookTile(book: book),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
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
  const _EntryForm({required this.state});

  final WorklogState state;

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  DateTime _date = DateTime.now();
  final _hoursController = TextEditingController();
  bool _startsNewBook = false;

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
    context
        .read<WorklogBloc>()
        .add(WorkLogEntryAdded(date: _date, hours: hours, startsNewBook: _startsNewBook));
    setState(() {
      _hoursController.clear();
      _startsNewBook = false;
    });
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
                  child: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _hoursController,
                  keyboardType: .number,
                  decoration: InputDecoration(labelText: t.worklog.hoursFieldHint),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.worklog.startsNewBookLabel),
            value: _startsNewBook,
            onChanged: (value) => setState(() => _startsNewBook = value),
          ),
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
  const _OpenBookCard({required this.book});

  final BillingBook book;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(t.worklog.openBookTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(t.worklog.totalHours(hours: book.totalHours)),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: t.worklog.closeBookButton,
            icon: Icons.lock_outline,
            onPressed: () => context.read<WorklogBloc>().add(BillingBookClosed(book.id)),
          ),
        ],
      ),
    );
  }
}

class _ClosedBookTile extends StatelessWidget {
  const _ClosedBookTile({required this.book});

  final BillingBook book;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(t.worklog.totalHours(hours: book.totalHours)),
              AppMoneyText(sen: book.netPayAmount ?? 0, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          if (book.isInjected)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(t.worklog.injectedInto(cycleId: book.injectedCycleId!)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: _InjectForm(book: book),
            ),
        ],
      ),
    );
  }
}

class _InjectForm extends StatefulWidget {
  const _InjectForm({required this.book});

  final BillingBook book;

  @override
  State<_InjectForm> createState() => _InjectFormState();
}

class _InjectFormState extends State<_InjectForm> {
  late final _cycleIdController = TextEditingController(
    text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
  );

  @override
  void dispose() {
    _cycleIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cycleIdController,
            decoration: InputDecoration(labelText: t.worklog.targetCycleHint),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          label: t.worklog.injectButton,
          onPressed: () => context.read<WorklogBloc>().add(
                NetPayInjected(bookId: widget.book.id, cycleId: _cycleIdController.text.trim()),
              ),
        ),
      ],
    );
  }
}
