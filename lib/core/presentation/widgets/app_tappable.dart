import 'package:flutter/widgets.dart';

/// Area ketuk yang diumumkan sebagai tombol ke pembaca layar (UX-12).
/// Pengganti `GestureDetector` polos untuk kartu, baris, dan tautan yang bisa
/// diketuk: labelnya diambil dari teks di dalamnya, atau dari [label] kalau
/// isinya hanya ikon.
class AppTappable extends StatelessWidget {
  /// Membuat [AppTappable].
  const AppTappable({
    required this.onTap,
    required this.child,
    this.label,
    this.behavior = HitTestBehavior.opaque,
    super.key,
  });

  /// Dipanggil saat diketuk; `null` = nonaktif.
  final VoidCallback? onTap;

  /// Label semantik, untuk isi tanpa teks.
  final String? label;

  /// Perilaku uji ketuk, bawaan seluruh kotak.
  final HitTestBehavior behavior;

  /// Isi.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(onTap: onTap, behavior: behavior, child: child),
    );
  }
}
