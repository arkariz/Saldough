import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/card/domain/entities/recurring_subscription.dart';

/// Bottom sheet tambah/sunting sebuah [RecurringSubscription] milik kartu
/// [cardId] (FR-CARD-004).
class RecurringSubscriptionEditSheet extends StatefulWidget {
  /// Membuat [RecurringSubscriptionEditSheet].
  const RecurringSubscriptionEditSheet({required this.cardId, this.initial, super.key});

  /// Rujukan ke `CreditCard` pemilik langganan ini.
  final String cardId;

  /// Langganan yang disunting, atau `null` kalau menambah baru.
  final RecurringSubscription? initial;

  /// Menampilkan [RecurringSubscriptionEditSheet] sebagai modal bottom
  /// sheet, mengembalikan [RecurringSubscription] hasil sunting atau `null`
  /// kalau dibatalkan.
  static Future<RecurringSubscription?> show(
    BuildContext context, {
    required String cardId,
    RecurringSubscription? initial,
  }) {
    return showModalBottomSheet<RecurringSubscription>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RecurringSubscriptionEditSheet(cardId: cardId, initial: initial),
    );
  }

  @override
  State<RecurringSubscriptionEditSheet> createState() => _RecurringSubscriptionEditSheetState();
}

class _RecurringSubscriptionEditSheetState extends State<RecurringSubscriptionEditSheet> {
  late final _merchantController = TextEditingController(text: widget.initial?.merchant ?? '');
  late final _amountController = TextEditingController(
    text: widget.initial == null ? '' : (widget.initial!.amount ~/ 100).toString(),
  );
  late final _dayController = TextEditingController(text: (widget.initial?.dayOfMonth ?? 1).toString());
  late bool _isActive = widget.initial?.isActive ?? true;

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _submit() {
    final merchant = _merchantController.text.trim();
    final amount = int.tryParse(_amountController.text.trim());
    final day = int.tryParse(_dayController.text.trim());
    if (merchant.isEmpty || amount == null || amount <= 0 || day == null || day < 1 || day > 28) return;
    final subscription = RecurringSubscription(
      id: widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      cardId: widget.cardId,
      merchant: merchant,
      amount: amount * 100,
      dayOfMonth: day,
      isActive: _isActive,
    );
    Navigator.of(context).pop(subscription);
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
              widget.initial == null ? t.card.addSubscriptionTitle : t.card.editSubscriptionTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _merchantController,
              autofocus: true,
              decoration: InputDecoration(labelText: t.card.merchantFieldHint),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _amountController,
              keyboardType: .number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: t.card.amountFieldHint),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _dayController,
              keyboardType: .number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: t.card.subscriptionDayFieldHint),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.card.subscriptionActiveLabel),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(t.common.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: AppButton(label: t.common.save, onPressed: _submit)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
