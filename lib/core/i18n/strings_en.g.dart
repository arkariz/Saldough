///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$en app = _Translations$app$en._(_root);
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
	@override late final _Translations$cycle$en cycle = _Translations$cycle$en._(_root);
	@override late final _Translations$income$en income = _Translations$income$en._(_root);
	@override late final _Translations$worklog$en worklog = _Translations$worklog$en._(_root);
	@override late final _Translations$card$en card = _Translations$card$en._(_root);
	@override late final _Translations$grocery$en grocery = _Translations$grocery$en._(_root);
	@override late final _Translations$investment$en investment = _Translations$investment$en._(_root);
	@override late final _Translations$shell$en shell = _Translations$shell$en._(_root);
}

// Path: app
class _Translations$app$en extends Translations$app$id {
	_Translations$app$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Saldough';
}

// Path: common
class _Translations$common$en extends Translations$common$id {
	_Translations$common$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get save => 'Save';
	@override String get cancel => 'Cancel';
	@override String get delete => 'Delete';
	@override String get edit => 'Edit';
	@override String get add => 'Add';
	@override String get retry => 'Retry';
	@override String get loading => 'Loading...';
	@override String get genericErrorMessage => 'Something went wrong. Please try again.';
	@override String get confirmDeleteTitle => 'Delete?';
}

// Path: cycle
class _Translations$cycle$en extends Translations$cycle$id {
	_Translations$cycle$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get incomeSectionTitle => 'Income';
	@override String get budgetSectionTitle => 'Budget';
	@override String get totalLabel => 'Total';
	@override String get remainderLabel => 'Remainder';
	@override String get addIncomeLine => 'Add income line';
	@override String get addBudgetLine => 'Add budget line';
	@override String get editIncomeLine => 'Edit income line';
	@override String get editBudgetLine => 'Edit budget line';
	@override String get labelFieldHint => 'Name';
	@override String get amountFieldHint => 'Amount (Rp)';
	@override String get emptyIncome => 'No income lines yet.';
	@override String get emptyBudget => 'No budget lines yet.';
	@override String get rollOverButton => 'Create next month';
	@override String cycleCreatedMessage({required Object month}) => '${month} cycle created.';
	@override String get closeCycle => 'Close cycle';
	@override String get reopenCycle => 'Reopen';
	@override String get closedBanner => 'This cycle is closed.';
	@override String get closedCannotEdit => 'This cycle is closed. Reopen it to make changes.';
	@override String get rollUpNotEditable => 'This line is calculated automatically and can\'t be edited directly.';
	@override String get rollUpSourceUnavailableCard => 'The source card isn\'t registered yet. Add it under Shopping › Credit Cards first.';
	@override String get rollUpSourceUnavailableGrocery => 'The shopping plan is still empty. Fill it in on the Shopping tab first.';
	@override String get markFixed => 'Mark as fixed';
	@override String get markIncidental => 'Mark as one-off';
	@override String get needsReviewBadge => 'Needs review';
	@override String get confirmReviewed => 'Looks right';
	@override String unreviewedBanner({required Object count}) => '${count} line(s) need review.';
	@override String get unreviewedBannerHint => 'The amount still carries over from last month — check it before marking it right.';
	@override String get deleteCycle => 'Delete this cycle';
	@override String get deleteCycleConfirmMessage => 'All income and budget lines for this month will be deleted. This action cannot be undone.';
	@override String get noIncomeSourcesHint => 'No income sources yet. You can type an amount manually, or add a source first so the amount follows your hours or fixed salary automatically.';
	@override String get addIncomeSourceButton => 'Add income source';
	@override String get budgetSourceFieldLabel => 'Amount source';
	@override String get budgetSourceManual => 'Manual';
	@override String get budgetSourceGrocery => 'Grocery plan';
	@override String get budgetSourceCard => 'Credit card';
	@override String get selectCardHint => 'Select a card';
	@override String get rollUpSourceAlreadyUsed => 'This source is already linked to another budget line.';
	@override String confirmDeleteIncomeLineTitle({required Object name}) => 'Delete the ${name} line?';
	@override String confirmDeleteBudgetLineTitle({required Object name}) => 'Delete the ${name} line?';
	@override String get confirmDeleteLineMessage => 'This line will be removed from this cycle. This cannot be undone.';
	@override String get noCardsHint => 'No cards yet. Add one first under Groceries › Credit Card.';
	@override String get allCardsUsedHint => 'Every card is already linked to another budget line.';
}

