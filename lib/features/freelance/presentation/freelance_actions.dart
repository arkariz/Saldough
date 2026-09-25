import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_bloc.dart';
import 'package:saldough/features/freelance/presentation/widgets/entry_form_sheet.dart';
import 'package:saldough/features/freelance/presentation/widgets/payment_form_sheet.dart';
import 'package:saldough/features/freelance/presentation/widgets/project_form_sheet.dart';
import 'package:saldough/features/freelance/presentation/widgets/receive_payment_sheet.dart';
import 'package:state_management/state_management.dart';

/// Membuka formulir TAMBAH proyek, lalu mengirim hasilnya ke
/// `FreelanceBloc`.
Future<void> addProject(BuildContext context) async {
  final bloc = context.read<FreelanceBloc>();
  final result = await showFullScreenSheet<ProjectFormResult>(context, builder: (_) => const ProjectFormSheet());
  if (result case ProjectFormSaved(:final name, :final hourlyRate, :final deductionRules)) {
    bloc.add(FreelanceProjectAdded(name: name, hourlyRate: hourlyRate, deductionRules: deductionRules));
  }
}

/// Membuka formulir SUNTING [project].
Future<void> editProject(BuildContext context, FreelanceProject project) async {
  final bloc = context.read<FreelanceBloc>();
  final result = await showFullScreenSheet<ProjectFormResult>(
    context,
    builder: (_) => ProjectFormSheet(initial: project, canDelete: !bloc.state.projectHasEntries(project)),
  );
  switch (result) {
    case ProjectFormSaved(:final name, :final hourlyRate, :final deductionRules):
      bloc.add(
        FreelanceProjectEdited(
          project.copyWith(name: name.trim(), hourlyRate: hourlyRate, deductionRules: deductionRules),
        ),
      );
    case ProjectFormDeleted():
      if (!context.mounted) return;
      final confirmed = await showConfirmDelete(
        context,
        title: t.freelance.projectDeleteConfirmTitle,
        message: t.freelance.projectDeleteConfirmMessage(name: project.name),
      );
      if (confirmed) bloc.add(FreelanceProjectDeleted(project));
    case null:
      break;
  }
}

/// Membuka formulir TAMBAH entri worklog.
Future<void> addEntry(BuildContext context) async {
  final bloc = context.read<FreelanceBloc>();
  final result = await showFullScreenSheet<EntryFormResult>(
    context,
    builder: (_) => EntryFormSheet(projects: bloc.state.projects),
  );
  if (result case EntryFormSaved(:final projectId, :final date, :final hours, :final hourlyRate, :final note)) {
    bloc.add(FreelanceEntryAdded(projectId: projectId, date: date, hours: hours, hourlyRate: hourlyRate, note: note));
  }
}

/// Membuka formulir SUNTING [entry] yang belum ditagihkan.
Future<void> editEntry(BuildContext context, WorklogEntry entry) async {
  final bloc = context.read<FreelanceBloc>();
  final result = await showFullScreenSheet<EntryFormResult>(
    context,
    builder: (_) => EntryFormSheet(projects: bloc.state.projects, initial: entry),
  );
  switch (result) {
    case EntryFormSaved(:final projectId, :final date, :final hours, :final hourlyRate, :final note):
      bloc.add(
        FreelanceEntryEdited(
          entry.copyWith(
            projectId: projectId,
            date: date,
            hours: hours,
            hourlyRate: hourlyRate,
            note: () => note.isEmpty ? null : note,
          ),
        ),
      );
    case EntryFormDeleted():
      if (!context.mounted) return;
      final confirmed = await showConfirmDelete(
        context,
        title: t.freelance.entryDeleteConfirmTitle,
        message: t.freelance.entryDeleteConfirmMessage,
      );
      if (confirmed) bloc.add(FreelanceEntryDeleted(entry));
    case null:
      break;
  }
}

/// Membuka formulir pengelompokan worklog jadi pembayaran.
Future<void> createPayment(BuildContext context) async {
  final bloc = context.read<FreelanceBloc>();
  final state = bloc.state;
  final projects = state.projectsWithUnbilled;
  final result = await showFullScreenSheet<PaymentFormSaved>(
    context,
    builder: (_) => PaymentFormSheet(
      projects: projects,
      unbilledEntries: {for (final project in projects) project.id: state.unbilledEntriesOf(project.id)},
    ),
  );
  if (result != null) {
    bloc.add(
      FreelancePaymentCreated(
        projectId: result.projectId,
        entryIds: result.entryIds,
        expectedDate: result.expectedDate,
      ),
    );
  }
}

/// Mengganti tanggal perkiraan [payment] yang masih tertunda.
Future<void> changePaymentDate(BuildContext context, FreelancePayment payment) async {
  final bloc = context.read<FreelanceBloc>();
  final picked = await showDatePicker(
    context: context,
    initialDate: payment.expectedDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(DateTime.now().year + 2),
  );
  if (picked != null) bloc.add(FreelancePaymentDateChanged(payment, picked));
}

/// Menghapus [payment] tertunda sesudah konfirmasi; entrinya kembali belum
/// ditagihkan.
Future<void> deletePayment(BuildContext context, FreelancePayment payment) async {
  final bloc = context.read<FreelanceBloc>();
  final confirmed = await showConfirmDelete(
    context,
    title: t.freelance.paymentDeleteConfirmTitle,
    message: t.freelance.paymentDeleteConfirmMessage,
  );
  if (confirmed) bloc.add(FreelancePaymentDeleted(payment));
}

/// Membuka formulir catat pembayaran diterima (FR-FRL-004).
Future<void> receivePayment(BuildContext context, FreelancePayment payment) async {
  final bloc = context.read<FreelanceBloc>();
  final state = bloc.state;
  final result = await showFullScreenSheet<ReceivePaymentConfirmed>(
    context,
    builder: (_) => ReceivePaymentSheet(
      projectName: state.projectOf(payment.projectId)?.name ?? t.freelance.unknownProject,
      breakdown: state.breakdownOf(payment),
      wallets: state.activeWallets,
    ),
  );
  if (result != null) {
    bloc.add(
      FreelancePaymentReceived(payment: payment, walletId: result.walletId, date: result.date, note: result.note),
    );
  }
}

/// Membatalkan penerimaan [payment] sesudah konfirmasi (ADR-019).
Future<void> cancelReceipt(BuildContext context, FreelancePayment payment) async {
  final bloc = context.read<FreelanceBloc>();
  final confirmed = await showConfirmDelete(
    context,
    title: t.freelance.receiptCancelConfirmTitle,
    message: t.freelance.receiptCancelConfirmMessage,
    confirmLabel: t.freelance.receiptCancelAction,
  );
  if (confirmed) bloc.add(FreelanceReceiptCancelled(payment));
}
