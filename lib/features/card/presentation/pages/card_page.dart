import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/card/domain/entities/card_statement.dart';
import 'package:saldough/features/card/domain/entities/card_transaction.dart';
import 'package:saldough/features/card/domain/entities/credit_card.dart';
import 'package:saldough/features/card/domain/entities/recurring_subscription.dart';
import 'package:saldough/features/card/presentation/bloc/card_bloc.dart';
import 'package:saldough/features/card/presentation/bloc/card_state.dart';
import 'package:saldough/features/card/presentation/widgets/credit_card_edit_sheet.dart';
import 'package:saldough/features/card/presentation/widgets/recurring_subscription_edit_sheet.dart';
import 'package:state_management/state_management.dart';

/// Layar kartu kredit — FR-CARD-001 sampai FR-CARD-005.
class CardPage extends StatelessWidget {
  /// Membuat [CardPage].
  const CardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.card.pageTitle)),
      body: EffectListener<CardBloc, CardState>(
        child: BlocBuilder<CardBloc, CardState>(
          builder: (context, state) {
            if (state.isLoading && state.cards.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final bloc = context.read<CardBloc>();
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(t.card.cardsTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                if (state.cards.isEmpty) Text(t.card.emptyCards),
                for (final card in state.cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _CardTile(card: card, isSelected: card.id == state.cardId),
                  ),
                AppButton(
                  label: t.card.addCardTitle,
                  icon: Icons.add,
                  onPressed: () async {
                    final result = await CreditCardEditSheet.show(context);
                    if (result != null) bloc.add(CreditCardSaved(result));
                  },
                ),
                if (state.selectedCard != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  if (state.openStatement != null) _OpenStatementSection(state: state),
                  const SizedBox(height: AppSpacing.lg),
                  _AddTransactionForm(state: state),
                  const SizedBox(height: AppSpacing.lg),
                  Text(t.card.subscriptionsTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.cardSubscriptions.isEmpty) Text(t.card.emptySubscriptions),
                  for (final subscription in state.cardSubscriptions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _SubscriptionTile(subscription: subscription),
                    ),
                  AppButton(
                    label: t.card.addSubscriptionTitle,
                    icon: Icons.add,
                    onPressed: () async {
                      final result =
                          await RecurringSubscriptionEditSheet.show(context, cardId: state.cardId);
                      if (result != null) bloc.add(RecurringSubscriptionSaved(result));
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(t.card.historyTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.closedStatements.isEmpty) Text(t.card.emptyHistory),
                  for (final statement in state.closedStatements)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ClosedStatementTile(statement: statement),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.isSelected});

  final CreditCard card;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CardBloc>();
    final colors = context.appColors;
    return AppCard(
      child: InkWell(
        onTap: () => bloc.add(CardSelected(card.id)),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (isSelected) Icon(Icons.check_circle, color: colors.income, size: 18),
                  if (isSelected) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(card.name, style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          t.card.statementDaySubtitle(day: card.statementDayOfMonth),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await CreditCardEditSheet.show(context, initial: card);
                if (result != null) bloc.add(CreditCardSaved(result));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => bloc.add(CreditCardDeleted(card.id)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenStatementSection extends StatelessWidget {
  const _OpenStatementSection({required this.state});

  final CardState state;

  @override
  Widget build(BuildContext context) {
    final statement = state.openStatement!;
    final bloc = context.read<CardBloc>();
    final pending = statement.transactions.where((t) => !t.isConfirmed).toList();
    final confirmed = statement.transactions.where((t) => t.isConfirmed).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(t.card.openStatementTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          AppMoneyText(sen: statement.confirmedTotal, style: Theme.of(context).textTheme.headlineSmall),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(t.card.pendingConfirmationTitle, style: Theme.of(context).textTheme.titleSmall),
            for (final transaction in pending)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: _PendingTransactionRow(transaction: transaction),
              ),
          ],
          if (confirmed.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final transaction in confirmed)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Expanded(child: Text(transaction.merchant)),
                    AppMoneyText(sen: transaction.amount, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: t.card.closeStatementButton,
            icon: Icons.lock_outline,
            onPressed: () => bloc.add(const CardStatementClosed()),
          ),
        ],
      ),
    );
  }
}

class _PendingTransactionRow extends StatefulWidget {
  const _PendingTransactionRow({required this.transaction});

  final CardTransaction transaction;

  @override
  State<_PendingTransactionRow> createState() => _PendingTransactionRowState();
}

class _PendingTransactionRowState extends State<_PendingTransactionRow> {
  late final _amountController =
      TextEditingController(text: (widget.transaction.amount ~/ 100).toString());

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(widget.transaction.merchant)),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          width: 96,
          child: TextField(
            controller: _amountController,
            keyboardType: .number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: t.card.amountFieldHint),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: () {
            final amount = int.tryParse(_amountController.text.trim());
            if (amount == null || amount <= 0) return;
            context.read<CardBloc>().add(
                  CardTransactionConfirmed(transactionId: widget.transaction.id, amount: amount * 100),
                );
          },
        ),
      ],
    );
  }
}

class _AddTransactionForm extends StatefulWidget {
  const _AddTransactionForm({required this.state});

  final CardState state;

  @override
  State<_AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<_AddTransactionForm> {
  DateTime _date = DateTime.now();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final merchant = _merchantController.text.trim();
    final amount = int.tryParse(_amountController.text.trim());
    if (merchant.isEmpty || amount == null || amount <= 0) return;
    context.read<CardBloc>().add(
          CardTransactionAdded(
            date: _date,
            merchant: merchant,
            amount: amount * 100,
            note: _noteController.text.trim(),
          ),
        );
    setState(() {
      _merchantController.clear();
      _amountController.clear();
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(t.card.addTransactionTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _merchantController,
            decoration: InputDecoration(labelText: t.card.merchantFieldHint),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: Text(
                    '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: .number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: t.card.amountFieldHint),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(labelText: t.card.noteFieldHint),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: t.card.addTransactionButton, icon: Icons.add, onPressed: _submit),
        ],
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({required this.subscription});

  final RecurringSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CardBloc>();
    return AppCard(
      child: InkWell(
        onTap: () async {
          final result = await RecurringSubscriptionEditSheet.show(
            context,
            cardId: subscription.cardId,
            initial: subscription,
          );
          if (result != null) bloc.add(RecurringSubscriptionSaved(result));
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(subscription.merchant, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    t.card.subscriptionSubtitle(
                      amount: AppMoneyFormatter.format(subscription.amount),
                      day: subscription.dayOfMonth,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (!subscription.isActive)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: AppChip(label: t.card.subscriptionInactiveBadge),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => bloc.add(RecurringSubscriptionDeleted(subscription.id)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedStatementTile extends StatelessWidget {
  const _ClosedStatementTile({required this.statement});

  final CardStatement statement;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text(t.card.statementPeriodLabel(start: _fmt(statement.periodStart), end: _fmt(statement.periodEnd))),
          AppMoneyText(sen: statement.confirmedTotal, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  String _fmt(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}