// Path: income
class _Translations$income$en extends Translations$income$id {
	_Translations$income$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pageTitle => 'Income sources';
	@override String get emptySources => 'No income sources yet.';
	@override String get addSourceTitle => 'Add income source';
	@override String get editSourceTitle => 'Edit income source';
	@override String get nameFieldHint => 'Name';
	@override String get fixedAmountFieldHint => 'Fixed amount (Rp)';
	@override String get hourlyRateFieldHint => 'Hourly rate (Rp)';
	@override String hourlyRateSubtitle({required Object rate}) => '${rate} / hour';
	@override String get kindFixedSalary => 'Fixed salary';
	@override String get kindHourlyFreelance => 'Hourly freelance';
	@override String get kindAdHoc => 'One-off';
	@override String get deductionRulesTitle => 'Deduction rules';
	@override String get addDeductionRuleButton => 'Add deduction';
	@override String get deductionLabelHint => 'Deduction name';
	@override String get deductionValueHint => 'Value';
	@override String get deductionKindPermille => 'Per mille';
	@override String get deductionKindFixed => 'Fixed (Rp)';
	@override String get worklogEntryPointLabel => 'Log Work Hours';
	@override String confirmDeleteSourceTitle({required Object name}) => 'Delete source ${name}?';
	@override String get confirmDeleteSourceMessage => 'Income lines in any cycle that link to this source will no longer update when the source is edited. Amounts already recorded are not deleted. This cannot be undone.';
}

// Path: worklog
class _Translations$worklog$en extends Translations$worklog$id {
	_Translations$worklog$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pageTitle => 'Work log';
	@override String get noFreelanceSource => 'No freelance income source yet. Add one on the Income Sources screen first.';
	@override String get addEntryTitle => 'Log hours';
	@override String get hoursFieldHint => 'Number of hours';
	@override String get startsNewBookLabel => 'Start new book';
	@override String get addEntryButton => 'Log';
	@override String get openBookTitle => 'Open book';
	@override String totalHours({required Object hours}) => '${hours} hour(s)';
	@override String get closeBookButton => 'Close book';
	@override String bookClosedMessage({required Object netPay}) => 'Book closed. Net pay ${netPay}.';
	@override String get historyTitle => 'Book history';
	@override String get emptyHistory => 'No closed books yet.';
	@override String get targetCycleHint => 'Target cycle';
	@override String get noCyclesForInject => 'No cycles available to pick from yet. Create a cycle in the Cycle tab first.';
	@override String get injectButton => 'Inject into cycle';
	@override String injectedMessage({required Object cycleId}) => 'Injected into cycle ${cycleId}.';
	@override String injectedInto({required Object cycleId}) => 'Injected into cycle ${cycleId}.';
}

