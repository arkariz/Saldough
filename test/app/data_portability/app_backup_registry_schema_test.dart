import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/data_portability/app_backup_registry.dart';
import 'package:saldough/shared/category/data/category_model.dart';
import 'package:saldough/shared/recurring/data/recurring_rule_model.dart';
import 'package:saldough/shared/transaction/data/transaction_model.dart';
import 'package:saldough/shared/wallet/data/wallet_model.dart';

/// Registri menulis `schemaVersion` modul `shared/` sebagai angka literal
/// (batas ADR-030 melarang impor berkas modelnya). Uji ini menjaganya sama
/// dengan konstanta asli: cadangan yang dibuat versi aplikasi ini harus selalu
/// lolos pemeriksaan versi miliknya sendiri.
void main() {
  test('supportedSchema modul shared/ sama dengan konstanta modelnya', () {
    expect(appBackupRegistry.specOf('wallet_all').schema, WalletModel.schemaVersion);
    expect(appBackupRegistry.specOf('category_all').schema, CategoryModel.schemaVersion);
    expect(appBackupRegistry.specOf('recurring_all').schema, RecurringRuleModel.schemaVersion);
    expect(appBackupRegistry.transactionSchema, TransactionModel.schemaVersion);
    expect(appBackupRegistry.specOf('transaction_2026-10').schema, TransactionModel.schemaVersion);
  });
}
