import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';

/// Aplikasi bank/e-wallet yang punya pola bawaan: nama paket → nama
/// tampilan. **Nama paket belum dicek di perangkat** -- cocokkan lewat layar
/// sampel debug (ADR-032 §3.6) sebelum dianggap pasti.
const builtInNotificationApps = <String, String>{
  'id.co.bri.brimo': 'BRImo',
  'com.jago.digitalBanking': 'Jago',
  'com.bca': 'BCA mobile',
  'id.bmri.livin': "Livin' by Mandiri",
  'id.bni.wondr': 'wondr by BNI',
  'com.gojek.app': 'Gojek',
  'com.gojek.gopay': 'GoPay',
  'ovo.id': 'OVO',
  'id.dana': 'DANA',
  'com.shopee.id': 'Shopee',
  'id.co.bankbkemobile.digitalbank': 'SeaBank',
  'com.bcadigital.blu': 'blu',
};

/// Pola bawaan (ADR-032 §3.3), dicoba sesudah pola pengguna.
///
/// **Belum diverifikasi sampel asli** (`verified: false`): templat di bawah
/// hanya berjangkar pada kata arah yang lazim di notifikasi bank Indonesia,
/// bukan format persis tiap aplikasi. Karena itu drafnya tidak pernah dicatat
/// otomatis (ADR-032 §3.4) sampai pola diganti dengan templat dari sampel
/// asli dan ditandai `verified: true` beserta ujinya.
final List<NotificationPattern> builtInNotificationPatterns = [
  for (final packageName in builtInNotificationApps.keys) ..._cuePatterns(packageName),
];

/// Kata arah → jenis. Urutan penting: frasa yang lebih khusus lebih dulu.
const _cues = <(String, String, NotificationPatternKind)>[
  ('transfer-in', 'transfer masuk', NotificationPatternKind.income),
  ('funds-in', 'dana masuk', NotificationPatternKind.income),
  ('money-in', 'uang masuk', NotificationPatternKind.income),
  ('received', 'menerima', NotificationPatternKind.income),
  ('transfer-out', 'transfer keluar', NotificationPatternKind.expense),
  ('funds-out', 'dana keluar', NotificationPatternKind.expense),
  ('payment', 'pembayaran', NotificationPatternKind.expense),
  ('purchase', 'pembelian', NotificationPatternKind.expense),
  ('debit', 'debit', NotificationPatternKind.expense),
];

List<NotificationPattern> _cuePatterns(String packageName) => [
  for (final (id, cue, kind) in _cues)
    NotificationPattern(
      id: 'builtin.$packageName.$id',
      packageName: packageName,
      label: cue,
      template: '{*}$cue{*}{amount}{*}',
      kind: kind,
      builtIn: true,
      verified: false,
    ),
];
