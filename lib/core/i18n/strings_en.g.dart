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
	@override late final _Translations$appShell$en appShell = _Translations$appShell$en._(_root);
	@override late final _Translations$record$en record = _Translations$record$en._(_root);
	@override late final _Translations$transaction$en transaction = _Translations$transaction$en._(_root);
	@override late final _Translations$wallet$en wallet = _Translations$wallet$en._(_root);
	@override late final _Translations$budget$en budget = _Translations$budget$en._(_root);
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

// Path: appShell
class _Translations$appShell$en extends Translations$appShell$id {
	_Translations$appShell$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get homeTabLabel => 'Home';
	@override String get budgetTabLabel => 'Budget';
	@override String get recordAction => 'Record';
	@override String get transactionsTabLabel => 'Transactions';
	@override String get walletsTabLabel => 'Wallets';
	@override String get comingSoonMessage => 'Coming soon.';
}

// Path: record
class _Translations$record$en extends Translations$record$id {
	_Translations$record$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get sheetTitle => 'Record Transaction';
	@override String get incomeAction => 'Record Income';
	@override String get expenseAction => 'Record Expense';
	@override String get transferAction => 'Record Transfer';
	@override String get toWalletFieldLabel => 'Into Wallet';
	@override String get fromWalletFieldLabel => 'From Wallet';
	@override String get destinationWalletFieldLabel => 'To Wallet';
	@override String get dateFieldLabel => 'Date';
	@override String get categoryFieldHint => 'Category (optional)';
	@override String get noteFieldHint => 'Write a short note';
	@override String get noWalletsMessage => 'No wallets yet. Create one in the Wallets tab first.';
	@override String get sameWalletWarning => 'Source and destination wallets can\'t be the same.';
	@override String get incomeSavedMessage => 'Income recorded.';
	@override String get expenseSavedMessage => 'Expense recorded.';
	@override String get transferSavedMessage => 'Transfer recorded.';
	@override String get disclaimerMessage => 'Saldough only records manual history. It never moves money automatically.';
	@override String get incomeSubtitle => 'Record money coming into one of your wallets.';
	@override String get expenseSubtitle => 'Record money going out of one of your wallets.';
	@override String get transferSubtitle => 'Record money moving between your own wallets.';
	@override String get incomeEffectLabel => 'Adds to wallet balance';
	@override String get expenseEffectLabel => 'Reduces wallet balance';
	@override String get transferEffectLabel => 'Total balance stays the same';
	@override String get walletNotSelectedPrompt => 'Not selected yet';
	@override String get savingMessage => 'Saving...';
	@override String get categorySuggestionSalary => 'Salary';
	@override String get categorySuggestionBonus => 'Bonus';
	@override String get categorySuggestionSales => 'Sales';
	@override String get categorySuggestionGift => 'Gift';
	@override String get categorySuggestionFood => 'Food';
	@override String get categorySuggestionShopping => 'Shopping';
	@override String get categorySuggestionTransport => 'Transport';
	@override String get categorySuggestionBills => 'Bills';
	@override String get sheetSubtitle => 'Pick the kind of financial event you want to record.';
	@override String get noticeTitle => 'Recording notice';
	@override String get examplesLabel => 'Examples:';
	@override String get incomeBadge => 'Money in';
	@override String get expenseBadge => 'Money out';
	@override String get transferBadge => 'Internal move';
	@override String get pickIncomeAction => 'Pick Income';
	@override String get pickExpenseAction => 'Pick Expense';
	@override String get pickTransferAction => 'Pick Transfer';
	@override String get transferExampleCash => 'Cash withdrawal';
	@override String get transferExampleTopUp => 'e-Wallet top-up';
	@override String get transferExampleMove => 'Move accounts';
	@override String get stepLabel => 'Step 2 // Transaction';
	@override String get editStepLabel => 'Edit // Transaction';
	@override String get expenseRuleTitle => 'Cash rule: balance is reduced';
	@override String get expenseRuleBody => 'An expense immediately reduces the balance of the wallet you pick below.';
	@override String get transferNoticeTitle => 'Important';
	@override String get transferNoticeBody => 'This records a money move you already made in the real world. It is not an automatic bank transfer.';
	@override String get amountLabelIncome => 'Income amount';
	@override String get amountLabelExpense => 'Expense amount';
	@override String get amountLabelTransfer => 'Transfer amount';
	@override String get clearAmountAction => 'Clear';
	@override String get categorySectionLabel => 'Category';
	@override String get optionalHint => 'Optional';
	@override String get categoryOtherLabel => 'Other';
	@override String get categoryCustomHint => 'Type your own category';
	@override String get categorySuggestionEntertainment => 'Fun';
	@override String get categorySuggestionInvestment => 'Investing';
	@override String get expenseWalletSectionLabel => 'Source wallet';
	@override String get noteSectionLabel => 'Note';
	@override String get balanceDecreasesCaption => 'Balance goes down';
	@override String get balanceIncreasesCaption => 'Balance goes up';
	@override String incomeSummary({required Object wallet, required Object amount}) => '${wallet} will go up by ${amount} once recorded.';
	@override String expenseSummary({required Object wallet, required Object amount}) => '${wallet} will go down by ${amount} once recorded.';
	@override String get transferSummaryTitle => 'Move summary';
	@override String transferSummaryFrom({required Object wallet, required Object amount}) => 'Wallet ${wallet} goes down ${amount}';
	@override String transferSummaryTo({required Object wallet, required Object amount}) => 'Wallet ${wallet} goes up ${amount}';
	@override String get footnote => '*Internal Saldough record. Does not debit or send money from any real bank account.';
	@override String get balanceLabel => 'Balance';
	@override String get categoryPlaceholder => 'Pick a category';
	@override String get categoryNoneLabel => 'No category';
	@override String get choiceStepLabel => 'Step 1 // Pick a type';
	@override String get flowOutside => 'Outside';
	@override String get flowWallet => 'Wallet';
	@override String get flowSourceWallet => 'Source wallet';
	@override String get flowTargetWallet => 'Target wallet';
	@override String get budgetItemLabel => 'Budget item';
	@override String get budgetItemNone => 'No budget';
	@override String get budgetItemHelp => 'Optional. Only active budget items from this wallet are offered.';
}