// Path: card
class _Translations$card$en extends Translations$card$id {
	_Translations$card$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pageTitle => 'Credit cards';
	@override String get cardsTitle => 'Cards';
	@override String get emptyCards => 'No cards yet.';
	@override String get addCardTitle => 'Add card';
	@override String get editCardTitle => 'Edit card';
	@override String get cardNameFieldHint => 'Card name';
	@override String get statementDayFieldHint => 'Statement day';
	@override String statementDaySubtitle({required Object day}) => 'Statement day ${day}';
	@override String openStatementTitleFor({required Object cardName}) => 'Open statement — ${cardName}';
	@override String get pendingConfirmationTitle => 'Needs confirmation';
	@override String get closeStatementButton => 'Close statement';
	@override String get statementClosedMessage => 'Statement closed. Next statement opened.';
	@override String get addTransactionTitle => 'Log transaction';
	@override String get merchantFieldHint => 'Merchant';
	@override String get amountFieldHint => 'Amount (Rp)';
	@override String get noteFieldHint => 'Note (optional)';
	@override String get addTransactionButton => 'Log';
	@override String subscriptionsTitleFor({required Object cardName}) => 'Recurring subscriptions — ${cardName}';
	@override String get emptySubscriptions => 'No subscriptions yet.';
	@override String get addSubscriptionTitle => 'Add subscription';
	@override String get editSubscriptionTitle => 'Edit subscription';
	@override String get subscriptionDayFieldHint => 'Day prepared each month';
	@override String get subscriptionActiveLabel => 'Active';
	@override String subscriptionSubtitle({required Object amount, required Object day}) => '${amount} / month, day ${day}';
	@override String get subscriptionInactiveBadge => 'Inactive';
	@override String historyTitleFor({required Object cardName}) => 'Statement history — ${cardName}';
	@override String get emptyHistory => 'No closed statements yet.';
	@override String statementPeriodLabel({required Object start, required Object end}) => '${start} – ${end}';
	@override String confirmDeleteCardTitle({required Object name}) => 'Delete card ${name}?';
	@override String get confirmDeleteCardMessage => 'All statements and transactions on this card will be deleted. Budget lines linked to this card will lose their source. This cannot be undone.';
	@override String confirmDeleteSubscriptionTitle({required Object name}) => 'Delete the ${name} subscription?';
	@override String get confirmDeleteSubscriptionMessage => 'This subscription will no longer be added automatically each statement. Transactions already recorded are unaffected. This cannot be undone.';
}

// Path: grocery
class _Translations$grocery$en extends Translations$grocery$id {
	_Translations$grocery$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pageTitle => 'Grocery plan';
	@override String get rollUpTotal => 'Monthly total';
	@override String get weeksPerMonthFieldHint => 'Weeks per month multiplier';
	@override String get weeklyTitle => 'Weekly list';
	@override String get monthlyTitle => 'Monthly list';
	@override String get emptyItems => 'No items yet.';
	@override String get addItemButton => 'Add item';
	@override String get editItemTitle => 'Edit item';
	@override String get itemNameFieldHint => 'Item name';
	@override String get quantityFieldHint => 'Quantity';
	@override String get unitPriceFieldHint => 'Unit price (Rp)';
	@override String get overridePriceLabel => 'Override price';
	@override String get overrideAmountFieldHint => 'Override amount (Rp)';
	@override String get overriddenBadge => 'overridden';
	@override String get cardEntryPointLabel => 'Credit Card';
	@override String confirmDeleteItemTitle({required Object name}) => 'Delete ${name}?';
	@override String get confirmDeleteItemMessage => 'The monthly grocery total will change, and any budget line linked to it will adjust accordingly. This cannot be undone.';
}

