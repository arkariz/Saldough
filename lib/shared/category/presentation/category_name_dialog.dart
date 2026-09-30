import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';

/// Menanyakan nama kategori — untuk "Tambah kategori" di CATAT dan tambah/ganti
/// nama di layar Kategori (ADR-026 §3.6). Mengembalikan nama yang sudah
/// dirapikan, atau `null` kalau dibatalkan atau kosong.
Future<String?> showCategoryNameDialog(BuildContext context, {required String title, String initial = ''}) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _CategoryNameDialog(title: title, initial: initial),
  );
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(hintText: t.category.nameHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
        TextButton(
          onPressed: _controller.text.trim().isEmpty ? null : _submit,
          child: Text(t.common.save),
        ),
      ],
    );
  }
}
