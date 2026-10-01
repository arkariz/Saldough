import 'package:saldough/features/record/domain/capture/language/capture_language.dart';

/// Pengolahan teks notifikasi sebelum ditafsirkan (ADR-032 §3.1, §3.3).
abstract final class NotificationText {
  NotificationText._();

  /// Kata OTP/kode rahasia, id dan en. Notifikasi yang memuatnya tidak pernah
  /// disimpan maupun diproses -- sama dengan saringan di layanan native.
  static const otpWords = [
    'otp',
    'kode verifikasi',
    'kode rahasia',
    'kode aktivasi',
    'one time password',
    'one-time password',
    'verification code',
    'security code',
    'jangan berikan',
    'jangan bagikan',
    'do not share',
  ];

  /// Teks satu notifikasi: judul lalu isi, tanpa mengulang judul yang sudah
  /// ada di awal isi.
  static String combine(String title, String body) {
    final t = title.trim();
    final b = body.trim();
    if (t.isEmpty) return b;
    if (b.isEmpty || b.toLowerCase().startsWith(t.toLowerCase())) return b.isEmpty ? t : b;
    return '$t\n$b';
  }

  /// `true` bila [text] tampak seperti OTP atau kode rahasia.
  static bool looksLikeOtp(String text) {
    final lower = text.toLowerCase();
    return otpWords.any(lower.contains);
  }

  /// [text] dengan angka bukan-nominal diganti spasi (panjang tetap, jadi
  /// posisi dan kutipan lain tetap sama dengan teks asli):
  /// - nominal sesudah kata saldo/limit dari [lexicon];
  /// - nomor rekening/kartu tersamar (`****1234`, `1234xxxx5678`);
  /// - deret digit 8+ tanpa pemisah (nomor referensi, rekening);
  /// - jam (`14:32`, `pukul 14.32`).
  static String maskNonTransactionNumbers(String text, NotificationLexicon lexicon) {
    final chars = text.split('');
    void blank(int start, int end) {
      for (var i = start; i < end; i++) {
        if (chars[i] != '\n') chars[i] = ' ';
      }
    }

    final lower = text.toLowerCase();
    if (lexicon.balanceWords.isNotEmpty) {
      final words = [...lexicon.balanceWords]..sort((a, b) => b.length.compareTo(a.length));
      final balance = RegExp(
        // "top up saldo Rp50.000" / "isi saldo ..." menyebut nominal
        // transaksi, bukan saldo.
        '(?<![a-z])(?<!top up )(?<!topup )(?<!isi )'
        '(?:${words.map(RegExp.escape).join('|')})'
        r'(?:\s+(?:anda|kamu|rekening|akhir|tersedia))?\s*[:=]?\s*'
        r'((?:rp|idr)?\.?\s?\d[\d.,]*)',
      );
      for (final m in balance.allMatches(lower)) {
        blank(m.start + m.group(0)!.length - m.group(1)!.length, m.end);
      }
    }
    for (final pattern in [
      RegExp(r'[*x•]{2,}\d+|\d+[*x•]{2,}\d*'),
      RegExp(r'(?<![\d.,])\d{8,}(?![\d.,])'),
      RegExp(r'(?<![\d.,])\d{1,2}:\d{2}(?::\d{2})?(?![\d])'),
      RegExp(r'pukul\s+\d{1,2}[.:]\d{2}(?:[.:]\d{2})?'),
    ]) {
      for (final m in pattern.allMatches(lower)) {
        blank(m.start, m.end);
      }
    }
    return chars.join();
  }
}