// Path: transaction
class _Translations$transaction$en extends Translations$transaction$id {
	_Translations$transaction$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pageTitle => 'Transactions';
	@override String get searchHint => 'Search notes / categories...';
	@override String get monthStatusLabel => 'This month\'s log status';
	@override String logCountBadge({required Object count}) => '${count} active logs';
	@override String get netFlowLabel => 'Net flow';
	@override String allFilterLabel({required Object count}) => 'All ${count}';
	@override String incomeFilterLabel({required Object count}) => 'Income ${count}';
	@override String expenseFilterLabel({required Object count}) => 'Expense ${count}';
	@override String transferFilterLabel({required Object count}) => 'Transfer ${count}';
	@override String get walletFilterAllLabel => 'All Wallets';
	@override String get walletFilterLabel => 'Wallet';
	@override String get categoryFilterAllLabel => 'All Categories';
	@override String get categoryFilterLabel => 'Category';
	@override String get todayLabel => 'Today';
	@override String get yesterdayLabel => 'Yesterday';
	@override String get incomeBadge => '+IN';
	@override String get expenseBadge => '-OUT';
	@override String get transferBadge => '# TRANSFER';
	@override String get untitledTransaction => 'Untitled';
	@override String get emptyMonthBadge => 'Empty Ledger';
	@override String get emptyMonthTitle => 'No transactions yet';
	@override String get emptyMonthSubtitle => 'Record an income, expense, or transfer to start seeing your daily cash history here.';
	@override String get emptyMonthCta => 'Record a Transaction Now';
	@override String get emptyGuideTitle => 'Recording guide';
	@override String get emptyGuideIncomeTitle => 'Income';
	@override String get emptyGuideIncomeDescription => 'Adds to your chosen wallet\'s balance, recorded for real in your ledger.';
	@override String get emptyGuideExpenseTitle => 'Expense';
	@override String get emptyGuideExpenseDescription => 'Reduces the wallet\'s balance and counts toward its monthly budget quota.';
	@override String get emptyGuideTransferTitle => 'Transfer Between Wallets';
	@override String get emptyGuideTransferDescription => 'Moves the recorded balance between wallets without changing your total net worth.';
	@override String get trustFooterMessage => 'Every transaction is recorded manually • 100% private, kept on your device';
	@override String get emptyFilterTitle => 'No transactions match the filter';
	@override String get emptyFilterSubtitle => 'Try changing or clearing the active filters.';
	@override String get clearFiltersButton => 'Clear filters';
	@override String get loadErrorTitle => 'Failed to load transactions';
	@override String get loadErrorSubtitle => 'Check and try loading again.';
	@override String get detailBackLabel => 'Back';
	@override String get detailIncomeTitle => 'Income recorded';
	@override String get detailExpenseTitle => 'Expense recorded';
	@override String get detailTransferTitle => 'Transfer recorded';
	@override String get detailTypeLabel => 'Entry type';
	@override String get detailIncomeType => 'Income';
	@override String get detailExpenseType => 'Expense';
	@override String get detailTransferType => 'Transfer between wallets';
	@override String get detailCategoryLabel => 'Category';
	@override String get detailIncomeWalletLabel => 'Destination Wallet';
	@override String get detailExpenseWalletLabel => 'Source Wallet';
	@override String get detailCurrentBalance => 'Current balance';
	@override String get detailNoteLabel => 'Manual Note';
	@override String get detailFromLabel => 'From';
	@override String get detailToLabel => 'To';
	@override String get detailAmountLabel => 'Amount';
	@override String get detailManualNote => 'This entry is a manual record in Saldough. Wallet balances are calculated from the data you enter, with no connection to a bank account.';
	@override String get editAction => 'Edit This Entry';
	@override String get deleteAction => 'Delete Entry from History';
	@override String get editSheetTitle => 'Edit Entry';
	@override String get saveChangesAction => 'Save Changes';
	@override String get deleteConfirmTitle => 'Delete this entry?';
	@override String get deleteConfirmMessage => 'The entry is removed from history, and wallet balances are recalculated without it.';
	@override String get updatedMessage => 'Changes saved.';
	@override String get deletedMessage => 'Entry deleted.';
	@override String get budgetLabel => 'Budget';
	@override String get openBudgetAction => 'View budget';
}