// Path: investment
class _Translations$investment$en extends Translations$investment$id {
	_Translations$investment$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pageTitle => 'Investment';
	@override String get totalPortfolioTitle => 'Total portfolio';
	@override String get goalsTitle => 'Goals';
	@override String get emptyGoals => 'No goals yet.';
	@override String get addGoalTitle => 'Add goal';
	@override String get editGoalTitle => 'Edit goal';
	@override String get goalNameFieldHint => 'Goal name';
	@override String get openingBalanceFieldHint => 'Opening balance (Rp)';
	@override String get allocationPlanTitle => 'This month\'s allocation';
	@override String get cycleIdFieldHint => 'Cycle';
	@override String get noCyclesAvailable => 'No cycles available to pick from yet. Create a cycle in the Cycle tab first.';
	@override String get cycleNotFound => 'This cycle doesn\'t exist yet.';
	@override String get cycleClosedMessage => 'This cycle is closed. Reopen it to edit the allocation.';
	@override String get remainderLabel => 'Cycle remainder';
	@override String get returnDepositFieldHint => 'Extra funds (Rp)';
	@override String get percentageFieldHint => '%';
	@override String totalPercentageLabel({required Object total}) => 'Total percentage: ${total}%';
	@override String get loansTitle => 'Loans between goals';
	@override String get emptyLoans => 'No loans yet.';
	@override String get addLoanTitle => 'Add loan';
	@override String get editLoanTitle => 'Edit loan';
	@override String get fromGoalFieldHint => 'From goal';
	@override String get toGoalFieldHint => 'To goal';
	@override String get principalFieldHint => 'Principal (Rp)';
	@override String get repaidFieldHint => 'Repaid (Rp)';
	@override String get noteFieldHint => 'Note (optional)';
	@override String get historyTitle => 'History';
	@override String allocationHistoryLabel({required Object cycleId}) => 'Allocation for cycle ${cycleId}';
	@override String loanInLabel({required Object fromName}) => 'Loan from ${fromName}';
	@override String loanOutLabel({required Object toName}) => 'Loan to ${toName}';
	@override String loanRouteLabel({required Object fromName, required Object toName}) => '${fromName} → ${toName}';
	@override String loanAmountsLabel({required Object principal, required Object repaid}) => 'Principal ${principal}, repaid ${repaid}';
	@override String get invalidTotalMessage => 'Total percentage must be 0 or 100.';
	@override String get allocationSavedMessage => 'Allocation plan saved.';
	@override String get loanSavedMessage => 'Loan saved.';
	@override String confirmDeleteGoalTitle({required Object name}) => 'Delete the ${name} goal?';
	@override String get confirmDeleteGoalMessage => 'The goal\'s balance and its entire allocation history will be deleted. This cannot be undone.';
	@override String get confirmDeleteLoanTitle => 'Delete this loan?';
	@override String get confirmDeleteLoanMessage => 'The principal and repayment records will be deleted, and both goals\' balances will change. This cannot be undone.';
}

