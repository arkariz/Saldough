import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

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
    final ds = context.ds;
    final c = ds.colors;
    return DsFieldRow(
      icon: Icons.edit_note,
      leading: SvgPicture.asset(ClayIcons.note, width: 24, height: 24),
      label: t.record.noteSectionLabel,
      child: TextField(
        controller: controller,
        onTapOutside: dismissKeyboardOnTapOutside,
        onChanged: onChanged,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: c.actionPrimary,
        style: ds.typography.bodyMd.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: false,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: t.record.noteFieldHint,
          hintStyle: ds.typography.bodyMd.copyWith(fontSize: 14, color: c.textMuted),
        ),
      ),
    );
  }
}
