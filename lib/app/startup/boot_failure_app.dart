import 'package:flutter/material.dart';

/// Layar darurat bila startup gagal atau tertahan sebelum layar pertama
/// (`main` memasangnya lewat penjaga). Sengaja polos: tidak memakai tema,
/// i18n, atau DI, karena bisa jadi justru itu yang gagal dimuat. Menyebut
/// [step] supaya laporan bisa langsung menunjuk langkah yang bermasalah.
class BootFailureApp extends StatelessWidget {
  /// Membuat [BootFailureApp].
  const BootFailureApp({required this.step, required this.stuck, this.error, this.onRetry, super.key});

  /// Langkah startup yang terakhir dimulai.
  final String step;

  /// `true` bila tertahan (belum gagal, hanya terlalu lama); `false` bila galat.
  final bool stuck;

  /// Galat, bila ada.
  final Object? error;

  /// Mencoba memulai ulang startup; `null` menyembunyikan tombol.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final detail = [
      'Langkah: $step',
      if (error != null) 'Galat: $error',
    ].join('\n');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF7F6F2),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tanukonomy belum bisa dibuka',
                  key: ValueKey('boot-failure-title'),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1B1B18)),
                ),
                const SizedBox(height: 8),
                Text(
                  stuck
                      ? 'Persiapan memakan waktu lebih lama dari biasanya. Data keuanganmu aman di ponsel. Coba lagi, atau tutup lalu buka aplikasi.'
                      : 'Ada yang gagal saat persiapan. Data keuanganmu aman di ponsel. Coba lagi, atau tutup lalu buka aplikasi.',
                  style: const TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF3F3F39)),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  detail,
                  key: const ValueKey('boot-failure-detail'),
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFF55554D)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kalau berulang, kirim keterangan di atas ke pengembang.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF55554D)),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('boot-failure-retry'),
                    onPressed: onRetry,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
