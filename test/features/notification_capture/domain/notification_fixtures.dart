import 'package:saldough/features/notification_capture/data/notification_rule_interpreter.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_draft_composer.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Fixture bersama uji Catat dari notifikasi.
const notificationWallets = [
  Wallet(id: 'bri', name: 'BRI', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
  Wallet(id: 'gopay', name: 'GoPay', iconKey: 'walletEwallet', initialBalance: 0, currentBalance: 0),
  Wallet(id: 'cash', name: 'Cash', iconKey: 'walletCash', initialBalance: 0, currentBalance: 0),
];

const _names = {
  'food': 'Makan & Minum',
  'groceries': 'Belanja Harian',
  'transport': 'Transportasi',
  'bills': 'Tagihan',
  'internet': 'Pulsa & Internet',
  'health': 'Kesehatan',
  'entertainment': 'Hiburan',
  'shopping': 'Belanja',
  'education': 'Pendidikan',
  'family': 'Keluarga',
  'donation': 'Donasi',
  'expenseOther': 'Lainnya',
  'salary': 'Gaji',
  'freelance': 'Freelance',
  'bonus': 'Bonus',
  'gift': 'Hadiah',
  'incomeOther': 'Lainnya',
};

/// Kategori bawaan dengan nama Indonesia.
final List<Category> notificationCategories = [
  for (final b in BuiltInCategories.all) Category(id: b.id, kind: b.kind, name: _names[b.key]!, builtInKey: b.key),
];

/// Sumber BRImo yang dipetakan ke dompet BRI.
const brimoSource = NotificationSource(
  packageName: 'id.co.bri.brimo',
  appLabel: 'BRImo',
  walletId: 'bri',
  keywords: ['berhasil', 'masuk', 'transaksi'],
);

/// Interpreter aturan notifikasi.
TransactionInterpreter notificationRules(CaptureLanguage language) =>
    NotificationRuleInterpreter(language: language, categories: () => notificationCategories);

/// Penyusun notifikasi tanpa cloud, atau dengan [cloud].
NotificationDraftComposer notificationComposer({TransactionInterpreter? cloud}) => NotificationDraftComposer(
  composer: CaptureDraftComposer(ruleInterpreterFor: notificationRules, cloudInterpreter: cloud),
  ruleInterpreterFor: notificationRules,
);
