/// Pengenal rekening dalam teks notifikasi (ADR-044 §3.7, E1/B-85): potongan
/// bertopeng seperti `****1234`, `xxxx5678`, atau `•••1234` yang stabil untuk
/// satu rekening di satu aplikasi. Dipakai untuk mengingat dompet tanpa
/// formulir; bukan nomor rekening utuh dan tidak pernah dikirim ke mana pun.
final _masked = RegExp(r'[*x•]{2,}\s?\d{3,6}', caseSensitive: false);

/// Pengenal rekening di [text], atau `null` bila tidak ada **tepat satu**
/// pengenal berbeda (nol = tidak ada yang dikenali; dua atau lebih = ambigu,
/// mis. transfer antar rekening, jadi tidak ditebak).
String? accountHintOf(String text) {
  final found = {for (final m in _masked.allMatches(text)) m.group(0)!.toLowerCase()};
  return found.length == 1 ? found.single : null;
}
