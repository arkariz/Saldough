import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_sheet.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Membuka formulir TAMBAH anggaran, lalu mengirim hasilnya ke `BudgetBloc`.
Future<void> addBudget(BuildContext context) async {
  final bloc = context.read<BudgetBloc>();
  final result = await showFullScreenSheet<BudgetFormResult>(
    context,
    builder: (_) => BudgetFormSheet(wallets: bloc.state.activeWallets),
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
    builder: (_) => BudgetFormSheet(wallets: wallets, initial: budget),
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
