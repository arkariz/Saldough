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
  const RecordCategoryField({required this.controller, required this.suggestions, this.icons = const [], super.key});

  /// Pengendali teks kategori.
  final TextEditingController controller;

  /// Saran kategori yang sering dipakai untuk jenis transaksi ini.
  final List<String> suggestions;

  /// Ikon per [suggestions], searah indeks. Bawaan kosong -- chip tanpa
  /// ikon. Indeks yang tidak tercakup (lebih pendek dari [suggestions] atau
  /// bernilai `null`) tampil tanpa ikon juga.
  final List<IconKey?> icons;

  IconKey? _iconFor(int index) => index < icons.length ? icons[index] : null;

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
          // `ValueListenableBuilder` supaya chip yang cocok dengan isi
          // [controller] saat ini tampil terpilih (UX-05 review pemilik) --
          // termasuk saat pemakai mengetik ulang nilainya jadi persis salah
          // satu saran tanpa menekan chip-nya.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < suggestions.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    AppChip(
                      label: suggestions[i],
                      icon: _iconFor(i),
                      selected: value.text == suggestions[i],
                      onTap: () => controller.text = suggestions[i],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