// Path: wallet
class _Translations$wallet$en extends Translations$wallet$id {
	_Translations$wallet$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get heading => 'My Wallets';
	@override String get subtitle => 'Where your cash stands right now';
	@override String activeBadge({required Object count}) => '${count} active';
	@override String get totalLabel => 'Total balance of all wallets';
	@override String get manualNoteTitle => 'Manual record';
	@override String get manualNoteBody => 'Balances are computed from the entries you record yourself, not synced automatically from any bank.';
	@override String get listHeading => 'Wallets';
	@override String get balanceLabel => 'Current balance';
	@override String get addAction => 'Add New Wallet';
	@override String get inactiveHeading => 'Inactive Wallets';
	@override String get inactiveBadge => 'Inactive';
	@override String get typeBank => 'Bank account';
	@override String get typeCash => 'Cash';
	@override String get typeEwallet => 'Digital wallet';
	@override String get typeSavings => 'Savings';
	@override String get typeCard => 'Card';
	@override String get emptyBadge => 'No wallets yet';
	@override String get emptyTitle => 'No wallets recorded yet';
	@override String get emptyBody => 'Add your first wallet to start recording where your money is. It can be a bank account, an e-wallet, or cash in your pocket.';
	@override String get loadErrorTitle => 'Couldn\'t load wallets';
	@override String get loadErrorSubtitle => 'Wallet data couldn\'t be read. Try again.';
	@override String get addTitle => 'Add New Wallet';
	@override String get editTitle => 'Edit Wallet';
	@override String get addStepLabel => 'Wallet // New';
	@override String get editStepLabel => 'Wallet // Edit';
	@override String get nameLabel => 'Wallet name';
	@override String get nameHint => 'E.g. Mandiri Savings, OVO, Cash Box';
	@override String get nameRequiredHint => 'Required';
	@override String get nameMaxHint => 'Max. 24 characters';
	@override String get iconLabel => 'Pick an icon';
	@override String get initialBalanceLabel => 'Starting balance right now';
	@override String get initialBalanceHelp => 'The starting balance is the money there right now, before you began recording. It states a situation, it is not a deposit, so it never shows in history.';
	@override String get currentBalanceLabel => 'Recorded balance right now';
	@override String get editBalanceNote => 'Changing the starting balance recomputes the recorded balance. For a gap with real money, record an income or expense via RECORD.';
	@override String get activeSwitchLabel => 'Wallet is active';
	@override String get activeSwitchHelp => 'Inactive wallets don\'t appear in wallet pickers. Their transactions stay saved and counted.';
	@override String get saveAddAction => 'Save Wallet';
	@override String get deleteAction => 'Delete Wallet';
	@override String get deleteHelp => 'Can only be deleted if it has no transactions at all. Otherwise, deactivate it.';
	@override String get deleteConfirmTitle => 'Delete wallet?';
	@override String deleteConfirmMessage({required Object name}) => 'Wallet ${name} will be deleted permanently. This can\'t be undone.';
	@override String get savedMessage => 'Wallet saved.';
	@override String get updatedMessage => 'Wallet updated.';
	@override String get deletedMessage => 'Wallet deleted.';
	@override String get deleteBlockedMessage => 'This wallet already has transactions, so it can\'t be deleted. Deactivate it instead.';
	@override String get privacyNote => 'Data is stored locally and privately on your device.';
	@override String get detailBackLabel => 'Back';
	@override String get detailEditAction => 'Edit';
	@override String get detailRecentHeading => 'This Month\'s Transactions';
	@override String get detailIncomeLabel => 'In';
	@override String get detailExpenseLabel => 'Out';
	@override String get detailNetLabel => 'Net';
	@override String get detailRecentEmptyTitle => 'No transactions yet';
	@override String get detailRecentEmpty => 'No transactions this month for this wallet yet.';
	@override String get detailViewAllAction => 'View All Transactions';
	@override String get detailRecordAction => 'Record a Transaction for This Wallet';
}

