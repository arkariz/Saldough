import 'package:saldough/core/currency/currency_preference_repository_impl.dart';
import 'package:saldough/features/budget/data/models/budget_model.dart';
import 'package:saldough/features/budget/data/models/budget_template_model.dart';
import 'package:saldough/features/data_portability/domain/backup_registry.dart';
import 'package:saldough/features/freelance/data/models/freelance_models.dart';
import 'package:saldough/features/notification_capture/data/notification_capture_store_impl.dart';

/// Daftar kunci penyimpanan dan statusnya terhadap cadangan (ADR-040 §3.3).
///
/// Setiap `StorageKey` di `lib/` harus muncul di sini, di `included` atau
/// `excluded` (dijaga `backup_registry_completeness_test.dart`). Menambah data
/// baru berarti memutuskan di sini apakah ia ikut cadangan.
///
/// Kunci ditulis sebagai `StorageKey.value` (`<namespace>_<name>`).
/// `supportedSchema` mengikuti `schemaVersion` repositorinya. Modul `shared/`
/// hanya boleh diimpor lewat barrel-nya (ADR-030), jadi angkanya ditulis
/// literal di sini dan `app_backup_registry_schema_test.dart` memastikannya
/// sama dengan konstanta aslinya; naikkan keduanya bersama.
final appBackupRegistry = BackupRegistry(
  included: [
    // Data.
    const BackupKeySpec('wallet_all', supportedSchema: 1),
    const BackupKeySpec('transaction__index'),
    const BackupKeySpec('budget_all', supportedSchema: BudgetModel.schemaVersion),
    const BackupKeySpec('budget_template_all', supportedSchema: BudgetTemplateModel.schemaVersion),
    const BackupKeySpec('category_all', supportedSchema: 1),
    // Penanda migrasi kategori lama: ikut supaya migrasi tidak berjalan lagi.
    const BackupKeySpec('category__migration'),
    const BackupKeySpec('freelance_projects', supportedSchema: freelanceSchemaVersion),
    const BackupKeySpec('freelance_worklog', supportedSchema: freelanceSchemaVersion),
    const BackupKeySpec('freelance_payments', supportedSchema: freelanceSchemaVersion),
    const BackupKeySpec('recurring_all', supportedSchema: 1),
    const BackupKeySpec('recurring_auto_record_log', supportedSchema: 1),
    const BackupKeySpec('recurring_match_log', supportedSchema: 1),
    const BackupKeySpec('recurring_suggestion_dismissed', supportedSchema: 1),
    const BackupKeySpec('plan_month_review', supportedSchema: 2),
    // Saldo akhir bulan lampau tidak bisa dihitung ulang dari data sekarang.
    const BackupKeySpec('plan_forecast_snapshots', supportedSchema: 1),
    // Setelan keuangan.
    const BackupKeySpec('settings_financial_month_schedule', supportedSchema: 1),
    // Preferensi lama satu angka, dibaca untuk migrasi: ikut untuk pengguna
    // yang belum termigrasi.
    const BackupKeySpec('settings_financial_month_start'),
    const BackupKeySpec('settings_financial_month_offer', supportedSchema: 1),
    const BackupKeySpec('settings_currency', supportedSchema: CurrencyPreferenceRepositoryImpl.schemaVersion),
    const BackupKeySpec('settings_recurring_reminders', supportedSchema: 1),
    const BackupKeySpec('settings_notification_capture', supportedSchema: NotificationCaptureStoreImpl.schemaVersion),
    const BackupKeySpec('capture_notification_patterns', supportedSchema: NotificationCaptureStoreImpl.schemaVersion),
  ],
  excluded: const {
    // Milik perangkat (R-9).
    'settings_language': 'milik perangkat',
    'settings_hideAmounts': 'milik perangkat',
    'settings_history_segment': 'milik perangkat',
    'tutorial_progress': 'milik perangkat',
    'app_update_memory': 'milik perangkat',
    'app_update_notes': 'milik perangkat',
    // Teks notifikasi: privasi (ADR-032) dan sementara.
    'capture_inbox': 'teks notifikasi, privasi dan sementara',
    'capture_processed_ids': 'sementara, pencegah ganda per perangkat',
    // P-1 ADR-040: log jendela batal pencatatan otomatis dari notifikasi.
    'capture_auto_recorded': 'sementara, terkait kotak masuk yang tidak ikut',
  },
  transactionIndexKey: 'transaction__index',
  transactionPartitionKey: (month) => 'transaction_$month',
  transactionPartitionPrefix: 'transaction_',
  transactionSchema: 2,
  sourceIconKey: (id) => 'source_icon_$id',
  sourceIconPrefix: 'source_icon_',
  references: const [
    BackupReference(
      from: 'transaction_*',
      fields: ['walletId', 'fromWalletId', 'toWalletId'],
      target: 'wallet_all',
    ),
    BackupReference(from: 'transaction_*', fields: ['categoryId'], target: 'category_all'),
    BackupReference(from: 'recurring_all', fields: ['walletId', 'toWalletId'], target: 'wallet_all'),
    BackupReference(from: 'freelance_payments', fields: ['walletId'], target: 'wallet_all'),
    BackupReference(from: 'freelance_payments', fields: ['projectId'], target: 'freelance_projects'),
    BackupReference(from: 'freelance_worklog', fields: ['projectId'], target: 'freelance_projects'),
  ],
  walletsKey: 'wallet_all',
  currencyKey: 'settings_currency',
);
