import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';

/// Nama paket pengganti "aplikasi mana pun": pola bawaan berlaku untuk setiap
/// aplikasi yang dipilih pengguna (ADR-044 §3.4), bukan untuk daftar bank
/// tertanam.
const anyPackage = '*';

/// Pola bawaan (ADR-032 §3.3), dicoba sesudah pola pengguna.
///
/// Berjangkar pada kata arah yang lazim di notifikasi transaksi, bukan pada
/// format satu aplikasi tertentu, jadi berlaku untuk aplikasi apa pun
/// (`packageName` = [anyPackage]). Belum diverifikasi (`verified: false`):
/// drafnya tidak pernah dicatat otomatis (ADR-032 §3.4) sampai pengguna
/// mengonfirmasi bentuknya di perangkat.
final List<NotificationPattern> builtInNotificationPatterns = _cuePatterns();

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
  // Padanan bahasa Inggris.
  ('money-received', 'received', NotificationPatternKind.income),
  ('paid', 'paid', NotificationPatternKind.expense),
  ('payment-en', 'payment', NotificationPatternKind.expense),
  ('purchase-en', 'purchase', NotificationPatternKind.expense),
];

List<NotificationPattern> _cuePatterns() => [
  for (final (id, cue, kind) in _cues)
    NotificationPattern(
      id: 'builtin.any.$id',
      packageName: anyPackage,
      label: cue,
      template: '{*}$cue{*}{amount}{*}',
      kind: kind,
      builtIn: true,
      verified: false,
    ),
];
