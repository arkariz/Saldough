import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Hasil [LineEditSheet].
class LineEditResult {
  /// Membuat [LineEditResult].
  const LineEditResult({required this.label, required this.amount});

  /// Nama baris.
  final String label;

  /// Nominal dalam sen.
  final int amount;
}

/// Bottom sheet tambah/sunting satu baris pemasukan atau anggaran.
///
/// Nominal diketik pemilik dalam rupiah bulat (tanpa sen) lewat keyboard
/// numerik, lalu dikonversi × 100 — pengguna tidak pernah mengetik satuan
/// sen secara langsung.
class LineEditSheet extends StatefulWidget {
  /// Membuat [LineEditSheet].
  const LineEditSheet({required this.title, this.initialLabel, this.initialAmount, super.key});

  /// Judul sheet, misalnya "Tambah baris pemasukan".
  final String title;

  /// Nama awal, kalau menyunting baris yang sudah ada.
  final String? initialLabel;

  /// Nominal awal dalam sen, kalau menyunting baris yang sudah ada.
  final int? initialAmount;

  /// Menampilkan [LineEditSheet] sebagai modal bottom sheet, mengembalikan
  /// [LineEditResult] atau `null` kalau dibatalkan.
  static Future<LineEditResult?> show(
    BuildContext context, {
    required String title,
    String? initialLabel,
    int? initialAmount,
  }) {
    return showModalBottomSheet<LineEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LineEditSheet(
        title: title,
        initialLabel: initialLabel,
        initialAmount: initialAmount,
      ),
    );
  }

  @override
  State<LineEditSheet> createState() => _LineEditSheetState();
}

class _LineEditSheetState extends State<LineEditSheet> {
  late final _labelController = TextEditingController(text: widget.initialLabel ?? '');
  late final _amountController = TextEditingController(
    text: widget.initialAmount == null ? '' : (widget.initialAmount! ~/ 100).toString(),
  );

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _labelController.text.trim();
    final amountText = _amountController.text.trim();
    if (label.isEmpty || amountText.isEmpty) return;
    final rupiah = int.tryParse(amountText);
    if (rupiah == null) return;
    Navigator.of(context).pop(LineEditResult(label: label, amount: rupiah * 100));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _labelController,
            autofocus: true,
            decoration: InputDecoration(labelText: t.cycle.labelFieldHint),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _amountController,
            keyboardType: .number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: t.cycle.amountFieldHint),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: t.common.save, onPressed: _submit),
        ],
      ),
    );
  }
}
