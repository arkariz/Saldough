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
	@override String get confirmDeleteMessage => 'This action cannot be undone.';
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
	@override String get closeCycle => 'Close cycle';
	@override String get reopenCycle => 'Reopen';
	@override String get closedBanner => 'This cycle is closed.';
	@override String get closedCannotEdit => 'This cycle is closed. Reopen it to make changes.';
	@override String get rollUpNotEditable => 'This line is calculated automatically and can\'t be edited directly.';
	@override String get rollUpSourceUnavailable => 'Source not available yet';
	@override String get markFixed => 'Mark as fixed';
	@override String get markIncidental => 'Mark as one-off';
	@override String get needsReviewBadge => 'Needs review';
	@override String get confirmReviewed => 'Looks right';
	@override String unreviewedBanner({required Object count}) => '${count} line(s) need review.';
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
	@override String get targetCycleHint => 'Target cycle (YYYY-MM)';
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
	@override String get openStatementTitle => 'Open statement';
	@override String get pendingConfirmationTitle => 'Needs confirmation';
	@override String get closeStatementButton => 'Close statement';
	@override String get statementClosedMessage => 'Statement closed. Next statement opened.';
	@override String get addTransactionTitle => 'Log transaction';
	@override String get merchantFieldHint => 'Merchant';
	@override String get amountFieldHint => 'Amount (Rp)';
	@override String get noteFieldHint => 'Note (optional)';
	@override String get addTransactionButton => 'Log';
	@override String get subscriptionsTitle => 'Recurring subscriptions';
	@override String get emptySubscriptions => 'No subscriptions yet.';
	@override String get addSubscriptionTitle => 'Add subscription';
	@override String get editSubscriptionTitle => 'Edit subscription';
	@override String get subscriptionDayFieldHint => 'Day prepared each month';
	@override String get subscriptionActiveLabel => 'Active';
	@override String subscriptionSubtitle({required Object amount, required Object day}) => '${amount} / month, day ${day}';
	@override String get subscriptionInactiveBadge => 'Inactive';
	@override String get historyTitle => 'Statement history';
	@override String get emptyHistory => 'No closed statements yet.';
	@override String statementPeriodLabel({required Object start, required Object end}) => '${start} – ${end}';
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
	@override String get cycleIdFieldHint => 'Cycle (YYYY-MM)';
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
			'common.confirmDeleteMessage' => 'This action cannot be undone.',
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
			'cycle.closeCycle' => 'Close cycle',
			'cycle.reopenCycle' => 'Reopen',
			'cycle.closedBanner' => 'This cycle is closed.',
			'cycle.closedCannotEdit' => 'This cycle is closed. Reopen it to make changes.',
			'cycle.rollUpNotEditable' => 'This line is calculated automatically and can\'t be edited directly.',
			'cycle.rollUpSourceUnavailable' => 'Source not available yet',
			'cycle.markFixed' => 'Mark as fixed',
			'cycle.markIncidental' => 'Mark as one-off',
			'cycle.needsReviewBadge' => 'Needs review',
			'cycle.confirmReviewed' => 'Looks right',
			'cycle.unreviewedBanner' => ({required Object count}) => '${count} line(s) need review.',
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
			'worklog.targetCycleHint' => 'Target cycle (YYYY-MM)',
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
			'card.openStatementTitle' => 'Open statement',
			'card.pendingConfirmationTitle' => 'Needs confirmation',
			'card.closeStatementButton' => 'Close statement',
			'card.statementClosedMessage' => 'Statement closed. Next statement opened.',
			'card.addTransactionTitle' => 'Log transaction',
			'card.merchantFieldHint' => 'Merchant',
			'card.amountFieldHint' => 'Amount (Rp)',
			'card.noteFieldHint' => 'Note (optional)',
			'card.addTransactionButton' => 'Log',
			'card.subscriptionsTitle' => 'Recurring subscriptions',
			'card.emptySubscriptions' => 'No subscriptions yet.',
			'card.addSubscriptionTitle' => 'Add subscription',
			'card.editSubscriptionTitle' => 'Edit subscription',
			'card.subscriptionDayFieldHint' => 'Day prepared each month',
			'card.subscriptionActiveLabel' => 'Active',
			'card.subscriptionSubtitle' => ({required Object amount, required Object day}) => '${amount} / month, day ${day}',
			'card.subscriptionInactiveBadge' => 'Inactive',
			'card.historyTitle' => 'Statement history',
			'card.emptyHistory' => 'No closed statements yet.',
			'card.statementPeriodLabel' => ({required Object start, required Object end}) => '${start} – ${end}',
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
			'investment.pageTitle' => 'Investment',
			'investment.totalPortfolioTitle' => 'Total portfolio',
			'investment.goalsTitle' => 'Goals',
			'investment.emptyGoals' => 'No goals yet.',
			'investment.addGoalTitle' => 'Add goal',
			'investment.editGoalTitle' => 'Edit goal',
			'investment.goalNameFieldHint' => 'Goal name',
			'investment.openingBalanceFieldHint' => 'Opening balance (Rp)',
			'investment.allocationPlanTitle' => 'This month\'s allocation',
			'investment.cycleIdFieldHint' => 'Cycle (YYYY-MM)',
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
			'shell.cycleTabLabel' => 'Cycle',
			'shell.incomeTabLabel' => 'Income',
			'shell.groceryTabLabel' => 'Grocery',
			'shell.investmentTabLabel' => 'Investment',
			_ => null,
		};
	}
}