// Path: shell
class _Translations$shell$en extends Translations$shell$id {
	_Translations$shell$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get cycleTabLabel => 'Cycle';
	@override String get incomeTabLabel => 'Income';
	@override String get groceryTabLabel => 'Grocery';
	@override String get investmentTabLabel => 'Investment';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Saldough',
			'common.save' => 'Save',
			'common.cancel' => 'Cancel',
			'common.delete' => 'Delete',
			'common.edit' => 'Edit',
			'common.add' => 'Add',
			'common.retry' => 'Retry',
			'common.loading' => 'Loading...',
			'common.genericErrorMessage' => 'Something went wrong. Please try again.',
			'common.confirmDeleteTitle' => 'Delete?',
			'cycle.incomeSectionTitle' => 'Income',
			'cycle.budgetSectionTitle' => 'Budget',
			'cycle.totalLabel' => 'Total',
			'cycle.remainderLabel' => 'Remainder',
			'cycle.addIncomeLine' => 'Add income line',
			'cycle.addBudgetLine' => 'Add budget line',
			'cycle.editIncomeLine' => 'Edit income line',
			'cycle.editBudgetLine' => 'Edit budget line',
			'cycle.labelFieldHint' => 'Name',
			'cycle.amountFieldHint' => 'Amount (Rp)',
			'cycle.emptyIncome' => 'No income lines yet.',
			'cycle.emptyBudget' => 'No budget lines yet.',
			'cycle.rollOverButton' => 'Create next month',
			'cycle.cycleCreatedMessage' => ({required Object month}) => '${month} cycle created.',
			'cycle.closeCycle' => 'Close cycle',
			'cycle.reopenCycle' => 'Reopen',
			'cycle.closedBanner' => 'This cycle is closed.',
			'cycle.closedCannotEdit' => 'This cycle is closed. Reopen it to make changes.',
			'cycle.rollUpNotEditable' => 'This line is calculated automatically and can\'t be edited directly.',
			'cycle.rollUpSourceUnavailableCard' => 'The source card isn\'t registered yet. Add it under Shopping › Credit Cards first.',
			'cycle.rollUpSourceUnavailableGrocery' => 'The shopping plan is still empty. Fill it in on the Shopping tab first.',
			'cycle.markFixed' => 'Mark as fixed',
			'cycle.markIncidental' => 'Mark as one-off',
			'cycle.needsReviewBadge' => 'Needs review',
			'cycle.confirmReviewed' => 'Looks right',
			'cycle.unreviewedBanner' => ({required Object count}) => '${count} line(s) need review.',
			'cycle.unreviewedBannerHint' => 'The amount still carries over from last month — check it before marking it right.',
			'cycle.deleteCycle' => 'Delete this cycle',
			'cycle.deleteCycleConfirmMessage' => 'All income and budget lines for this month will be deleted. This action cannot be undone.',
			'cycle.noIncomeSourcesHint' => 'No income sources yet. You can type an amount manually, or add a source first so the amount follows your hours or fixed salary automatically.',
			'cycle.addIncomeSourceButton' => 'Add income source',
			'cycle.budgetSourceFieldLabel' => 'Amount source',
			'cycle.budgetSourceManual' => 'Manual',
			'cycle.budgetSourceGrocery' => 'Grocery plan',
			'cycle.budgetSourceCard' => 'Credit card',
			'cycle.selectCardHint' => 'Select a card',
			'cycle.rollUpSourceAlreadyUsed' => 'This source is already linked to another budget line.',
			'cycle.confirmDeleteIncomeLineTitle' => ({required Object name}) => 'Delete the ${name} line?',
			'cycle.confirmDeleteBudgetLineTitle' => ({required Object name}) => 'Delete the ${name} line?',
			'cycle.confirmDeleteLineMessage' => 'This line will be removed from this cycle. This cannot be undone.',
			'cycle.noCardsHint' => 'No cards yet. Add one first under Groceries › Credit Card.',
			'cycle.allCardsUsedHint' => 'Every card is already linked to another budget line.',
			'income.pageTitle' => 'Income sources',
			'income.emptySources' => 'No income sources yet.',
			'income.addSourceTitle' => 'Add income source',
			'income.editSourceTitle' => 'Edit income source',
			'income.nameFieldHint' => 'Name',
			'income.fixedAmountFieldHint' => 'Fixed amount (Rp)',
			'income.hourlyRateFieldHint' => 'Hourly rate (Rp)',
			'income.hourlyRateSubtitle' => ({required Object rate}) => '${rate} / hour',
			'income.kindFixedSalary' => 'Fixed salary',
			'income.kindHourlyFreelance' => 'Hourly freelance',
			'income.kindAdHoc' => 'One-off',
			'income.deductionRulesTitle' => 'Deduction rules',
			'income.addDeductionRuleButton' => 'Add deduction',
			'income.deductionLabelHint' => 'Deduction name',
			'income.deductionValueHint' => 'Value',
			'income.deductionKindPermille' => 'Per mille',
			'income.deductionKindFixed' => 'Fixed (Rp)',
			'income.worklogEntryPointLabel' => 'Log Work Hours',
			'income.confirmDeleteSourceTitle' => ({required Object name}) => 'Delete source ${name}?',
			'income.confirmDeleteSourceMessage' => 'Income lines in any cycle that link to this source will no longer update when the source is edited. Amounts already recorded are not deleted. This cannot be undone.',
			'worklog.pageTitle' => 'Work log',
			'worklog.noFreelanceSource' => 'No freelance income source yet. Add one on the Income Sources screen first.',
			'worklog.addEntryTitle' => 'Log hours',
			'worklog.hoursFieldHint' => 'Number of hours',
			'worklog.startsNewBookLabel' => 'Start new book',
			'worklog.addEntryButton' => 'Log',
			'worklog.openBookTitle' => 'Open book',
			'worklog.totalHours' => ({required Object hours}) => '${hours} hour(s)',
			'worklog.closeBookButton' => 'Close book',
			'worklog.bookClosedMessage' => ({required Object netPay}) => 'Book closed. Net pay ${netPay}.',
			'worklog.historyTitle' => 'Book history',
			'worklog.emptyHistory' => 'No closed books yet.',
			'worklog.targetCycleHint' => 'Target cycle',
			'worklog.noCyclesForInject' => 'No cycles available to pick from yet. Create a cycle in the Cycle tab first.',
			'worklog.injectButton' => 'Inject into cycle',
			'worklog.injectedMessage' => ({required Object cycleId}) => 'Injected into cycle ${cycleId}.',
			'worklog.injectedInto' => ({required Object cycleId}) => 'Injected into cycle ${cycleId}.',
			'card.pageTitle' => 'Credit cards',
			'card.cardsTitle' => 'Cards',
			'card.emptyCards' => 'No cards yet.',
			'card.addCardTitle' => 'Add card',
			'card.editCardTitle' => 'Edit card',
			'card.cardNameFieldHint' => 'Card name',
			'card.statementDayFieldHint' => 'Statement day',
			'card.statementDaySubtitle' => ({required Object day}) => 'Statement day ${day}',
			'card.openStatementTitleFor' => ({required Object cardName}) => 'Open statement — ${cardName}',
			'card.pendingConfirmationTitle' => 'Needs confirmation',
			'card.closeStatementButton' => 'Close statement',
			'card.statementClosedMessage' => 'Statement closed. Next statement opened.',
			'card.addTransactionTitle' => 'Log transaction',
			'card.merchantFieldHint' => 'Merchant',
			'card.amountFieldHint' => 'Amount (Rp)',
			'card.noteFieldHint' => 'Note (optional)',
			'card.addTransactionButton' => 'Log',
			'card.subscriptionsTitleFor' => ({required Object cardName}) => 'Recurring subscriptions — ${cardName}',
			'card.emptySubscriptions' => 'No subscriptions yet.',
			'card.addSubscriptionTitle' => 'Add subscription',
			'card.editSubscriptionTitle' => 'Edit subscription',
			'card.subscriptionDayFieldHint' => 'Day prepared each month',
			'card.subscriptionActiveLabel' => 'Active',
			'card.subscriptionSubtitle' => ({required Object amount, required Object day}) => '${amount} / month, day ${day}',
			'card.subscriptionInactiveBadge' => 'Inactive',
			'card.historyTitleFor' => ({required Object cardName}) => 'Statement history — ${cardName}',
			'card.emptyHistory' => 'No closed statements yet.',
			'card.statementPeriodLabel' => ({required Object start, required Object end}) => '${start} – ${end}',
			'card.confirmDeleteCardTitle' => ({required Object name}) => 'Delete card ${name}?',
			'card.confirmDeleteCardMessage' => 'All statements and transactions on this card will be deleted. Budget lines linked to this card will lose their source. This cannot be undone.',
			'card.confirmDeleteSubscriptionTitle' => ({required Object name}) => 'Delete the ${name} subscription?',
			'card.confirmDeleteSubscriptionMessage' => 'This subscription will no longer be added automatically each statement. Transactions already recorded are unaffected. This cannot be undone.',
			'grocery.pageTitle' => 'Grocery plan',
			'grocery.rollUpTotal' => 'Monthly total',
			'grocery.weeksPerMonthFieldHint' => 'Weeks per month multiplier',
			'grocery.weeklyTitle' => 'Weekly list',
			'grocery.monthlyTitle' => 'Monthly list',
			'grocery.emptyItems' => 'No items yet.',
			'grocery.addItemButton' => 'Add item',
			'grocery.editItemTitle' => 'Edit item',
			'grocery.itemNameFieldHint' => 'Item name',
			'grocery.quantityFieldHint' => 'Quantity',
			'grocery.unitPriceFieldHint' => 'Unit price (Rp)',
			'grocery.overridePriceLabel' => 'Override price',
			'grocery.overrideAmountFieldHint' => 'Override amount (Rp)',
			'grocery.overriddenBadge' => 'overridden',
			'grocery.cardEntryPointLabel' => 'Credit Card',
			'grocery.confirmDeleteItemTitle' => ({required Object name}) => 'Delete ${name}?',
			'grocery.confirmDeleteItemMessage' => 'The monthly grocery total will change, and any budget line linked to it will adjust accordingly. This cannot be undone.',
			'investment.pageTitle' => 'Investment',
			'investment.totalPortfolioTitle' => 'Total portfolio',
			'investment.goalsTitle' => 'Goals',
			'investment.emptyGoals' => 'No goals yet.',
			'investment.addGoalTitle' => 'Add goal',
			'investment.editGoalTitle' => 'Edit goal',
			'investment.goalNameFieldHint' => 'Goal name',
			'investment.openingBalanceFieldHint' => 'Opening balance (Rp)',
			'investment.allocationPlanTitle' => 'This month\'s allocation',
			'investment.cycleIdFieldHint' => 'Cycle',
			'investment.noCyclesAvailable' => 'No cycles available to pick from yet. Create a cycle in the Cycle tab first.',
			'investment.cycleNotFound' => 'This cycle doesn\'t exist yet.',
			'investment.cycleClosedMessage' => 'This cycle is closed. Reopen it to edit the allocation.',
			'investment.remainderLabel' => 'Cycle remainder',
			'investment.returnDepositFieldHint' => 'Extra funds (Rp)',
			'investment.percentageFieldHint' => '%',
			'investment.totalPercentageLabel' => ({required Object total}) => 'Total percentage: ${total}%',
			'investment.loansTitle' => 'Loans between goals',
			'investment.emptyLoans' => 'No loans yet.',
			'investment.addLoanTitle' => 'Add loan',
			'investment.editLoanTitle' => 'Edit loan',
			'investment.fromGoalFieldHint' => 'From goal',
			'investment.toGoalFieldHint' => 'To goal',
			'investment.principalFieldHint' => 'Principal (Rp)',
			'investment.repaidFieldHint' => 'Repaid (Rp)',
			'investment.noteFieldHint' => 'Note (optional)',
			'investment.historyTitle' => 'History',
			'investment.allocationHistoryLabel' => ({required Object cycleId}) => 'Allocation for cycle ${cycleId}',
			'investment.loanInLabel' => ({required Object fromName}) => 'Loan from ${fromName}',
			'investment.loanOutLabel' => ({required Object toName}) => 'Loan to ${toName}',
			'investment.loanRouteLabel' => ({required Object fromName, required Object toName}) => '${fromName} → ${toName}',
			'investment.loanAmountsLabel' => ({required Object principal, required Object repaid}) => 'Principal ${principal}, repaid ${repaid}',
			'investment.invalidTotalMessage' => 'Total percentage must be 0 or 100.',
			'investment.allocationSavedMessage' => 'Allocation plan saved.',
			'investment.loanSavedMessage' => 'Loan saved.',
			'investment.confirmDeleteGoalTitle' => ({required Object name}) => 'Delete the ${name} goal?',
			'investment.confirmDeleteGoalMessage' => 'The goal\'s balance and its entire allocation history will be deleted. This cannot be undone.',
			'investment.confirmDeleteLoanTitle' => 'Delete this loan?',
			'investment.confirmDeleteLoanMessage' => 'The principal and repayment records will be deleted, and both goals\' balances will change. This cannot be undone.',
			'shell.cycleTabLabel' => 'Cycle',
			'shell.incomeTabLabel' => 'Income',
			'shell.groceryTabLabel' => 'Grocery',
			'shell.investmentTabLabel' => 'Investment',
			_ => null,
		};
	}
}
