import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/card/domain/entities/credit_card.dart';

/// Bottom sheet tambah/sunting sebuah [CreditCard] (FR-CARD-001).
class CreditCardEditSheet extends StatefulWidget {
  /// Membuat [CreditCardEditSheet].
  const CreditCardEditSheet({this.initial, super.key});

  /// Kartu yang disunting, atau `null` kalau menambah baru.
  final CreditCard? initial;

  /// Menampilkan [CreditCardEditSheet] sebagai modal bottom sheet,
  /// mengembalikan [CreditCard] hasil sunting atau `null` kalau dibatalkan.
  static Future<CreditCard?> show(BuildContext context, {CreditCard? initial}) {
    return showModalBottomSheet<CreditCard>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreditCardEditSheet(initial: initial),
    );
  }

  @override
  State<CreditCardEditSheet> createState() => _CreditCardEditSheetState();
}

class _CreditCardEditSheetState extends State<CreditCardEditSheet> {
  late final _nameController = TextEditingController(text: widget.initial?.name ?? '');
  late final _statementDayController =
      TextEditingController(text: (widget.initial?.statementDayOfMonth ?? 15).toString());

  @override
  void dispose() {
    _nameController.dispose();
    _statementDayController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final day = int.tryParse(_statementDayController.text.trim());
    if (name.isEmpty || day == null || day < 1 || day > 28) return;
    final card = CreditCard(
      id: widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      statementDayOfMonth: day,
    );
    Navigator.of(context).pop(card);
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Text(
              widget.initial == null ? t.card.addCardTitle : t.card.editCardTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: t.card.cardNameFieldHint),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _statementDayController,
              keyboardType: .number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: t.card.statementDayFieldHint),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: t.common.save, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
