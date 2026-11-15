import 'package:saldough/core/i18n/strings.g.dart';

/// Aset ikon clay per id stempel (rupa buku-stempel §3).
String stampAsset(String id) => 'assets/icons_clay/${switch (id) {
  'wallet_first' => 'bank_wallet',
  'record_first' => 'note_pencil',
  'period_tidy' => 'check_completed',
  'recurring_clear' => 'repeat_loop',
  'inbox_clear' => 'tray_empty',
  'backup_first' => 'box_backup',
  'budget_first' => 'coins_currency',
  'freelance_paid' => 'coin_paid',
  _ => 'star_bonus',
}}.svg';

/// Sudut miring tetap per id (−7° sampai +6°), supaya segel terasa dicap
/// tangan tetapi tidak berubah antar render.
double stampRotation(String id) => switch (id) {
  'wallet_first' => -6,
  'record_first' => 4,
  'period_tidy' => -3,
  'recurring_clear' => 6,
  'inbox_clear' => -7,
  'backup_first' => 3,
  'budget_first' => -4,
  'freelance_paid' => 5,
  _ => 0,
};

/// Nama stempel menurut bahasa aktif; id yang tidak dikenal dikembalikan apa adanya.
String stampName(String id) {
  final names = t.stamps.names;
  return switch (id) {
    'wallet_first' => names.wallet_first,
    'record_first' => names.record_first,
    'period_tidy' => names.period_tidy,
    'recurring_clear' => names.recurring_clear,
    'inbox_clear' => names.inbox_clear,
    'backup_first' => names.backup_first,
    'budget_first' => names.budget_first,
    'freelance_paid' => names.freelance_paid,
    _ => id,
  };
}
