import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Baris Catatan di Catat (prototipe `Catat.dc.html`): ikon, label kecil di
/// atas kolom teks satu baris tanpa bingkai ("Tulis catatan singkat").
/// Mengetik di sini membuka keyboard sistem; papan angka nominal menyingkir
/// selama keyboard terbuka.
class RecordNoteField extends StatelessWidget {
  /// Membuat [RecordNoteField].
  const RecordNoteField({required this.controller, required this.kind, this.onChanged, super.key});

  /// Pengendali teks catatan.
  final TextEditingController controller;

  /// Jenis transaksi.
  final TransactionKind kind;

  /// Dipanggil setiap teks berubah (memilih varian ikon kategori).
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space2),
        child: Row(
          children: [
            AppIcon(IconKey.edit, color: colors.ink2),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.record.noteSectionLabel, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
                  TextField(
                    controller: controller,
                    onTapOutside: dismissKeyboardOnTapOutside,
                    onChanged: onChanged,
                    textCapitalization: TextCapitalization.sentences,
                    cursorColor: colors.brand,
                    style: textTheme.bodyLarge,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      filled: false,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: t.record.noteFieldHint,
                      hintStyle: textTheme.bodyLarge?.copyWith(color: colors.ink3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
