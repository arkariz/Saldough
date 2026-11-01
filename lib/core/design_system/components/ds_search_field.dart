import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/ds_theme.dart';
import 'package:saldough/core/design_system/tokens/ds_radius.dart';

/// Kolom cari berbentuk pil (acuan Riwayat): ikon kaca pembesar, teks petunjuk
/// abu, tinggi 48. Kolom ikut berubah saat [query] diganti dari luar (mis.
/// tombol "Hapus filter").
class DsSearchField extends StatefulWidget {
  /// Membuat kolom cari.
  const DsSearchField({
    required this.query,
    required this.onChanged,
    required this.hint,
    super.key,
  });

  /// Kata kunci aktif.
  final String query;

  /// Dipanggil tiap teks berubah.
  final ValueChanged<String> onChanged;

  /// Teks petunjuk.
  final String hint;

  @override
  State<DsSearchField> createState() => _DsSearchFieldState();
}

class _DsSearchFieldState extends State<DsSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );

  @override
  void didUpdateWidget(DsSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) _controller.text = widget.query;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: DsRadius.fullAll,
        border: Border.all(color: c.outlineSubtle),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        style: ds.typography.bodyMd.copyWith(color: c.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: widget.hint,
          hintStyle: ds.typography.bodyMd.copyWith(color: c.textMuted),
          prefixIcon: Icon(Icons.search, size: 20, color: c.textMuted),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 48,
          ),
          contentPadding: const EdgeInsets.only(right: 16, top: 14, bottom: 14),
        ),
      ),
    );
  }
}
