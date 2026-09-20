import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_frame.dart';

/// Kolom catatan bebas: judul bagian di atas, kartu putih berikon pena di
/// bawahnya (rujukan visual `pixel_kas_catat_pengeluaran`, bagian
/// "Keterangan / Catatan"). Dipakai ketiga formulir CATAT.
class RecordNoteField extends StatelessWidget {
  /// Membuat [RecordNoteField].
  const RecordNoteField({required this.controller, required this.kind, super.key});

  /// Pengendali teks catatan.
  final TextEditingController controller;

  /// Jenis transaksi: mewarnai kursor.
  final TransactionKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecordSectionLabel(t.record.noteSectionLabel, hint: t.record.optionalHint),
        const SizedBox(height: AppSpacing.xs),
        TransactionSlab(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              const AppIcon(IconKey.edit, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.sentences,
                  cursorColor: colors.kindInk(kind),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: t.record.noteFieldHint,
                    hintStyle: TextStyle(color: colors.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
