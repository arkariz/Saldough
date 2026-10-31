import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/components/ds_button.dart';
import 'package:saldough/core/design_system/components/ds_icon_tile.dart';
import 'package:saldough/core/design_system/ds_theme.dart';

/// Keadaan gagal memuat satu layar: tile ikon peringatan, judul, keterangan
/// opsional, dan tombol coba lagi. Di tengah layar, tanpa kartu.
class DsErrorState extends StatelessWidget {
  /// Membuat keadaan gagal.
  const DsErrorState({
    required this.title,
    required this.retryLabel,
    required this.onRetry,
    this.body,
    this.illustration,
    super.key,
  });

  /// Judul.
  final String title;

  /// Keterangan di bawah judul.
  final String? body;

  /// Teks tombol coba lagi.
  final String retryLabel;

  /// Dipanggil saat coba lagi.
  final VoidCallback onRetry;

  /// Ilustrasi pengganti ikon peringatan (mis. ikon clay), kira-kira 40px.
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    // Bisa digulir: teks sangat besar tidak boleh meluap di layar pendek.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration == null)
              const DsIconTile(icon: Icons.error_outline, tone: DsIconTileTone.warning, size: DsIconTileSize.lg)
            else
              DsIconTile.child(tone: DsIconTileTone.warning, child: illustration),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(title, textAlign: TextAlign.center, style: ds.typography.headlineSm),
            ),
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: ds.typography.bodyMd.copyWith(color: c.textSecondary),
              ),
            ],
            const SizedBox(height: 20),
            DsButton.secondary(label: retryLabel, icon: Icons.refresh, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
