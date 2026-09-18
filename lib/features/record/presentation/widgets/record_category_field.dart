import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Field kategori bebas teks dengan chip saran di bawahnya.
///
/// Kategori TETAP teks bebas (`PROJECT_GLOSSARY.md` §"Konvensi penamaan" —
/// "Nama dompet dan kategori disimpan sebagai data, bukan sebagai enum").
/// [suggestions] murni pemercepat ketikan: menekan satu chip mengisi
/// [controller], tapi nilai akhirnya tetap boleh diketik ulang jadi apa
/// saja, tidak dibatasi ke daftar ini.
class RecordCategoryField extends StatelessWidget {
  /// Membuat [RecordCategoryField].
  const RecordCategoryField({required this.controller, required this.suggestions, super.key});

  /// Pengendali teks kategori.
  final TextEditingController controller;

  /// Saran kategori yang sering dipakai untuk jenis transaksi ini.
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(labelText: t.record.categoryFieldHint),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final suggestion in suggestions)
                AppChip(label: suggestion, onTap: () => controller.text = suggestion),
            ],
          ),
        ],
      ],
    );
  }
}
