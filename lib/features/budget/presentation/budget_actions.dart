import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/domain/usecases/create_budget_from_template.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_sheet.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Membuka formulir TAMBAH anggaran, lalu mengirim hasilnya ke `BudgetBloc`.
Future<void> addBudget(BuildContext context) async {
  final bloc = context.read<BudgetBloc>();
  final result = await showFullScreenSheet<BudgetFormResult>(
    context,
    builder: (_) => BudgetFormSheet(wallets: bloc.state.activeWallets, allWallets: bloc.state.wallets),
  );
  if (result case BudgetFormSaved(
    :final name,
    :final walletId,
    :final period,
    :final startDate,
    :final items,
  )) {
    bloc.add(
      BudgetAdded(
        name: name,
        walletId: walletId,
        period: period,
        startDate: startDate,
        items: items,
      ),
    );
  }
}

/// Membuat anggaran baru dari [template] (T-7.3, FR-BUD-005): membuka
/// formulir TAMBAH anggaran yang SAMA, terisi nama dan pos template dengan id
/// pos baru, lalu mengirim hasilnya ke `BudgetBloc`. Dompet dan periode
/// dipilih di formulir; pos transfer yang tujuannya bentrok dengan dompet itu
/// ditandai formulir sampai pemilik mengganti tujuannya.
///
/// Mengembalikan `true` kalau anggaran jadi dibuat. Template tidak berubah.
Future<bool> useBudgetTemplate(BuildContext context, BudgetTemplate template) async {
  final bloc = context.read<BudgetBloc>();
  final stamp = DateTime.now().microsecondsSinceEpoch;
  var sequence = 0;
  final items = const CreateBudgetFromTemplate().draftItems(template, newItemId: () => '$stamp-${sequence++}');
  final result = await showFullScreenSheet<BudgetFormResult>(
    context,
    builder: (_) => BudgetFormSheet(
      wallets: bloc.state.activeWallets,
      allWallets: bloc.state.wallets,
      prefillName: template.name,
      prefillItems: items,
      templateName: template.name,
    ),
  );
  if (result case BudgetFormSaved(
    :final name,
    :final walletId,
    :final period,
    :final startDate,
    :final items,
  )) {
    bloc.add(BudgetAdded(name: name, walletId: walletId, period: period, startDate: startDate, items: items));
    return true;
  }
  return false;
}

/// Membuka formulir SUNTING [budget] dan meneruskan hasilnya (simpan,
/// arsip, hapus) ke `BudgetBloc`. Mengembalikan hasil formulir supaya layar
/// rincian bisa menutup dirinya sesudah anggaran dihapus.
Future<BudgetFormResult?> editBudget(BuildContext context, Budget budget) async {
  final bloc = context.read<BudgetBloc>();
  final wallets = <Wallet>[
    ...bloc.state.activeWallets,
    // Dompet anggaran ini tetap jadi pilihan walau sudah dinonaktifkan.
    if (bloc.state.walletOf(budget.walletId) case final wallet? when !wallet.isActive) wallet,
  ];
  final result = await showFullScreenSheet<BudgetFormResult>(
    context,
    builder: (_) => BudgetFormSheet(
      wallets: wallets,
      initial: budget,
      allWallets: bloc.state.wallets,
      lockedItemIds: bloc.state.lockedItemIds(budget),
    ),
  );
  switch (result) {
    case BudgetFormSaved(
      :final name,
      :final walletId,
      :final period,
      :final startDate,
        :final items,
    ):
      bloc.add(
        BudgetEdited(
          budget.copyWith(
            name: name,
            walletId: walletId,
            period: period,
            startDate: startDate,
                items: items,
          ),
        ),
      );
    case BudgetFormArchiveToggled():
      bloc.add(BudgetArchiveToggled(budget));
    case BudgetFormDeleted():
      bloc.add(BudgetDeleted(budget));
    case null:
      break;
  }
  return result;
}
