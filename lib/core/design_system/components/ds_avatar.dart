import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';

/// Foto profil bulat dengan cincin tipis.
class DsAvatar extends StatelessWidget {
  /// Membuat avatar. Tanpa [image], ikon orang ditampilkan.
  const DsAvatar({required this.semanticLabel, this.image, this.size = 28, super.key});

  /// Foto.
  final ImageProvider? image;

  /// Diameter foto (tanpa cincin).
  final double size;

  /// Label pembaca layar ("Akun").
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.outlineSubtle),
        ),
        child: CircleAvatar(
          radius: size / 2,
          backgroundColor: c.surfaceSunken,
          foregroundImage: image,
          child: image == null ? Icon(Icons.person, size: size * 0.6, color: c.textSecondary) : null,
        ),
      ),
    );
  }
}