// Path: budget
class _Translations$budget$en extends Translations$budget$id {
	_Translations$budget$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get heading => 'My Budgets';
	@override String activeBadge({required Object count}) => '${count} active';
	@override String get summaryTitle => 'Total of active budgets';
	@override String summaryPercent({required Object percent}) => '${percent}% spent';
	@override String get plannedLabel => 'Planned';
	@override String get spentLabel => 'Spent';
	@override String get remainingLabel => 'Remaining';
	@override String spentPercentLabel({required Object percent}) => 'Spent (${percent}%)';
	@override String get summaryNote => 'A budget is a spending plan, not a deduction from your wallet. Balances only change when an expense or transfer is recorded.';
	@override String get filterAll => 'All';
	@override String get filterActive => 'Active';
	@override String get filterFinished => 'Finished';
	@override String get filterArchived => 'Inactive';
	@override String get filterWalletLabel => 'Wallet';
	@override String get filterWalletAll => 'All wallets';
	@override String get addAction => 'Create New Budget';
	@override String get periodWeekly => 'Weekly';
	@override String get periodMonthly => 'Monthly';
	@override String get itemStatusPlanned => 'Not yet spent';
	@override String get itemStatusPartiallySpent => 'Partially spent';
	@override String get itemStatusCompleted => 'Completed';
	@override String get itemStatusOverspent => 'Over budget';
	@override String itemCount({required Object count}) => '${count} items';
	@override String get emptyBadge => 'No plans yet';
	@override String get emptyTitle => 'No budgets yet';
	@override String get emptyBody => 'Plan a weekly or monthly spending limit for one wallet. Creating a budget does not reduce any wallet balance.';
	@override String get emptyFilteredTitle => 'No matching budgets';
	@override String get emptyFilteredBody => 'No budget has the selected status and wallet.';
	@override String get resetFilterAction => 'Show all budgets';
	@override String get noWalletTitle => 'Create a wallet first';
	@override String get noWalletBody => 'Every budget belongs to one wallet. Add a wallet in the Wallets tab, then come back here.';
	@override String get loadErrorTitle => 'Budgets failed to load';
	@override String get loadErrorSubtitle => 'Budget data could not be read. Try again.';
	@override String get savedMessage => 'Budget saved.';
	@override String get updatedMessage => 'Budget changes saved.';
	@override String get deletedMessage => 'Budget deleted.';
	@override String get archivedMessage => 'Budget archived.';
	@override String get unarchivedMessage => 'Budget reactivated.';
	@override String get addStepLabel => 'New budget';
	@override String get editStepLabel => 'Edit budget';
	@override String get addTitle => 'Create Budget';
	@override String get editTitle => 'Edit Budget';
	@override String get ruleTitle => 'Budget rule';
	@override String get ruleBody => 'This plan does not deduct from your wallet. The balance only decreases when you record a transaction.';
	@override String get nameLabel => 'Budget name';
	@override String get nameHint => 'Example: Household Needs';
	@override String get requiredHint => 'Required';
	@override String get walletLabel => 'Linked wallet';
	@override String get walletHelp => 'Only expenses and outgoing transfers from this wallet count toward the budget.';
	@override String walletBalance({required Object amount}) => 'Balance: ${amount}';
	@override String get periodLabel => 'Period';
	@override String get startDateLabel => 'Starts';
	@override String periodRange({required Object start, required Object end}) => '${start} – ${end}';
	@override String get plannedAmountLabel => 'Planned amount';
	@override String get plannedAmountHelp => 'The limit for the whole budget. It does not have to equal the sum of its items.';
	@override String get itemsLabel => 'Budget items';
	@override String get itemsHelp => 'Planned purchases or planned transfers. Optional.';
	@override String get addItemAction => 'Add Item';
	@override String get itemsTotalLabel => 'Sum of all items';
	@override String get differenceLabel => 'Difference from plan';
	@override String get useItemsTotalAction => 'Use item total';
	@override String get saveAddAction => 'Save Budget';
	@override String get archiveAction => 'Archive Budget';
	@override String get unarchiveAction => 'Reactivate';
	@override String get archiveHelp => 'Inactive budgets are hidden from the active list. Linked transactions stay recorded.';
	@override String get deleteAction => 'Delete Budget';
	@override String get deleteConfirmTitle => 'Delete budget?';
	@override String deleteConfirmMessage({required Object name}) => 'Budget "${name}" and its items will be deleted. Linked transactions stay recorded and wallet balances do not change.';
	@override String get itemAddTitle => 'Add Item';
	@override String get itemEditTitle => 'Edit Item';
	@override String get itemNameLabel => 'Item name';
	@override String get itemNameHint => 'Example: Rice';
	@override String get itemModeAmount => 'Amount';
	@override String get itemModeItemized => 'Quantity × price';
	@override String get itemAmountLabel => 'Planned amount';
	@override String get itemQuantityLabel => 'Quantity';
	@override String get itemUnitPriceLabel => 'Unit price';
	@override String get itemTotalLabel => 'Item total';
	@override String itemItemizedDetail({required Object quantity, required Object price}) => '${quantity} × ${price}';
	@override String get itemSaveAction => 'Save Item';
	@override String get itemDeleteAction => 'Delete Item';
	@override String get detailBackLabel => 'Budget List';
	@override String get detailEditAction => 'Edit budget';
	@override String get detailRecordExpenseAction => 'Record Expense';
	@override String get detailRecordTransferAction => 'Record Transfer';
	@override String get detailItemsHeading => 'Budget Items';
	@override String get detailNoItems => 'This budget has no items yet. Add items via Edit so expenses can be linked.';
	@override String get detailLinkedHeading => 'Linked Transactions';
	@override String get detailLinkedEmpty => 'No transactions are linked to this budget yet.';
	@override String get detailHowTitle => 'How budget items work';
	@override String detailHowBody({required Object wallet}) => 'When recording an expense or transfer from ${wallet}, pick one of these items. Spent grows from that transaction; the budget itself never deducts a balance.';
	@override String get unknownWallet => 'Wallet not found';
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
			'appShell.homeTabLabel' => 'Home',
			'appShell.budgetTabLabel' => 'Budget',
			'appShell.recordAction' => 'Record',
			'appShell.transactionsTabLabel' => 'Transactions',
			'appShell.walletsTabLabel' => 'Wallets',
			'appShell.comingSoonMessage' => 'Coming soon.',
			'record.sheetTitle' => 'Record Transaction',
			'record.incomeAction' => 'Record Income',
			'record.expenseAction' => 'Record Expense',
			'record.transferAction' => 'Record Transfer',
			'record.toWalletFieldLabel' => 'Into Wallet',
			'record.fromWalletFieldLabel' => 'From Wallet',
			'record.destinationWalletFieldLabel' => 'To Wallet',
			'record.dateFieldLabel' => 'Date',
			'record.categoryFieldHint' => 'Category (optional)',
			'record.noteFieldHint' => 'Write a short note',
			'record.noWalletsMessage' => 'No wallets yet. Create one in the Wallets tab first.',
			'record.sameWalletWarning' => 'Source and destination wallets can\'t be the same.',
			'record.incomeSavedMessage' => 'Income recorded.',
			'record.expenseSavedMessage' => 'Expense recorded.',
			'record.transferSavedMessage' => 'Transfer recorded.',
			'record.disclaimerMessage' => 'Saldough only records manual history. It never moves money automatically.',
			'record.incomeSubtitle' => 'Record money coming into one of your wallets.',
			'record.expenseSubtitle' => 'Record money going out of one of your wallets.',
			'record.transferSubtitle' => 'Record money moving between your own wallets.',
			'record.incomeEffectLabel' => 'Adds to wallet balance',
			'record.expenseEffectLabel' => 'Reduces wallet balance',
			'record.transferEffectLabel' => 'Total balance stays the same',
			'record.walletNotSelectedPrompt' => 'Not selected yet',
			'record.savingMessage' => 'Saving...',
			'record.categorySuggestionSalary' => 'Salary',
			'record.categorySuggestionBonus' => 'Bonus',
			'record.categorySuggestionSales' => 'Sales',
			'record.categorySuggestionGift' => 'Gift',
			'record.categorySuggestionFood' => 'Food',
			'record.categorySuggestionShopping' => 'Shopping',
			'record.categorySuggestionTransport' => 'Transport',
			'record.categorySuggestionBills' => 'Bills',
			'record.sheetSubtitle' => 'Pick the kind of financial event you want to record.',
			'record.noticeTitle' => 'Recording notice',
			'record.examplesLabel' => 'Examples:',
			'record.incomeBadge' => 'Money in',
			'record.expenseBadge' => 'Money out',
			'record.transferBadge' => 'Internal move',
			'record.pickIncomeAction' => 'Pick Income',
			'record.pickExpenseAction' => 'Pick Expense',
			'record.pickTransferAction' => 'Pick Transfer',
			'record.transferExampleCash' => 'Cash withdrawal',
			'record.transferExampleTopUp' => 'e-Wallet top-up',
			'record.transferExampleMove' => 'Move accounts',
			'record.stepLabel' => 'Step 2 // Transaction',
			'record.editStepLabel' => 'Edit // Transaction',
			'record.expenseRuleTitle' => 'Cash rule: balance is reduced',
			'record.expenseRuleBody' => 'An expense immediately reduces the balance of the wallet you pick below.',
			'record.transferNoticeTitle' => 'Important',
			'record.transferNoticeBody' => 'This records a money move you already made in the real world. It is not an automatic bank transfer.',
			'record.amountLabelIncome' => 'Income amount',
			'record.amountLabelExpense' => 'Expense amount',
			'record.amountLabelTransfer' => 'Transfer amount',
			'record.clearAmountAction' => 'Clear',
			'record.categorySectionLabel' => 'Category',
			'record.optionalHint' => 'Optional',
			'record.categoryOtherLabel' => 'Other',
			'record.categoryCustomHint' => 'Type your own category',
			'record.categorySuggestionEntertainment' => 'Fun',
			'record.categorySuggestionInvestment' => 'Investing',
			'record.expenseWalletSectionLabel' => 'Source wallet',
			'record.noteSectionLabel' => 'Note',
			'record.balanceDecreasesCaption' => 'Balance goes down',
			'record.balanceIncreasesCaption' => 'Balance goes up',
			'record.incomeSummary' => ({required Object wallet, required Object amount}) => '${wallet} will go up by ${amount} once recorded.',
			'record.expenseSummary' => ({required Object wallet, required Object amount}) => '${wallet} will go down by ${amount} once recorded.',
			'record.transferSummaryTitle' => 'Move summary',
			'record.transferSummaryFrom' => ({required Object wallet, required Object amount}) => 'Wallet ${wallet} goes down ${amount}',
			'record.transferSummaryTo' => ({required Object wallet, required Object amount}) => 'Wallet ${wallet} goes up ${amount}',
			'record.footnote' => '*Internal Saldough record. Does not debit or send money from any real bank account.',
			'record.balanceLabel' => 'Balance',
			'record.categoryPlaceholder' => 'Pick a category',
			'record.categoryNoneLabel' => 'No category',
			'record.choiceStepLabel' => 'Step 1 // Pick a type',
			'record.flowOutside' => 'Outside',
			'record.flowWallet' => 'Wallet',
			'record.flowSourceWallet' => 'Source wallet',
			'record.flowTargetWallet' => 'Target wallet',
			'record.budgetItemLabel' => 'Budget item',
			'record.budgetItemNone' => 'No budget',
			'record.budgetItemHelp' => 'Optional. Only active budget items from this wallet are offered.',
			'transaction.pageTitle' => 'Transactions',
			'transaction.searchHint' => 'Search notes / categories...',
			'transaction.monthStatusLabel' => 'This month\'s log status',
			'transaction.logCountBadge' => ({required Object count}) => '${count} active logs',
			'transaction.netFlowLabel' => 'Net flow',
			'transaction.allFilterLabel' => ({required Object count}) => 'All ${count}',
			'transaction.incomeFilterLabel' => ({required Object count}) => 'Income ${count}',
			'transaction.expenseFilterLabel' => ({required Object count}) => 'Expense ${count}',
			'transaction.transferFilterLabel' => ({required Object count}) => 'Transfer ${count}',
			'transaction.walletFilterAllLabel' => 'All Wallets',
			'transaction.walletFilterLabel' => 'Wallet',
			'transaction.categoryFilterAllLabel' => 'All Categories',
			'transaction.categoryFilterLabel' => 'Category',
			'transaction.todayLabel' => 'Today',
			'transaction.yesterdayLabel' => 'Yesterday',
			'transaction.incomeBadge' => '+IN',
			'transaction.expenseBadge' => '-OUT',
			'transaction.transferBadge' => '# TRANSFER',
			'transaction.untitledTransaction' => 'Untitled',
			'transaction.emptyMonthBadge' => 'Empty Ledger',
			'transaction.emptyMonthTitle' => 'No transactions yet',
			'transaction.emptyMonthSubtitle' => 'Record an income, expense, or transfer to start seeing your daily cash history here.',
			'transaction.emptyMonthCta' => 'Record a Transaction Now',
			'transaction.emptyGuideTitle' => 'Recording guide',
			'transaction.emptyGuideIncomeTitle' => 'Income',
			'transaction.emptyGuideIncomeDescription' => 'Adds to your chosen wallet\'s balance, recorded for real in your ledger.',
			'transaction.emptyGuideExpenseTitle' => 'Expense',
			'transaction.emptyGuideExpenseDescription' => 'Reduces the wallet\'s balance and counts toward its monthly budget quota.',
			'transaction.emptyGuideTransferTitle' => 'Transfer Between Wallets',
			'transaction.emptyGuideTransferDescription' => 'Moves the recorded balance between wallets without changing your total net worth.',
			'transaction.trustFooterMessage' => 'Every transaction is recorded manually • 100% private, kept on your device',
			'transaction.emptyFilterTitle' => 'No transactions match the filter',
			'transaction.emptyFilterSubtitle' => 'Try changing or clearing the active filters.',
			'transaction.clearFiltersButton' => 'Clear filters',
			'transaction.loadErrorTitle' => 'Failed to load transactions',
			'transaction.loadErrorSubtitle' => 'Check and try loading again.',
			'transaction.detailBackLabel' => 'Back',
			'transaction.detailIncomeTitle' => 'Income recorded',
			'transaction.detailExpenseTitle' => 'Expense recorded',
			'transaction.detailTransferTitle' => 'Transfer recorded',
			'transaction.detailTypeLabel' => 'Entry type',
			'transaction.detailIncomeType' => 'Income',
			'transaction.detailExpenseType' => 'Expense',
			'transaction.detailTransferType' => 'Transfer between wallets',
			'transaction.detailCategoryLabel' => 'Category',
			'transaction.detailIncomeWalletLabel' => 'Destination Wallet',
			'transaction.detailExpenseWalletLabel' => 'Source Wallet',
			'transaction.detailCurrentBalance' => 'Current balance',
			'transaction.detailNoteLabel' => 'Manual Note',
			'transaction.detailFromLabel' => 'From',
			'transaction.detailToLabel' => 'To',
			'transaction.detailAmountLabel' => 'Amount',
			'transaction.detailManualNote' => 'This entry is a manual record in Saldough. Wallet balances are calculated from the data you enter, with no connection to a bank account.',
			'transaction.editAction' => 'Edit This Entry',
			'transaction.deleteAction' => 'Delete Entry from History',
			'transaction.editSheetTitle' => 'Edit Entry',
			'transaction.saveChangesAction' => 'Save Changes',
			'transaction.deleteConfirmTitle' => 'Delete this entry?',
			'transaction.deleteConfirmMessage' => 'The entry is removed from history, and wallet balances are recalculated without it.',
			'transaction.updatedMessage' => 'Changes saved.',
			'transaction.deletedMessage' => 'Entry deleted.',
			'transaction.budgetLabel' => 'Budget',
			'transaction.openBudgetAction' => 'View budget',
			'wallet.heading' => 'My Wallets',
			'wallet.subtitle' => 'Where your cash stands right now',
			'wallet.activeBadge' => ({required Object count}) => '${count} active',
			'wallet.totalLabel' => 'Total balance of all wallets',
			'wallet.manualNoteTitle' => 'Manual record',
			'wallet.manualNoteBody' => 'Balances are computed from the entries you record yourself, not synced automatically from any bank.',
			'wallet.listHeading' => 'Wallets',
			'wallet.balanceLabel' => 'Current balance',
			'wallet.addAction' => 'Add New Wallet',
			'wallet.inactiveHeading' => 'Inactive Wallets',
			'wallet.inactiveBadge' => 'Inactive',
			'wallet.typeBank' => 'Bank account',
			'wallet.typeCash' => 'Cash',
			'wallet.typeEwallet' => 'Digital wallet',
			'wallet.typeSavings' => 'Savings',
			'wallet.typeCard' => 'Card',
			'wallet.emptyBadge' => 'No wallets yet',
			'wallet.emptyTitle' => 'No wallets recorded yet',
			'wallet.emptyBody' => 'Add your first wallet to start recording where your money is. It can be a bank account, an e-wallet, or cash in your pocket.',
			'wallet.loadErrorTitle' => 'Couldn\'t load wallets',
			'wallet.loadErrorSubtitle' => 'Wallet data couldn\'t be read. Try again.',
			'wallet.addTitle' => 'Add New Wallet',
			'wallet.editTitle' => 'Edit Wallet',
			'wallet.addStepLabel' => 'Wallet // New',
			'wallet.editStepLabel' => 'Wallet // Edit',
			'wallet.nameLabel' => 'Wallet name',
			'wallet.nameHint' => 'E.g. Mandiri Savings, OVO, Cash Box',
			'wallet.nameRequiredHint' => 'Required',
			'wallet.nameMaxHint' => 'Max. 24 characters',
			'wallet.iconLabel' => 'Pick an icon',
			'wallet.initialBalanceLabel' => 'Starting balance right now',
			'wallet.initialBalanceHelp' => 'The starting balance is the money there right now, before you began recording. It states a situation, it is not a deposit, so it never shows in history.',
			'wallet.currentBalanceLabel' => 'Recorded balance right now',
			'wallet.editBalanceNote' => 'Changing the starting balance recomputes the recorded balance. For a gap with real money, record an income or expense via RECORD.',
			'wallet.activeSwitchLabel' => 'Wallet is active',
			'wallet.activeSwitchHelp' => 'Inactive wallets don\'t appear in wallet pickers. Their transactions stay saved and counted.',
			'wallet.saveAddAction' => 'Save Wallet',
			'wallet.deleteAction' => 'Delete Wallet',
			'wallet.deleteHelp' => 'Can only be deleted if it has no transactions at all. Otherwise, deactivate it.',
			'wallet.deleteConfirmTitle' => 'Delete wallet?',
			'wallet.deleteConfirmMessage' => ({required Object name}) => 'Wallet ${name} will be deleted permanently. This can\'t be undone.',
			'wallet.savedMessage' => 'Wallet saved.',
			'wallet.updatedMessage' => 'Wallet updated.',
			'wallet.deletedMessage' => 'Wallet deleted.',
			'wallet.deleteBlockedMessage' => 'This wallet already has transactions, so it can\'t be deleted. Deactivate it instead.',
			'wallet.privacyNote' => 'Data is stored locally and privately on your device.',
			'wallet.detailBackLabel' => 'Back',
			'wallet.detailEditAction' => 'Edit',
			'wallet.detailRecentHeading' => 'This Month\'s Transactions',
			'wallet.detailIncomeLabel' => 'In',
			'wallet.detailExpenseLabel' => 'Out',
			'wallet.detailNetLabel' => 'Net',
			'wallet.detailRecentEmptyTitle' => 'No transactions yet',
			'wallet.detailRecentEmpty' => 'No transactions this month for this wallet yet.',
			'wallet.detailViewAllAction' => 'View All Transactions',
			'wallet.detailRecordAction' => 'Record a Transaction for This Wallet',
			'budget.heading' => 'My Budgets',
			'budget.activeBadge' => ({required Object count}) => '${count} active',
			'budget.summaryTitle' => 'Total of active budgets',
			'budget.summaryPercent' => ({required Object percent}) => '${percent}% spent',
			'budget.plannedLabel' => 'Planned',
			'budget.spentLabel' => 'Spent',
			'budget.remainingLabel' => 'Remaining',
			'budget.spentPercentLabel' => ({required Object percent}) => 'Spent (${percent}%)',
			'budget.summaryNote' => 'A budget is a spending plan, not a deduction from your wallet. Balances only change when an expense or transfer is recorded.',
			'budget.filterAll' => 'All',
			'budget.filterActive' => 'Active',
			'budget.filterFinished' => 'Finished',
			'budget.filterArchived' => 'Inactive',
			'budget.filterWalletLabel' => 'Wallet',
			'budget.filterWalletAll' => 'All wallets',
			'budget.addAction' => 'Create New Budget',
			'budget.periodWeekly' => 'Weekly',
			'budget.periodMonthly' => 'Monthly',
			'budget.itemStatusPlanned' => 'Not yet spent',
			'budget.itemStatusPartiallySpent' => 'Partially spent',
			'budget.itemStatusCompleted' => 'Completed',
			'budget.itemStatusOverspent' => 'Over budget',
			'budget.itemCount' => ({required Object count}) => '${count} items',
			'budget.emptyBadge' => 'No plans yet',
			'budget.emptyTitle' => 'No budgets yet',
			'budget.emptyBody' => 'Plan a weekly or monthly spending limit for one wallet. Creating a budget does not reduce any wallet balance.',
			'budget.emptyFilteredTitle' => 'No matching budgets',
			'budget.emptyFilteredBody' => 'No budget has the selected status and wallet.',
			'budget.resetFilterAction' => 'Show all budgets',
			'budget.noWalletTitle' => 'Create a wallet first',
			'budget.noWalletBody' => 'Every budget belongs to one wallet. Add a wallet in the Wallets tab, then come back here.',
			'budget.loadErrorTitle' => 'Budgets failed to load',
			'budget.loadErrorSubtitle' => 'Budget data could not be read. Try again.',
			'budget.savedMessage' => 'Budget saved.',
			'budget.updatedMessage' => 'Budget changes saved.',
			'budget.deletedMessage' => 'Budget deleted.',
			'budget.archivedMessage' => 'Budget archived.',
			'budget.unarchivedMessage' => 'Budget reactivated.',
			'budget.addStepLabel' => 'New budget',
			'budget.editStepLabel' => 'Edit budget',
			'budget.addTitle' => 'Create Budget',
			'budget.editTitle' => 'Edit Budget',
			'budget.ruleTitle' => 'Budget rule',
			'budget.ruleBody' => 'This plan does not deduct from your wallet. The balance only decreases when you record a transaction.',
			'budget.nameLabel' => 'Budget name',
			'budget.nameHint' => 'Example: Household Needs',
			'budget.requiredHint' => 'Required',
			'budget.walletLabel' => 'Linked wallet',
			'budget.walletHelp' => 'Only expenses and outgoing transfers from this wallet count toward the budget.',
			'budget.walletBalance' => ({required Object amount}) => 'Balance: ${amount}',
			'budget.periodLabel' => 'Period',
			'budget.startDateLabel' => 'Starts',
			'budget.periodRange' => ({required Object start, required Object end}) => '${start} – ${end}',
			'budget.plannedAmountLabel' => 'Planned amount',
			'budget.plannedAmountHelp' => 'The limit for the whole budget. It does not have to equal the sum of its items.',
			'budget.itemsLabel' => 'Budget items',
			'budget.itemsHelp' => 'Planned purchases or planned transfers. Optional.',
			'budget.addItemAction' => 'Add Item',
			'budget.itemsTotalLabel' => 'Sum of all items',
			'budget.differenceLabel' => 'Difference from plan',
			'budget.useItemsTotalAction' => 'Use item total',
			'budget.saveAddAction' => 'Save Budget',
			'budget.archiveAction' => 'Archive Budget',
			'budget.unarchiveAction' => 'Reactivate',
			'budget.archiveHelp' => 'Inactive budgets are hidden from the active list. Linked transactions stay recorded.',
			'budget.deleteAction' => 'Delete Budget',
			'budget.deleteConfirmTitle' => 'Delete budget?',
			'budget.deleteConfirmMessage' => ({required Object name}) => 'Budget "${name}" and its items will be deleted. Linked transactions stay recorded and wallet balances do not change.',
			'budget.itemAddTitle' => 'Add Item',
			'budget.itemEditTitle' => 'Edit Item',
			'budget.itemNameLabel' => 'Item name',
			'budget.itemNameHint' => 'Example: Rice',
			'budget.itemModeAmount' => 'Amount',
			'budget.itemModeItemized' => 'Quantity × price',
			'budget.itemAmountLabel' => 'Planned amount',
			'budget.itemQuantityLabel' => 'Quantity',
			'budget.itemUnitPriceLabel' => 'Unit price',
			'budget.itemTotalLabel' => 'Item total',
			'budget.itemItemizedDetail' => ({required Object quantity, required Object price}) => '${quantity} × ${price}',
			'budget.itemSaveAction' => 'Save Item',
			'budget.itemDeleteAction' => 'Delete Item',
			'budget.detailBackLabel' => 'Budget List',
			'budget.detailEditAction' => 'Edit budget',
			'budget.detailRecordExpenseAction' => 'Record Expense',
			'budget.detailRecordTransferAction' => 'Record Transfer',
			'budget.detailItemsHeading' => 'Budget Items',
			'budget.detailNoItems' => 'This budget has no items yet. Add items via Edit so expenses can be linked.',
			'budget.detailLinkedHeading' => 'Linked Transactions',
			'budget.detailLinkedEmpty' => 'No transactions are linked to this budget yet.',
			'budget.detailHowTitle' => 'How budget items work',
			'budget.detailHowBody' => ({required Object wallet}) => 'When recording an expense or transfer from ${wallet}, pick one of these items. Spent grows from that transaction; the budget itself never deducts a balance.',
			'budget.unknownWallet' => 'Wallet not found',
			_ => null,
		};
	}
}
