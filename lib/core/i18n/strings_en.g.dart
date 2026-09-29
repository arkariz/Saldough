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
	@override late final _Translations$freelance$en freelance = _Translations$freelance$en._(_root);
	@override late final _Translations$home$en home = _Translations$home$en._(_root);
	@override late final _Translations$onboarding$en onboarding = _Translations$onboarding$en._(_root);
	@override late final _Translations$tour$en tour = _Translations$tour$en._(_root);
	@override late final _Translations$info$en info = _Translations$info$en._(_root);
	@override late final _Translations$account$en account = _Translations$account$en._(_root);
	@override late final _Translations$currency$en currency = _Translations$currency$en._(_root);
}

// Path: app
class _Translations$app$en extends Translations$app$id {
	_Translations$app$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tanukonomy';
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
}

// Path: record
class _Translations$record$en extends Translations$record$id {
	_Translations$record$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
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
	@override String get incomeBadge => 'Money in';
	@override String get expenseBadge => 'Money out';
	@override String get transferBadge => 'Internal move';
	@override String get stepLabel => 'Record // Transaction';
	@override String get editStepLabel => 'Edit // Transaction';
	@override String get expenseRuleTitle => 'Cash rule: balance is reduced';
	@override String get expenseRuleBody => 'An expense immediately reduces the balance of the wallet you pick below.';
	@override String get transferNoticeTitle => 'Moving between wallets';
	@override String get transferNoticeBody => 'Record money moving between your wallets, like a cash withdrawal or an e-wallet top-up. Your total stays the same.';
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
	@override String get balanceLabel => 'Balance';
	@override String get categoryPlaceholder => 'Pick a category';
	@override String get categoryNoneLabel => 'No category';
	@override String get budgetItemLabel => 'Budget item';
	@override String get budgetItemNone => 'No budget';
	@override String get budgetItemHelp => 'Optional. Only budget items matching the wallets above whose period covers the transaction date are offered.';
	@override String budgetItemOutOfPeriod({required Object name}) => 'This date is outside the "${name}" budget period, so this transaction no longer counts toward it.';
	@override String get freelanceCalloutTitle => 'Freelance pay?';
	@override String get freelanceCalloutAction => 'Record it in Freelance';
	@override String get kindSwitcherLabel => 'Transaction kind';
	@override String get kindExpense => 'Out';
	@override String get kindIncome => 'In';
	@override String get kindTransfer => 'Transfer';
}

// Path: transaction
class _Translations$transaction$en extends Translations$transaction$id {
	_Translations$transaction$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pageTitle => 'Transactions';
	@override String get searchHint => 'Search this month: notes / categories...';
	@override String get monthStatusLabel => 'This month\'s log status';
	@override String logCountBadge({required Object count}) => '${count} active logs';
	@override String get netFlowLabel => 'Net flow';
	@override String get flowIncomeLabel => 'In';
	@override String get flowExpenseLabel => 'Out';
	@override String allFilterLabel({required Object count}) => 'All ${count}';
	@override String incomeFilterLabel({required Object count}) => 'Income ${count}';
	@override String expenseFilterLabel({required Object count}) => 'Expense ${count}';
	@override String transferFilterLabel({required Object count}) => 'Transfer ${count}';
	@override String get walletFilterAllLabel => 'All Wallets';
	@override String get walletFilterLabel => 'Wallet';
	@override String get categoryFilterAllLabel => 'All Categories';
	@override String get categoryFilterLabel => 'Category';
	@override String get filterButtonLabel => 'Filter';
	@override String get filterSheetTitle => 'Filter Transactions';
	@override String get filterSheetDoneAction => 'Done';
	@override String get todayLabel => 'Today';
	@override String get yesterdayLabel => 'Yesterday';
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
	@override String get trustFooterMessage => 'Your complete history, kept safe on your device';
	@override String get emptyFilterTitle => 'No transactions this month match the filter';
	@override String get emptyFilterSubtitle => 'Search and filters only cover the month that is open. Change the month, or change or clear the filters.';
	@override String get clearFiltersButton => 'Clear filters';
	@override String get crossMonthSearchButton => 'Search other months';
	@override String get crossMonthSearchingLabel => 'Searching earlier months...';
	@override String get crossMonthResultsHeader => 'Found in other months';
	@override String get crossMonthLoadMoreButton => 'Search further back';
	@override String get crossMonthNoMoreResults => 'Not found in earlier months.';
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
	@override String get detailNoteLabel => 'Note';
	@override String get detailFromLabel => 'From';
	@override String get detailToLabel => 'To';
	@override String get detailAmountLabel => 'Amount';
	@override String get detailManualNote => 'Kept safe on your device. Wallet balances follow every record, so when you edit or delete it, balances adjust with it.';
	@override String get editAction => 'Edit This Entry';
	@override String get recordAgainAction => 'Record Again';
	@override String get deleteAction => 'Delete Entry from History';
	@override String get editSheetTitle => 'Edit Entry';
	@override String get saveChangesAction => 'Save Changes';
	@override String get updatedMessage => 'Changes saved.';
	@override String get deletedMessage => 'Entry deleted.';
	@override String get undoDeleteAction => 'Undo';
	@override String get restoredMessage => 'Entry restored.';
	@override String get budgetLabel => 'Budget';
	@override String get openBudgetAction => 'View budget';
	@override String get detailFreelanceNote => 'This income was recorded from a freelance payment. To change it, cancel its receipt in Freelance.';
}

// Path: wallet
class _Translations$wallet$en extends Translations$wallet$id {
	_Translations$wallet$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Where your cash stands right now';
	@override String activeBadge({required Object count}) => '${count} active';
	@override String get totalLabel => 'Total balance of all wallets';
	@override String get listHeading => 'Wallets';
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
	@override String get initialBalanceHelp => 'The starting balance is the money in this wallet right now, the starting point of your records. Every transaction after it counts from here.';
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
	@override String get detailIncomeLabel => 'Income';
	@override String get detailExpenseLabel => 'Expenses';
	@override String get detailRecentEmptyTitle => 'No transactions yet';
	@override String get detailRecentEmpty => 'No transactions this month for this wallet yet.';
	@override String get detailViewAllAction => 'View All Transactions';
	@override String get detailRecordAction => 'Record a Transaction for This Wallet';
	@override String get detailTransferInLabel => 'Transfers in';
	@override String get detailTransferOutLabel => 'Transfers out';
	@override String get detailBalanceChangeLabel => 'Balance change';
}

// Path: budget
class _Translations$budget$en extends Translations$budget$id {
	_Translations$budget$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String activeBadge({required Object count}) => '${count} active';
	@override String get summaryTitle => 'Total of active budgets';
	@override String summaryPercent({required Object percent}) => '${percent}% spent';
	@override String get plannedLabel => 'Planned';
	@override String get spentLabel => 'Spent';
	@override String get remainingLabel => 'Remaining';
	@override String spentPercentLabel({required Object percent}) => 'Spent (${percent}%)';
	@override String paceLabel({required Object percent}) => 'Period elapsed (${percent}%)';
	@override String get summaryNote => 'A budget is your spending plan. The used amount grows each time a linked expense or transfer is recorded.';
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
	@override String itemCount({required Object count}) => 'Items: ${count}';
	@override String get emptyBadge => 'No plans yet';
	@override String get emptyTitle => 'No budgets yet';
	@override String get emptyBody => 'Plan a weekly or monthly spending limit for one wallet, then keep an eye on how much is used.';
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
	@override String get ruleBody => 'This plan is your spending guide. Wallet balances move with the transactions you record.';
	@override String get nameLabel => 'Budget name';
	@override String get nameHint => 'Example: Household Needs';
	@override String get requiredHint => 'Required';
	@override String get walletLabel => 'Linked wallet';
	@override String get walletHelp => 'Only expenses and outgoing transfers from this wallet count toward the budget.';
	@override String walletBalance({required Object amount}) => 'Balance: ${amount}';
	@override String get periodLabel => 'Period';
	@override String get startDateLabel => 'Starts';
	@override String periodRange({required Object start, required Object end}) => '${start} – ${end}';
	@override String get itemsLabel => 'Budget items';
	@override String get itemsHelp => 'Planned purchases or planned transfers. The budget total is the sum of all items.';
	@override String get addItemAction => 'Add Item';
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
	@override String detailHowBody({required Object wallet}) => 'Record with the button on each item. Expense items count expenses from ${wallet}; transfer items count transfers from ${wallet} to their destination wallet.';
	@override String get unknownWallet => 'Wallet not found';
	@override String get totalPlannedLabel => 'Total planned budget';
	@override String get itemsRequiredHint => 'Add at least one item. Transactions are recorded against items, so a budget without items cannot track spending.';
	@override String walletUnchangedNote({required Object wallet}) => '${wallet} balance unchanged';
	@override String get itemKindLabel => 'Item type';
	@override String get itemKindExpense => 'Expense';
	@override String get itemKindTransfer => 'Transfer';
	@override String get itemKindLockedHint => 'The type can\'t be changed because this item already has linked transactions.';
	@override String get itemTargetWalletLabel => 'Destination wallet';
	@override String get itemTargetWalletHelp => 'Only transfers from the budget wallet to this wallet count toward the item.';
	@override String get itemNoTargetWallet => 'You need another active wallet as the transfer destination.';
	@override String itemTransferTo({required Object wallet}) => 'To ${wallet}';
	@override String itemTargetConflict({required Object name}) => 'Transfer item "${name}" points to the budget\'s own wallet. Change the item\'s destination or the budget wallet.';
	@override String get templatesAction => 'Budget Templates';
	@override String get templatesTitle => 'Budget Templates';
	@override String templatesSavedBadge({required Object count}) => 'Saved: ${count}';
	@override String get templatesInfoTitle => 'What is a budget template?';
	@override String get templatesInfoBody => 'A reusable set of plan items, so you never start from scratch. Each use creates a new, independent budget.';
	@override String templateItemCount({required Object count}) => 'Items: ${count}';
	@override String get templateItemsLabel => 'Planned items';
	@override String get templateTotalLabel => 'Planned total';
	@override String get templateUseAction => 'Use This Template';
	@override String get templateEditAction => 'Edit';
	@override String get templateDuplicateAction => 'Duplicate';
	@override String get templateInactiveBadge => 'Inactive';
	@override String get templateAddAction => 'Create New Template';
	@override String get templatesFooter => 'Templates can be edited any time without changing budgets already created from them.';
	@override String get templatesEmptyBadge => 'No templates yet';
	@override String get templatesEmptyTitle => 'No templates yet';
	@override String get templatesEmptyBody => 'Save item sets you use often, such as monthly groceries, so your next budget is one tap away.';
	@override String get templateNeedsWallet => 'Create an active wallet first to use a template.';
	@override String get templatesLoadError => 'Templates failed to load';
	@override String get templateStepLabel => 'Budget template';
	@override String get templateAddTitle => 'Create Template';
	@override String get templateEditTitle => 'Edit Template';
	@override String get templateRuleBody => 'A template keeps your set of plan items. The wallet and period are chosen when you use it.';
	@override String get templateNameHint => 'Example: Monthly groceries';
	@override String get templateEnabledLabel => 'Offer this template';
	@override String get templateEnabledHelp => 'Inactive templates stay saved but cannot be used to create a budget.';
	@override String get templateSaveAction => 'Save Template';
	@override String get templateDeleteAction => 'Delete Template';
	@override String get templateDeleteConfirmTitle => 'Delete template?';
	@override String templateDeleteConfirmMessage({required Object name}) => 'Template "${name}" will be deleted. Budgets created from it are not deleted.';
	@override String get templateSavedMessage => 'Template saved.';
	@override String get templateUpdatedMessage => 'Template changes saved.';
	@override String get templateDeletedMessage => 'Template deleted.';
	@override String get templateDuplicatedMessage => 'Template duplicated.';
	@override String templateCopyName({required Object name}) => '${name} (copy)';
	@override String fromTemplateStepLabel({required Object name}) => 'From template ${name}';
	@override String get templateNameLabel => 'Template name';
}

// Path: freelance
class _Translations$freelance$en extends Translations$freelance$id {
	_Translations$freelance$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Freelance';
	@override String worklogTab({required Object count}) => 'Worklog (${count})';
	@override String paymentsTab({required Object count}) => 'Payments (${count})';
	@override String get loadErrorTitle => 'Freelance data failed to load';
	@override String get ruleTitle => 'Freelance cash rule';
	@override String get ruleBody => 'Work hours add up to an invoice, and your wallet balance grows when its payment is recorded as received.';
	@override String get summaryTitle => 'Pay & hours summary';
	@override String get totalHoursLabel => 'Hours worked';
	@override String hoursValue({required Object hours}) => '${hours} h';
	@override String get hourShort => 'h';
	@override String projectCount({required Object count}) => 'Projects: ${count}';
	@override String get earnedLabel => 'Total earned';
	@override String get earnedCaption => 'Hours × rate, before deductions';
	@override String get paidLabel => 'Received';
	@override String get paidCaption => 'Gross pay · payment already recorded';
	@override String get unpaidLabel => 'Not received';
	@override String get unpaidCaption => 'Gross pay · unbilled or pending';
	@override String paidRatio({required Object percent}) => '${percent}% received';
	@override String get projectsLabel => 'Projects';
	@override String get projectsEmpty => 'No projects yet. Add a client or project with its hourly rate first.';
	@override String get projectStepLabel => 'Freelance project';
	@override String get projectAddTitle => 'Add Project';
	@override String get projectEditTitle => 'Edit Project';
	@override String get projectNameLabel => 'Client or project name';
	@override String get projectNameHint => 'Example: Studio Koding';
	@override String get requiredHint => 'Required';
	@override String get hourlyRateLabel => 'Hourly rate';
	@override String get hourlyRateHelp => 'Default rate for new entries. Changing it does not change entries already recorded.';
	@override String get deductionsLabel => 'Deductions';
	@override String get deductionsHelp => 'Taken from the gross pay of each payment, such as tax. Changing them does not change payments already created.';
	@override String get deductionAddAction => 'Add deduction';
	@override String get deductionTitle => 'Deduction';
	@override String get deductionLabelLabel => 'Deduction name';
	@override String get deductionLabelHint => 'Example: Tax';
	@override String get deductionKindPercentage => 'Percent';
	@override String get deductionKindFixed => 'Fixed amount';
	@override String get deductionPercentLabel => 'Percent of gross pay';
	@override String get deductionPercentHelp => 'At most one decimal place, for example 2.5.';
	@override String get deductionAmountLabel => 'Amount per payment';
	@override String get deductionSaveAction => 'Save deduction';
	@override String get deductionRemoveAction => 'Remove deduction';
	@override String get projectSaveAction => 'Save project';
	@override String get projectDeleteAction => 'Delete project';
	@override String get projectDeleteLockedHint => 'A project that already has worklog entries cannot be deleted.';
	@override String get projectDeleteConfirmTitle => 'Delete project?';
	@override String projectDeleteConfirmMessage({required Object name}) => 'Project "${name}" will be deleted.';
	@override String get projectDeleteRefused => 'This project already has worklog entries, so it cannot be deleted.';
	@override String get projectSavedMessage => 'Project saved.';
	@override String get projectUpdatedMessage => 'Project changes saved.';
	@override String get projectDeletedMessage => 'Project deleted.';
	@override String get projectLabel => 'Project';
	@override String get projectPick => 'Choose a project';
	@override String get entryStepLabel => 'Work log';
	@override String get entryAddTitle => 'Add Worklog';
	@override String get entryEditTitle => 'Edit Worklog';
	@override String get entryRuleBody => 'Work hours add up to an invoice. The money reaches your balance when its payment is recorded as received.';
	@override String get workDateLabel => 'Work date';
	@override String get hoursLabel => 'Duration';
	@override String get entryRateHelp => 'Filled from the project rate. Change it if this entry\'s rate differs.';
	@override String get noteLabel => 'Note';
	@override String get noteHint => 'What was done (optional)';
	@override String get entrySaveAction => 'Save Worklog';
	@override String get entrySaveHint => 'This amount is recorded as earned, not yet received.';
	@override String get entryDeleteAction => 'Delete entry';
	@override String get entryDeleteConfirmTitle => 'Delete worklog entry?';
	@override String get entryDeleteConfirmMessage => 'This entry will be deleted. Wallet balances do not change.';
	@override String get entryLockedMessage => 'Entries already in a payment cannot be edited or deleted.';
	@override String get entrySavedMessage => 'Worklog saved.';
	@override String get entryUpdatedMessage => 'Worklog changes saved.';
	@override String get entryDeletedMessage => 'Worklog deleted.';
	@override String hoursTimesRate({required Object hours, required Object rate}) => '${hours} h × ${rate}';
	@override String get statusUnbilled => 'Unbilled';
	@override String get statusPending => 'Pending';
	@override String get statusPaid => 'Received';
	@override String expectedOn({required Object date}) => 'Expected ${date}';
	@override String receivedOn({required Object date, required Object wallet}) => 'Received ${date} in ${wallet}';
	@override String get unknownProject => 'Deleted project';
	@override String get unknownWallet => 'deleted wallet';
	@override String get pendingTotalLabel => 'Pending (net)';
	@override String get paidTotalLabel => 'Received (net)';
	@override String paymentCount({required Object count}) => 'Payments: ${count}';
	@override String get paymentStepLabel => 'Freelance payment';
	@override String get paymentAddTitle => 'Create Payment';
	@override String get paymentCreateRuleBody => 'A payment groups work hours into one invoice. Once it\'s recorded as received, your wallet balance grows.';
	@override String paymentEntriesLabel({required Object count, required Object hours}) => 'Billed entries: ${count} (${hours} h)';
	@override String paymentEntriesSummary({required Object count, required Object hours}) => 'Entries: ${count} · ${hours} h';
	@override String get expectedDateLabel => 'Expected date received';
	@override String get grossPayLabel => 'Gross pay';
	@override String get netPayLabel => 'Net pay';
	@override String get netPayNotPositive => 'Deductions cannot equal or exceed gross pay.';
	@override String get paymentCreateAction => 'Create Payment';
	@override String get paymentChangeDateAction => 'Change date';
	@override String get paymentDeleteAction => 'Delete';
	@override String get paymentDeleteConfirmTitle => 'Delete payment?';
	@override String get paymentDeleteConfirmMessage => 'This pending payment is deleted and its entries become unbilled again. Wallet balances do not change.';
	@override String get paymentEntriesInvalid => 'The chosen entries are already billed or belong to another project.';
	@override String get paymentPaidLocked => 'A received payment cannot be deleted. Cancel its receipt first.';
	@override String get paymentAlreadyPaid => 'This payment is already recorded as received.';
	@override String get paymentCreatedMessage => 'Payment created.';
	@override String get paymentUpdatedMessage => 'Payment date updated.';
	@override String get paymentDeletedMessage => 'Payment deleted.';
	@override String get receiveTitle => 'Record Payment Received';
	@override String get receiveRuleTitle => 'Payment received';
	@override String get receiveRuleBody => 'Record it once the money has reached you. The chosen wallet grows by the net pay, and this invoice is marked paid.';
	@override String get receiveAmountLabel => 'Amount received';
	@override String get receiveWalletLabel => 'Receiving wallet';
	@override String get receiveDateLabel => 'Date received';
	@override String receiveNoteDefault({required Object project}) => 'Freelance payment ${project}';
	@override String get receiveAction => 'Record Received';
	@override String get paymentReceivedMessage => 'Payment recorded as received. Wallet balance increased.';
	@override String get receiptCancelAction => 'Cancel receipt';
	@override String get receiptCancelConfirmTitle => 'Cancel receipt?';
	@override String get receiptCancelConfirmMessage => 'Its income record is deleted and the wallet balance goes back down. The payment becomes pending again.';
	@override String get receiptCancelledMessage => 'Receipt cancelled. The payment is pending again.';
	@override String get changeAction => 'Change';
	@override String get receiptCancelConfirmAction => 'Delete income';
	@override String billAction({required Object count}) => 'Bill (${count})';
	@override String get entriesEmptyBadge => 'No work hours yet';
	@override String get entriesEmptyTitle => 'No worklog yet';
	@override String get entriesEmptyBody => 'Log this project\'s work hours with the + Worklog button below.';
	@override String get entriesFilteredEmpty => 'No entries with this status.';
	@override String get entryAddShortAction => '+ Worklog';
	@override String entryCountLabel({required Object count}) => 'Entries: ${count}';
	@override String get filterAll => 'All';
	@override String lastEntryOn({required Object date}) => 'Last ${date}';
	@override String get noDeductions => 'No deductions';
	@override String get noEntriesYet => 'No entries yet';
	@override String projectTotals({required Object hours, required Object amount}) => 'Total ${hours} h · ${amount}';
	@override String get projectsEmptyBadge => 'No projects yet';
	@override String get projectsEmptyTitle => 'No projects yet';
	@override String get unbilledLabel => 'Unbilled';
	@override String get unbilledNone => 'Everything is billed';
	@override String get paymentsEmptyBadge => 'No invoices yet';
	@override String get paymentsEmptyTitle => 'No payments yet';
	@override String get paymentsEmptyBody => 'Tap Bill below to group unbilled work hours into one payment.';
	@override String get paymentsFilteredEmpty => 'No payments with this status.';
	@override String nextExpected({required Object count, required Object date}) => 'Invoices: ${count} · next ${date}';
	@override String paymentWorkRange({required Object range}) => 'Work ${range}';
}

// Path: home
class _Translations$home$en extends Translations$home$id {
	_Translations$home$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get loadErrorTitle => 'Home failed to load';
	@override String get balanceLabel => 'Total active cash';
	@override String walletCount({required Object count}) => 'Active wallets: ${count}';
	@override String moreWallets({required Object count}) => '+${count} more';
	@override String get startBadge => 'Start recording';
	@override String get noWalletsBody => 'No wallet balance recorded yet.';
	@override String incomeLabel({required Object month}) => 'Income ${month}';
	@override String expenseLabel({required Object month}) => 'Expenses ${month}';
	@override String get budgetTitle => 'Active budgets';
	@override String get budgetRemaining => 'Remaining';
	@override String get budgetOver => 'Over plan';
	@override String get budgetAction => 'View Budgets';
	@override String get freelanceTitle => 'Freelance';
	@override String freelancePaid({required Object amount}) => 'Received: ${amount}';
	@override String get freelanceAction => 'View Freelance';
	@override String get recentTitle => 'Recent transactions';
	@override String get seeAll => 'See all';
	@override String get emptyBadge => 'Empty inventory';
	@override String get emptyTitle => 'No transactions yet';
	@override String get emptyBody => 'Start by recording your first income, expense, or transfer.';
	@override String get emptyNoWalletBody => 'Create your first wallet with its starting balance, then record your first transaction.';
	@override String get recordAction => 'Record Transaction';
	@override String get createWalletAction => 'Create First Wallet';
	@override String get budgetLink => 'Or create a spending budget';
	@override String get guideTitle => 'Quick guide';
	@override String get guideCount => '3 core rules';
	@override String get guideWalletTitle => 'Wallets';
	@override String get guideWalletTag => 'Real assets';
	@override String get guideWalletBody => 'Record bank accounts, digital wallets, or cash with their current balance.';
	@override String get guideBudgetTitle => 'Budgets';
	@override String get guideBudgetTag => 'Plans';
	@override String get guideBudgetBody => 'Plan spending limits and track how much is used.';
	@override String get guideFreelanceTitle => 'Freelance';
	@override String get guideFreelanceTag => 'Receivables';
	@override String get guideFreelanceBody => 'Track work hours and invoices. Money reaches a wallet only when its payment is recorded as received.';
	@override String budgetSpentOf({required Object spent, required Object planned}) => '${spent} used of ${planned}';
	@override String get freelanceUnpaidTitle => 'Not received (gross)';
	@override String get freelanceDueLabel => 'Due';
	@override String freelancePendingInvoices({required Object count}) => 'Pending invoices: ${count}';
	@override String freelanceSummaryLine({required Object hours, required Object earned}) => '${hours} · earned ${earned}';
	@override String openCard({required Object name}) => 'Open ${name}';
	@override String budgetUsedBadge({required Object percent}) => '${percent}% used';
}

// Path: onboarding
class _Translations$onboarding$en extends Translations$onboarding$id {
	_Translations$onboarding$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get skipAction => 'Skip';
	@override String get nextAction => 'Next';
	@override String get closeAction => 'Close';
	@override String pageIndicatorLabel({required Object current, required Object total}) => 'Page ${current} of ${total}';
	@override String get page1Title => 'All your money, one book';
	@override String get page1Body => 'See where your money is, what happens to it, and where you plan for it to go — all in your personal cash book.';
	@override String get page2Title => 'Know where your money is';
	@override String get page2Body => 'Bank accounts, e-wallets, and cash become wallets. Each wallet\'s balance and the total are always in view.';
	@override String get page3Title => 'Record in seconds';
	@override String get page3Body => 'Money in, money out, or moved between wallets — tap RECORD. Your usual wallet and favorite categories are already waiting.';
	@override String get page4Title => 'Plan, then track';
	@override String get page4Body => 'Set weekly or monthly budgets with your spending items. Your balance stays intact, and you see how much of the plan is used.';
	@override String get finalTitle => 'Start with your first wallet';
	@override String get finalBody => 'Add one wallet, then record your first transaction. On every screen, the tanuki will show you the way.';
	@override String get createWalletAction => 'Create First Wallet';
	@override String get laterAction => 'Maybe later';
	@override String get signInAction => 'Have an account? Sign in';
	@override String get backAction => 'Back';
	@override String get currencyTitle => 'Choose your currency';
	@override String get currencyBody => 'Every amount in Tanukonomy uses this currency. You can change it later on the Account screen, but amounts you\'ve already recorded aren\'t converted.';
	@override String get currencySuggested => 'Matches your device region';
	@override String get currencyChooseFirst => 'Choose a currency first';
	@override String currencyConfirm({required Object code}) => 'Use ${code}';
}

// Path: tour
class _Translations$tour$en extends Translations$tour$id {
	_Translations$tour$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get nextAction => 'Next';
	@override String get doneAction => 'Done';
	@override String get skipAction => 'Skip tour';
	@override String stepCounter({required Object current, required Object total}) => '${current}/${total}';
	@override String stepSemantics({required Object current, required Object total, required Object title, required Object body}) => 'Step ${current} of ${total}: ${title}. ${body}';
	@override String get homeBalanceTitle => 'Total recorded balance';
	@override String get homeBalanceBody => 'The sum of all active wallets — where your money stands at a glance.';
	@override String get homeRecordTitle => 'One door for recording';
	@override String get homeRecordBody => 'Every bit of money in, out, and between wallets is recorded from here.';
	@override String get homeCashFlowTitle => 'This month\'s flow';
	@override String get homeCashFlowBody => 'The money that actually came in and went out this month.';
	@override String get homeBudgetTitle => 'Active budget left';
	@override String get homeBudgetBody => 'What\'s left of the plan in budgets running now. Tap for details.';
	@override String get homeFreelanceTitle => 'Freelance summary';
	@override String get homeFreelanceBody => 'Income you\'ve earned and what\'s still pending. A wallet balance only goes up when a payment is recorded as received.';
	@override String get homeRecentTitle => 'Recent transactions';
	@override String get homeRecentBody => 'Your latest records. Tap one for details, or See all for the month-by-month history.';
	@override String get recordKindTitle => 'Pick the kind';
	@override String get recordKindBody => 'Out lowers a balance, In raises it, and Transfer only moves money between your wallets — your total stays the same.';
	@override String get recordFreelanceTitle => 'Freelance pay has its own path';
	@override String get recordFreelanceBody => 'Project pay is recorded as a received payment in Freelance, so its work hours and invoice are settled too.';
	@override String get recordAmountTitle => 'Amount';
	@override String get recordAmountBody => 'Type the amount, or use the quick buttons.';
	@override String get recordWalletTitle => 'Wallet filled in for you';
	@override String get recordWalletBody => 'The wallet you used last is already selected. Change it if needed.';
	@override String get recordBudgetItemTitle => 'Link to a budget';
	@override String get recordBudgetItemBody => 'Optional. A linked expense adds to that item\'s used amount, as long as its date is inside the budget period.';
	@override String get walletSummaryTitle => 'Total across wallets';
	@override String get walletSummaryBody => 'The sum of recorded balances of active wallets.';
	@override String get walletCardTitle => 'Wallet details';
	@override String get walletCardBody => 'Tap to see this wallet\'s history and record straight from there.';
	@override String get walletAddTitle => 'Add a wallet';
	@override String get walletAddBody => 'Bank account, e-wallet, or cash. Its starting balance can be changed anytime, and the recorded balance follows.';
	@override String get txnMonthTitle => 'One month per view';
	@override String get txnMonthBody => 'Switch months to see other history. The in and out totals here cover only the month shown.';
	@override String get txnFilterTitle => 'Search and filter';
	@override String get txnFilterBody => 'Search notes or categories, then filter by wallet and category with Filter. If this month has no match, the search can continue into other months.';
	@override String get txnRowTitle => 'Edit or delete';
	@override String get txnRowBody => 'Tap a transaction for its details; from there you can edit, record it again, or delete it, and balances are recalculated.';
	@override String get budgetSummaryTitle => 'Left across active budgets';
	@override String get budgetSummaryBody => 'Plan minus used — the spending room left across your active budgets.';
	@override String get budgetFilterTitle => 'Active first';
	@override String get budgetFilterBody => 'The list shows active budgets. Choose Finished or Inactive to see older ones.';
	@override String get budgetTemplatesTitle => 'Use templates';
	@override String get budgetTemplatesBody => 'Save a recurring set of items, then create new budgets from it.';
	@override String get budgetDetailItemTitle => 'Budget item';
	@override String get budgetDetailItemBody => 'Used goes up from transactions linked to this item within the budget period.';
	@override String get budgetDetailRecordTitle => 'Record from an item';
	@override String get budgetDetailRecordBody => 'Opens RECORD with this item already selected.';
	@override String get freelanceProjectTitle => 'Projects and rates';
	@override String get freelanceProjectBody => 'Each project has an hourly rate and deductions. Tap a project to log hours and payments.';
	@override String get freelanceWorklogTitle => 'Hours worked';
	@override String get freelanceWorklogBody => 'Work hours are income you\'ve earned. Group them into an invoice, then record it when you\'re paid.';
	@override String get freelanceReceiveTitle => 'Money actually arrives';
	@override String get freelanceReceiveBody => 'Record it when the pay arrives: your wallet balance grows and the invoice is settled.';
}

// Path: info
class _Translations$info$en extends Translations$info$id {
	_Translations$info$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get menuTooltip => 'Info and tours';
	@override String get replayTourAction => 'Tour this screen';
	@override String get showIntroAction => 'Tanukonomy introduction';
	@override String get resetAllAction => 'Reset all tutorials';
	@override String get resetConfirmTitle => 'Reset tutorials?';
	@override String get resetConfirmMessage => 'The introduction and every tour will show again like the first time. Your financial data isn\'t touched.';
	@override String get resetConfirmAction => 'Reset';
	@override String get resetDoneMessage => 'Tutorials reset.';
}

// Path: account
class _Translations$account$en extends Translations$account$id {
	_Translations$account$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Account';
	@override String get signedOutTitle => 'Set up your account';
	@override String get signedOutBody => 'Everything you record works fully without an account. An account prepares you for the backup and cross-device sync we\'re building.';
	@override String get googleSignInAction => 'Sign in with Google';
	@override String get emailSignInToggle => 'Sign in with email';
	@override String get emailFormHint => 'For accounts that were created for you.';
	@override String get emailLabel => 'Email';
	@override String get passwordLabel => 'Password';
	@override String get emailSignInAction => 'Sign in';
	@override String get emailRequired => 'Enter your email and password first.';
	@override String get signedInMessage => 'You\'re signed in.';
	@override String get signedOutMessage => 'You\'re signed out.';
	@override String get methodGoogle => 'Signed in with Google';
	@override String get methodPassword => 'Signed in with email';
	@override String get dataTitle => 'Your data';
	@override String get dataBody => 'Wallets, transactions, and budgets are stored on this device. Signing out or deleting your account doesn\'t touch them.';
	@override String get signOutAction => 'Sign out';
	@override String get dangerTitle => 'Danger zone';
	@override String get dangerBody => 'Deleting your account is permanent and can\'t be undone.';
	@override String get deleteAction => 'Delete Account';
	@override String get deleteConfirmTitle => 'Delete account?';
	@override String get deleteConfirmBody => 'Your account is permanently deleted. Wallets, transactions, and budgets on this device stay.';
	@override String get deletePasswordTitle => 'Enter your password';
	@override String get deletePasswordBody => 'For your security, enter your password again to delete your account.';
	@override String get deletedMessage => 'Account deleted.';
	@override late final _Translations$account$errors$en errors = _Translations$account$errors$en._(_root);
}

// Path: currency
class _Translations$currency$en extends Translations$currency$id {
	_Translations$currency$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get settingsTitle => 'Settings';
	@override String get label => 'Currency';
	@override String get pickerTitle => 'Choose currency';
	@override String changeTitle({required Object code}) => 'Switch to ${code}?';
	@override String changeBody({required Object before, required Object after}) => 'Amounts you\'ve already recorded aren\'t converted; only the symbol changes. For example, ${before} will show as ${after}.';
	@override String get changeAction => 'Switch';
	@override String changedMessage({required Object code}) => 'Currency switched to ${code}.';
	@override late final _Translations$currency$names$en names = _Translations$currency$names$en._(_root);
}

// Path: account.errors
class _Translations$account$errors$en extends Translations$account$errors$id {
	_Translations$account$errors$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get network => 'Can\'t connect. Check your internet connection, then try again.';
	@override String get wrongCredentials => 'Wrong email or password.';
	@override String get tooManyRequests => 'Too many attempts. Wait a moment, then try again.';
	@override String get userDisabled => 'This account has been disabled.';
	@override String get other => 'Couldn\'t sign in. Try again.';
}

// Path: currency.names
class _Translations$currency$names$en extends Translations$currency$names$id {
	_Translations$currency$names$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get idr => 'Indonesian Rupiah';
	@override String get usd => 'US Dollar';
	@override String get eur => 'Euro';
	@override String get gbp => 'British Pound';
	@override String get jpy => 'Japanese Yen';
	@override String get cny => 'Chinese Yuan';
	@override String get krw => 'South Korean Won';
	@override String get inr => 'Indian Rupee';
	@override String get sgd => 'Singapore Dollar';
	@override String get myr => 'Malaysian Ringgit';
	@override String get thb => 'Thai Baht';
	@override String get php => 'Philippine Peso';
	@override String get vnd => 'Vietnamese Dong';
	@override String get aud => 'Australian Dollar';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Tanukonomy',
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
			'record.incomeBadge' => 'Money in',
			'record.expenseBadge' => 'Money out',
			'record.transferBadge' => 'Internal move',
			'record.stepLabel' => 'Record // Transaction',
			'record.editStepLabel' => 'Edit // Transaction',
			'record.expenseRuleTitle' => 'Cash rule: balance is reduced',
			'record.expenseRuleBody' => 'An expense immediately reduces the balance of the wallet you pick below.',
			'record.transferNoticeTitle' => 'Moving between wallets',
			'record.transferNoticeBody' => 'Record money moving between your wallets, like a cash withdrawal or an e-wallet top-up. Your total stays the same.',
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
			'record.balanceLabel' => 'Balance',
			'record.categoryPlaceholder' => 'Pick a category',
			'record.categoryNoneLabel' => 'No category',
			'record.budgetItemLabel' => 'Budget item',
			'record.budgetItemNone' => 'No budget',
			'record.budgetItemHelp' => 'Optional. Only budget items matching the wallets above whose period covers the transaction date are offered.',
			'record.budgetItemOutOfPeriod' => ({required Object name}) => 'This date is outside the "${name}" budget period, so this transaction no longer counts toward it.',
			'record.freelanceCalloutTitle' => 'Freelance pay?',
			'record.freelanceCalloutAction' => 'Record it in Freelance',
			'record.kindSwitcherLabel' => 'Transaction kind',
			'record.kindExpense' => 'Out',
			'record.kindIncome' => 'In',
			'record.kindTransfer' => 'Transfer',
			'transaction.pageTitle' => 'Transactions',
			'transaction.searchHint' => 'Search this month: notes / categories...',
			'transaction.monthStatusLabel' => 'This month\'s log status',
			'transaction.logCountBadge' => ({required Object count}) => '${count} active logs',
			'transaction.netFlowLabel' => 'Net flow',
			'transaction.flowIncomeLabel' => 'In',
			'transaction.flowExpenseLabel' => 'Out',
			'transaction.allFilterLabel' => ({required Object count}) => 'All ${count}',
			'transaction.incomeFilterLabel' => ({required Object count}) => 'Income ${count}',
			'transaction.expenseFilterLabel' => ({required Object count}) => 'Expense ${count}',
			'transaction.transferFilterLabel' => ({required Object count}) => 'Transfer ${count}',
			'transaction.walletFilterAllLabel' => 'All Wallets',
			'transaction.walletFilterLabel' => 'Wallet',
			'transaction.categoryFilterAllLabel' => 'All Categories',
			'transaction.categoryFilterLabel' => 'Category',
			'transaction.filterButtonLabel' => 'Filter',
			'transaction.filterSheetTitle' => 'Filter Transactions',
			'transaction.filterSheetDoneAction' => 'Done',
			'transaction.todayLabel' => 'Today',
			'transaction.yesterdayLabel' => 'Yesterday',
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
			'transaction.trustFooterMessage' => 'Your complete history, kept safe on your device',
			'transaction.emptyFilterTitle' => 'No transactions this month match the filter',
			'transaction.emptyFilterSubtitle' => 'Search and filters only cover the month that is open. Change the month, or change or clear the filters.',
			'transaction.clearFiltersButton' => 'Clear filters',
			'transaction.crossMonthSearchButton' => 'Search other months',
			'transaction.crossMonthSearchingLabel' => 'Searching earlier months...',
			'transaction.crossMonthResultsHeader' => 'Found in other months',
			'transaction.crossMonthLoadMoreButton' => 'Search further back',
			'transaction.crossMonthNoMoreResults' => 'Not found in earlier months.',
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
			'transaction.detailNoteLabel' => 'Note',
			'transaction.detailFromLabel' => 'From',
			'transaction.detailToLabel' => 'To',
			'transaction.detailAmountLabel' => 'Amount',
			'transaction.detailManualNote' => 'Kept safe on your device. Wallet balances follow every record, so when you edit or delete it, balances adjust with it.',
			'transaction.editAction' => 'Edit This Entry',
			'transaction.recordAgainAction' => 'Record Again',
			'transaction.deleteAction' => 'Delete Entry from History',
			'transaction.editSheetTitle' => 'Edit Entry',
			'transaction.saveChangesAction' => 'Save Changes',
			'transaction.updatedMessage' => 'Changes saved.',
			'transaction.deletedMessage' => 'Entry deleted.',
			'transaction.undoDeleteAction' => 'Undo',
			'transaction.restoredMessage' => 'Entry restored.',
			'transaction.budgetLabel' => 'Budget',
			'transaction.openBudgetAction' => 'View budget',
			'transaction.detailFreelanceNote' => 'This income was recorded from a freelance payment. To change it, cancel its receipt in Freelance.',
			'wallet.subtitle' => 'Where your cash stands right now',
			'wallet.activeBadge' => ({required Object count}) => '${count} active',
			'wallet.totalLabel' => 'Total balance of all wallets',
			'wallet.listHeading' => 'Wallets',
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
			'wallet.initialBalanceHelp' => 'The starting balance is the money in this wallet right now, the starting point of your records. Every transaction after it counts from here.',
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
			'wallet.detailIncomeLabel' => 'Income',
			'wallet.detailExpenseLabel' => 'Expenses',
			'wallet.detailRecentEmptyTitle' => 'No transactions yet',
			'wallet.detailRecentEmpty' => 'No transactions this month for this wallet yet.',
			'wallet.detailViewAllAction' => 'View All Transactions',
			'wallet.detailRecordAction' => 'Record a Transaction for This Wallet',
			'wallet.detailTransferInLabel' => 'Transfers in',
			'wallet.detailTransferOutLabel' => 'Transfers out',
			'wallet.detailBalanceChangeLabel' => 'Balance change',
			'budget.activeBadge' => ({required Object count}) => '${count} active',
			'budget.summaryTitle' => 'Total of active budgets',
			'budget.summaryPercent' => ({required Object percent}) => '${percent}% spent',
			'budget.plannedLabel' => 'Planned',
			'budget.spentLabel' => 'Spent',
			'budget.remainingLabel' => 'Remaining',
			'budget.spentPercentLabel' => ({required Object percent}) => 'Spent (${percent}%)',
			'budget.paceLabel' => ({required Object percent}) => 'Period elapsed (${percent}%)',
			'budget.summaryNote' => 'A budget is your spending plan. The used amount grows each time a linked expense or transfer is recorded.',
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
			'budget.itemCount' => ({required Object count}) => 'Items: ${count}',
			'budget.emptyBadge' => 'No plans yet',
			'budget.emptyTitle' => 'No budgets yet',
			'budget.emptyBody' => 'Plan a weekly or monthly spending limit for one wallet, then keep an eye on how much is used.',
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
			'budget.ruleBody' => 'This plan is your spending guide. Wallet balances move with the transactions you record.',
			'budget.nameLabel' => 'Budget name',
			'budget.nameHint' => 'Example: Household Needs',
			'budget.requiredHint' => 'Required',
			'budget.walletLabel' => 'Linked wallet',
			'budget.walletHelp' => 'Only expenses and outgoing transfers from this wallet count toward the budget.',
			'budget.walletBalance' => ({required Object amount}) => 'Balance: ${amount}',
			'budget.periodLabel' => 'Period',
			'budget.startDateLabel' => 'Starts',
			'budget.periodRange' => ({required Object start, required Object end}) => '${start} – ${end}',
			'budget.itemsLabel' => 'Budget items',
			'budget.itemsHelp' => 'Planned purchases or planned transfers. The budget total is the sum of all items.',
			'budget.addItemAction' => 'Add Item',
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
			'budget.detailHowBody' => ({required Object wallet}) => 'Record with the button on each item. Expense items count expenses from ${wallet}; transfer items count transfers from ${wallet} to their destination wallet.',
			'budget.unknownWallet' => 'Wallet not found',
			'budget.totalPlannedLabel' => 'Total planned budget',
			'budget.itemsRequiredHint' => 'Add at least one item. Transactions are recorded against items, so a budget without items cannot track spending.',
			'budget.walletUnchangedNote' => ({required Object wallet}) => '${wallet} balance unchanged',
			'budget.itemKindLabel' => 'Item type',
			'budget.itemKindExpense' => 'Expense',
			'budget.itemKindTransfer' => 'Transfer',
			'budget.itemKindLockedHint' => 'The type can\'t be changed because this item already has linked transactions.',
			'budget.itemTargetWalletLabel' => 'Destination wallet',
			'budget.itemTargetWalletHelp' => 'Only transfers from the budget wallet to this wallet count toward the item.',
			'budget.itemNoTargetWallet' => 'You need another active wallet as the transfer destination.',
			'budget.itemTransferTo' => ({required Object wallet}) => 'To ${wallet}',
			'budget.itemTargetConflict' => ({required Object name}) => 'Transfer item "${name}" points to the budget\'s own wallet. Change the item\'s destination or the budget wallet.',
			'budget.templatesAction' => 'Budget Templates',
			'budget.templatesTitle' => 'Budget Templates',
			'budget.templatesSavedBadge' => ({required Object count}) => 'Saved: ${count}',
			'budget.templatesInfoTitle' => 'What is a budget template?',
			'budget.templatesInfoBody' => 'A reusable set of plan items, so you never start from scratch. Each use creates a new, independent budget.',
			'budget.templateItemCount' => ({required Object count}) => 'Items: ${count}',
			'budget.templateItemsLabel' => 'Planned items',
			'budget.templateTotalLabel' => 'Planned total',
			'budget.templateUseAction' => 'Use This Template',
			'budget.templateEditAction' => 'Edit',
			'budget.templateDuplicateAction' => 'Duplicate',
			'budget.templateInactiveBadge' => 'Inactive',
			'budget.templateAddAction' => 'Create New Template',
			'budget.templatesFooter' => 'Templates can be edited any time without changing budgets already created from them.',
			'budget.templatesEmptyBadge' => 'No templates yet',
			'budget.templatesEmptyTitle' => 'No templates yet',
			'budget.templatesEmptyBody' => 'Save item sets you use often, such as monthly groceries, so your next budget is one tap away.',
			'budget.templateNeedsWallet' => 'Create an active wallet first to use a template.',
			'budget.templatesLoadError' => 'Templates failed to load',
			'budget.templateStepLabel' => 'Budget template',
			'budget.templateAddTitle' => 'Create Template',
			'budget.templateEditTitle' => 'Edit Template',
			'budget.templateRuleBody' => 'A template keeps your set of plan items. The wallet and period are chosen when you use it.',
			'budget.templateNameHint' => 'Example: Monthly groceries',
			'budget.templateEnabledLabel' => 'Offer this template',
			'budget.templateEnabledHelp' => 'Inactive templates stay saved but cannot be used to create a budget.',
			'budget.templateSaveAction' => 'Save Template',
			'budget.templateDeleteAction' => 'Delete Template',
			'budget.templateDeleteConfirmTitle' => 'Delete template?',
			'budget.templateDeleteConfirmMessage' => ({required Object name}) => 'Template "${name}" will be deleted. Budgets created from it are not deleted.',
			'budget.templateSavedMessage' => 'Template saved.',
			'budget.templateUpdatedMessage' => 'Template changes saved.',
			'budget.templateDeletedMessage' => 'Template deleted.',
			'budget.templateDuplicatedMessage' => 'Template duplicated.',
			'budget.templateCopyName' => ({required Object name}) => '${name} (copy)',
			'budget.fromTemplateStepLabel' => ({required Object name}) => 'From template ${name}',
			'budget.templateNameLabel' => 'Template name',
			'freelance.title' => 'Freelance',
			'freelance.worklogTab' => ({required Object count}) => 'Worklog (${count})',
			'freelance.paymentsTab' => ({required Object count}) => 'Payments (${count})',
			'freelance.loadErrorTitle' => 'Freelance data failed to load',
			'freelance.ruleTitle' => 'Freelance cash rule',
			'freelance.ruleBody' => 'Work hours add up to an invoice, and your wallet balance grows when its payment is recorded as received.',
			'freelance.summaryTitle' => 'Pay & hours summary',
			'freelance.totalHoursLabel' => 'Hours worked',
			'freelance.hoursValue' => ({required Object hours}) => '${hours} h',
			'freelance.hourShort' => 'h',
			'freelance.projectCount' => ({required Object count}) => 'Projects: ${count}',
			'freelance.earnedLabel' => 'Total earned',
			'freelance.earnedCaption' => 'Hours × rate, before deductions',
			'freelance.paidLabel' => 'Received',
			'freelance.paidCaption' => 'Gross pay · payment already recorded',
			'freelance.unpaidLabel' => 'Not received',
			'freelance.unpaidCaption' => 'Gross pay · unbilled or pending',
			'freelance.paidRatio' => ({required Object percent}) => '${percent}% received',
			'freelance.projectsLabel' => 'Projects',
			'freelance.projectsEmpty' => 'No projects yet. Add a client or project with its hourly rate first.',
			'freelance.projectStepLabel' => 'Freelance project',
			'freelance.projectAddTitle' => 'Add Project',
			'freelance.projectEditTitle' => 'Edit Project',
			'freelance.projectNameLabel' => 'Client or project name',
			'freelance.projectNameHint' => 'Example: Studio Koding',
			'freelance.requiredHint' => 'Required',
			'freelance.hourlyRateLabel' => 'Hourly rate',
			'freelance.hourlyRateHelp' => 'Default rate for new entries. Changing it does not change entries already recorded.',
			'freelance.deductionsLabel' => 'Deductions',
			'freelance.deductionsHelp' => 'Taken from the gross pay of each payment, such as tax. Changing them does not change payments already created.',
			'freelance.deductionAddAction' => 'Add deduction',
			'freelance.deductionTitle' => 'Deduction',
			'freelance.deductionLabelLabel' => 'Deduction name',
			'freelance.deductionLabelHint' => 'Example: Tax',
			'freelance.deductionKindPercentage' => 'Percent',
			'freelance.deductionKindFixed' => 'Fixed amount',
			'freelance.deductionPercentLabel' => 'Percent of gross pay',
			'freelance.deductionPercentHelp' => 'At most one decimal place, for example 2.5.',
			'freelance.deductionAmountLabel' => 'Amount per payment',
			'freelance.deductionSaveAction' => 'Save deduction',
			'freelance.deductionRemoveAction' => 'Remove deduction',
			'freelance.projectSaveAction' => 'Save project',
			'freelance.projectDeleteAction' => 'Delete project',
			'freelance.projectDeleteLockedHint' => 'A project that already has worklog entries cannot be deleted.',
			'freelance.projectDeleteConfirmTitle' => 'Delete project?',
			'freelance.projectDeleteConfirmMessage' => ({required Object name}) => 'Project "${name}" will be deleted.',
			'freelance.projectDeleteRefused' => 'This project already has worklog entries, so it cannot be deleted.',
			'freelance.projectSavedMessage' => 'Project saved.',
			'freelance.projectUpdatedMessage' => 'Project changes saved.',
			'freelance.projectDeletedMessage' => 'Project deleted.',
			'freelance.projectLabel' => 'Project',
			'freelance.projectPick' => 'Choose a project',
			'freelance.entryStepLabel' => 'Work log',
			'freelance.entryAddTitle' => 'Add Worklog',
			'freelance.entryEditTitle' => 'Edit Worklog',
			'freelance.entryRuleBody' => 'Work hours add up to an invoice. The money reaches your balance when its payment is recorded as received.',
			'freelance.workDateLabel' => 'Work date',
			'freelance.hoursLabel' => 'Duration',
			'freelance.entryRateHelp' => 'Filled from the project rate. Change it if this entry\'s rate differs.',
			'freelance.noteLabel' => 'Note',
			'freelance.noteHint' => 'What was done (optional)',
			'freelance.entrySaveAction' => 'Save Worklog',
			'freelance.entrySaveHint' => 'This amount is recorded as earned, not yet received.',
			'freelance.entryDeleteAction' => 'Delete entry',
			'freelance.entryDeleteConfirmTitle' => 'Delete worklog entry?',
			'freelance.entryDeleteConfirmMessage' => 'This entry will be deleted. Wallet balances do not change.',
			'freelance.entryLockedMessage' => 'Entries already in a payment cannot be edited or deleted.',
			'freelance.entrySavedMessage' => 'Worklog saved.',
			'freelance.entryUpdatedMessage' => 'Worklog changes saved.',
			'freelance.entryDeletedMessage' => 'Worklog deleted.',
			'freelance.hoursTimesRate' => ({required Object hours, required Object rate}) => '${hours} h × ${rate}',
			'freelance.statusUnbilled' => 'Unbilled',
			'freelance.statusPending' => 'Pending',
			'freelance.statusPaid' => 'Received',
			'freelance.expectedOn' => ({required Object date}) => 'Expected ${date}',
			'freelance.receivedOn' => ({required Object date, required Object wallet}) => 'Received ${date} in ${wallet}',
			'freelance.unknownProject' => 'Deleted project',
			'freelance.unknownWallet' => 'deleted wallet',
			'freelance.pendingTotalLabel' => 'Pending (net)',
			'freelance.paidTotalLabel' => 'Received (net)',
			'freelance.paymentCount' => ({required Object count}) => 'Payments: ${count}',
			'freelance.paymentStepLabel' => 'Freelance payment',
			'freelance.paymentAddTitle' => 'Create Payment',
			'freelance.paymentCreateRuleBody' => 'A payment groups work hours into one invoice. Once it\'s recorded as received, your wallet balance grows.',
			'freelance.paymentEntriesLabel' => ({required Object count, required Object hours}) => 'Billed entries: ${count} (${hours} h)',
			'freelance.paymentEntriesSummary' => ({required Object count, required Object hours}) => 'Entries: ${count} · ${hours} h',
			'freelance.expectedDateLabel' => 'Expected date received',
			'freelance.grossPayLabel' => 'Gross pay',
			'freelance.netPayLabel' => 'Net pay',
			'freelance.netPayNotPositive' => 'Deductions cannot equal or exceed gross pay.',
			'freelance.paymentCreateAction' => 'Create Payment',
			'freelance.paymentChangeDateAction' => 'Change date',
			'freelance.paymentDeleteAction' => 'Delete',
			'freelance.paymentDeleteConfirmTitle' => 'Delete payment?',
			'freelance.paymentDeleteConfirmMessage' => 'This pending payment is deleted and its entries become unbilled again. Wallet balances do not change.',
			'freelance.paymentEntriesInvalid' => 'The chosen entries are already billed or belong to another project.',
			'freelance.paymentPaidLocked' => 'A received payment cannot be deleted. Cancel its receipt first.',
			'freelance.paymentAlreadyPaid' => 'This payment is already recorded as received.',
			'freelance.paymentCreatedMessage' => 'Payment created.',
			'freelance.paymentUpdatedMessage' => 'Payment date updated.',
			'freelance.paymentDeletedMessage' => 'Payment deleted.',
			'freelance.receiveTitle' => 'Record Payment Received',
			'freelance.receiveRuleTitle' => 'Payment received',
			'freelance.receiveRuleBody' => 'Record it once the money has reached you. The chosen wallet grows by the net pay, and this invoice is marked paid.',
			'freelance.receiveAmountLabel' => 'Amount received',
			'freelance.receiveWalletLabel' => 'Receiving wallet',
			'freelance.receiveDateLabel' => 'Date received',
			'freelance.receiveNoteDefault' => ({required Object project}) => 'Freelance payment ${project}',
			'freelance.receiveAction' => 'Record Received',
			'freelance.paymentReceivedMessage' => 'Payment recorded as received. Wallet balance increased.',
			'freelance.receiptCancelAction' => 'Cancel receipt',
			'freelance.receiptCancelConfirmTitle' => 'Cancel receipt?',
			'freelance.receiptCancelConfirmMessage' => 'Its income record is deleted and the wallet balance goes back down. The payment becomes pending again.',
			'freelance.receiptCancelledMessage' => 'Receipt cancelled. The payment is pending again.',
			'freelance.changeAction' => 'Change',
			'freelance.receiptCancelConfirmAction' => 'Delete income',
			'freelance.billAction' => ({required Object count}) => 'Bill (${count})',
			'freelance.entriesEmptyBadge' => 'No work hours yet',
			'freelance.entriesEmptyTitle' => 'No worklog yet',
			'freelance.entriesEmptyBody' => 'Log this project\'s work hours with the + Worklog button below.',
			'freelance.entriesFilteredEmpty' => 'No entries with this status.',
			'freelance.entryAddShortAction' => '+ Worklog',
			'freelance.entryCountLabel' => ({required Object count}) => 'Entries: ${count}',
			'freelance.filterAll' => 'All',
			'freelance.lastEntryOn' => ({required Object date}) => 'Last ${date}',
			'freelance.noDeductions' => 'No deductions',
			'freelance.noEntriesYet' => 'No entries yet',
			'freelance.projectTotals' => ({required Object hours, required Object amount}) => 'Total ${hours} h · ${amount}',
			'freelance.projectsEmptyBadge' => 'No projects yet',
			'freelance.projectsEmptyTitle' => 'No projects yet',
			'freelance.unbilledLabel' => 'Unbilled',
			'freelance.unbilledNone' => 'Everything is billed',
			'freelance.paymentsEmptyBadge' => 'No invoices yet',
			'freelance.paymentsEmptyTitle' => 'No payments yet',
			'freelance.paymentsEmptyBody' => 'Tap Bill below to group unbilled work hours into one payment.',
			'freelance.paymentsFilteredEmpty' => 'No payments with this status.',
			'freelance.nextExpected' => ({required Object count, required Object date}) => 'Invoices: ${count} · next ${date}',
			'freelance.paymentWorkRange' => ({required Object range}) => 'Work ${range}',
			'home.loadErrorTitle' => 'Home failed to load',
			'home.balanceLabel' => 'Total active cash',
			'home.walletCount' => ({required Object count}) => 'Active wallets: ${count}',
			'home.moreWallets' => ({required Object count}) => '+${count} more',
			'home.startBadge' => 'Start recording',
			'home.noWalletsBody' => 'No wallet balance recorded yet.',
			'home.incomeLabel' => ({required Object month}) => 'Income ${month}',
			'home.expenseLabel' => ({required Object month}) => 'Expenses ${month}',
			'home.budgetTitle' => 'Active budgets',
			'home.budgetRemaining' => 'Remaining',
			'home.budgetOver' => 'Over plan',
			'home.budgetAction' => 'View Budgets',
			'home.freelanceTitle' => 'Freelance',
			'home.freelancePaid' => ({required Object amount}) => 'Received: ${amount}',
			'home.freelanceAction' => 'View Freelance',
			'home.recentTitle' => 'Recent transactions',
			'home.seeAll' => 'See all',
			'home.emptyBadge' => 'Empty inventory',
			'home.emptyTitle' => 'No transactions yet',
			'home.emptyBody' => 'Start by recording your first income, expense, or transfer.',
			'home.emptyNoWalletBody' => 'Create your first wallet with its starting balance, then record your first transaction.',
			'home.recordAction' => 'Record Transaction',
			'home.createWalletAction' => 'Create First Wallet',
			'home.budgetLink' => 'Or create a spending budget',
			'home.guideTitle' => 'Quick guide',
			'home.guideCount' => '3 core rules',
			'home.guideWalletTitle' => 'Wallets',
			'home.guideWalletTag' => 'Real assets',
			'home.guideWalletBody' => 'Record bank accounts, digital wallets, or cash with their current balance.',
			'home.guideBudgetTitle' => 'Budgets',
			'home.guideBudgetTag' => 'Plans',
			'home.guideBudgetBody' => 'Plan spending limits and track how much is used.',
			_ => null,
		} ?? switch (path) {
			'home.guideFreelanceTitle' => 'Freelance',
			'home.guideFreelanceTag' => 'Receivables',
			'home.guideFreelanceBody' => 'Track work hours and invoices. Money reaches a wallet only when its payment is recorded as received.',
			'home.budgetSpentOf' => ({required Object spent, required Object planned}) => '${spent} used of ${planned}',
			'home.freelanceUnpaidTitle' => 'Not received (gross)',
			'home.freelanceDueLabel' => 'Due',
			'home.freelancePendingInvoices' => ({required Object count}) => 'Pending invoices: ${count}',
			'home.freelanceSummaryLine' => ({required Object hours, required Object earned}) => '${hours} · earned ${earned}',
			'home.openCard' => ({required Object name}) => 'Open ${name}',
			'home.budgetUsedBadge' => ({required Object percent}) => '${percent}% used',
			'onboarding.skipAction' => 'Skip',
			'onboarding.nextAction' => 'Next',
			'onboarding.closeAction' => 'Close',
			'onboarding.pageIndicatorLabel' => ({required Object current, required Object total}) => 'Page ${current} of ${total}',
			'onboarding.page1Title' => 'All your money, one book',
			'onboarding.page1Body' => 'See where your money is, what happens to it, and where you plan for it to go — all in your personal cash book.',
			'onboarding.page2Title' => 'Know where your money is',
			'onboarding.page2Body' => 'Bank accounts, e-wallets, and cash become wallets. Each wallet\'s balance and the total are always in view.',
			'onboarding.page3Title' => 'Record in seconds',
			'onboarding.page3Body' => 'Money in, money out, or moved between wallets — tap RECORD. Your usual wallet and favorite categories are already waiting.',
			'onboarding.page4Title' => 'Plan, then track',
			'onboarding.page4Body' => 'Set weekly or monthly budgets with your spending items. Your balance stays intact, and you see how much of the plan is used.',
			'onboarding.finalTitle' => 'Start with your first wallet',
			'onboarding.finalBody' => 'Add one wallet, then record your first transaction. On every screen, the tanuki will show you the way.',
			'onboarding.createWalletAction' => 'Create First Wallet',
			'onboarding.laterAction' => 'Maybe later',
			'onboarding.signInAction' => 'Have an account? Sign in',
			'onboarding.backAction' => 'Back',
			'onboarding.currencyTitle' => 'Choose your currency',
			'onboarding.currencyBody' => 'Every amount in Tanukonomy uses this currency. You can change it later on the Account screen, but amounts you\'ve already recorded aren\'t converted.',
			'onboarding.currencySuggested' => 'Matches your device region',
			'onboarding.currencyChooseFirst' => 'Choose a currency first',
			'onboarding.currencyConfirm' => ({required Object code}) => 'Use ${code}',
			'tour.nextAction' => 'Next',
			'tour.doneAction' => 'Done',
			'tour.skipAction' => 'Skip tour',
			'tour.stepCounter' => ({required Object current, required Object total}) => '${current}/${total}',
			'tour.stepSemantics' => ({required Object current, required Object total, required Object title, required Object body}) => 'Step ${current} of ${total}: ${title}. ${body}',
			'tour.homeBalanceTitle' => 'Total recorded balance',
			'tour.homeBalanceBody' => 'The sum of all active wallets — where your money stands at a glance.',
			'tour.homeRecordTitle' => 'One door for recording',
			'tour.homeRecordBody' => 'Every bit of money in, out, and between wallets is recorded from here.',
			'tour.homeCashFlowTitle' => 'This month\'s flow',
			'tour.homeCashFlowBody' => 'The money that actually came in and went out this month.',
			'tour.homeBudgetTitle' => 'Active budget left',
			'tour.homeBudgetBody' => 'What\'s left of the plan in budgets running now. Tap for details.',
			'tour.homeFreelanceTitle' => 'Freelance summary',
			'tour.homeFreelanceBody' => 'Income you\'ve earned and what\'s still pending. A wallet balance only goes up when a payment is recorded as received.',
			'tour.homeRecentTitle' => 'Recent transactions',
			'tour.homeRecentBody' => 'Your latest records. Tap one for details, or See all for the month-by-month history.',
			'tour.recordKindTitle' => 'Pick the kind',
			'tour.recordKindBody' => 'Out lowers a balance, In raises it, and Transfer only moves money between your wallets — your total stays the same.',
			'tour.recordFreelanceTitle' => 'Freelance pay has its own path',
			'tour.recordFreelanceBody' => 'Project pay is recorded as a received payment in Freelance, so its work hours and invoice are settled too.',
			'tour.recordAmountTitle' => 'Amount',
			'tour.recordAmountBody' => 'Type the amount, or use the quick buttons.',
			'tour.recordWalletTitle' => 'Wallet filled in for you',
			'tour.recordWalletBody' => 'The wallet you used last is already selected. Change it if needed.',
			'tour.recordBudgetItemTitle' => 'Link to a budget',
			'tour.recordBudgetItemBody' => 'Optional. A linked expense adds to that item\'s used amount, as long as its date is inside the budget period.',
			'tour.walletSummaryTitle' => 'Total across wallets',
			'tour.walletSummaryBody' => 'The sum of recorded balances of active wallets.',
			'tour.walletCardTitle' => 'Wallet details',
			'tour.walletCardBody' => 'Tap to see this wallet\'s history and record straight from there.',
			'tour.walletAddTitle' => 'Add a wallet',
			'tour.walletAddBody' => 'Bank account, e-wallet, or cash. Its starting balance can be changed anytime, and the recorded balance follows.',
			'tour.txnMonthTitle' => 'One month per view',
			'tour.txnMonthBody' => 'Switch months to see other history. The in and out totals here cover only the month shown.',
			'tour.txnFilterTitle' => 'Search and filter',
			'tour.txnFilterBody' => 'Search notes or categories, then filter by wallet and category with Filter. If this month has no match, the search can continue into other months.',
			'tour.txnRowTitle' => 'Edit or delete',
			'tour.txnRowBody' => 'Tap a transaction for its details; from there you can edit, record it again, or delete it, and balances are recalculated.',
			'tour.budgetSummaryTitle' => 'Left across active budgets',
			'tour.budgetSummaryBody' => 'Plan minus used — the spending room left across your active budgets.',
			'tour.budgetFilterTitle' => 'Active first',
			'tour.budgetFilterBody' => 'The list shows active budgets. Choose Finished or Inactive to see older ones.',
			'tour.budgetTemplatesTitle' => 'Use templates',
			'tour.budgetTemplatesBody' => 'Save a recurring set of items, then create new budgets from it.',
			'tour.budgetDetailItemTitle' => 'Budget item',
			'tour.budgetDetailItemBody' => 'Used goes up from transactions linked to this item within the budget period.',
			'tour.budgetDetailRecordTitle' => 'Record from an item',
			'tour.budgetDetailRecordBody' => 'Opens RECORD with this item already selected.',
			'tour.freelanceProjectTitle' => 'Projects and rates',
			'tour.freelanceProjectBody' => 'Each project has an hourly rate and deductions. Tap a project to log hours and payments.',
			'tour.freelanceWorklogTitle' => 'Hours worked',
			'tour.freelanceWorklogBody' => 'Work hours are income you\'ve earned. Group them into an invoice, then record it when you\'re paid.',
			'tour.freelanceReceiveTitle' => 'Money actually arrives',
			'tour.freelanceReceiveBody' => 'Record it when the pay arrives: your wallet balance grows and the invoice is settled.',
			'info.menuTooltip' => 'Info and tours',
			'info.replayTourAction' => 'Tour this screen',
			'info.showIntroAction' => 'Tanukonomy introduction',
			'info.resetAllAction' => 'Reset all tutorials',
			'info.resetConfirmTitle' => 'Reset tutorials?',
			'info.resetConfirmMessage' => 'The introduction and every tour will show again like the first time. Your financial data isn\'t touched.',
			'info.resetConfirmAction' => 'Reset',
			'info.resetDoneMessage' => 'Tutorials reset.',
			'account.title' => 'Account',
			'account.signedOutTitle' => 'Set up your account',
			'account.signedOutBody' => 'Everything you record works fully without an account. An account prepares you for the backup and cross-device sync we\'re building.',
			'account.googleSignInAction' => 'Sign in with Google',
			'account.emailSignInToggle' => 'Sign in with email',
			'account.emailFormHint' => 'For accounts that were created for you.',
			'account.emailLabel' => 'Email',
			'account.passwordLabel' => 'Password',
			'account.emailSignInAction' => 'Sign in',
			'account.emailRequired' => 'Enter your email and password first.',
			'account.signedInMessage' => 'You\'re signed in.',
			'account.signedOutMessage' => 'You\'re signed out.',
			'account.methodGoogle' => 'Signed in with Google',
			'account.methodPassword' => 'Signed in with email',
			'account.dataTitle' => 'Your data',
			'account.dataBody' => 'Wallets, transactions, and budgets are stored on this device. Signing out or deleting your account doesn\'t touch them.',
			'account.signOutAction' => 'Sign out',
			'account.dangerTitle' => 'Danger zone',
			'account.dangerBody' => 'Deleting your account is permanent and can\'t be undone.',
			'account.deleteAction' => 'Delete Account',
			'account.deleteConfirmTitle' => 'Delete account?',
			'account.deleteConfirmBody' => 'Your account is permanently deleted. Wallets, transactions, and budgets on this device stay.',
			'account.deletePasswordTitle' => 'Enter your password',
			'account.deletePasswordBody' => 'For your security, enter your password again to delete your account.',
			'account.deletedMessage' => 'Account deleted.',
			'account.errors.network' => 'Can\'t connect. Check your internet connection, then try again.',
			'account.errors.wrongCredentials' => 'Wrong email or password.',
			'account.errors.tooManyRequests' => 'Too many attempts. Wait a moment, then try again.',
			'account.errors.userDisabled' => 'This account has been disabled.',
			'account.errors.other' => 'Couldn\'t sign in. Try again.',
			'currency.settingsTitle' => 'Settings',
			'currency.label' => 'Currency',
			'currency.pickerTitle' => 'Choose currency',
			'currency.changeTitle' => ({required Object code}) => 'Switch to ${code}?',
			'currency.changeBody' => ({required Object before, required Object after}) => 'Amounts you\'ve already recorded aren\'t converted; only the symbol changes. For example, ${before} will show as ${after}.',
			'currency.changeAction' => 'Switch',
			'currency.changedMessage' => ({required Object code}) => 'Currency switched to ${code}.',
			'currency.names.idr' => 'Indonesian Rupiah',
			'currency.names.usd' => 'US Dollar',
			'currency.names.eur' => 'Euro',
			'currency.names.gbp' => 'British Pound',
			'currency.names.jpy' => 'Japanese Yen',
			'currency.names.cny' => 'Chinese Yuan',
			'currency.names.krw' => 'South Korean Won',
			'currency.names.inr' => 'Indian Rupee',
			'currency.names.sgd' => 'Singapore Dollar',
			'currency.names.myr' => 'Malaysian Ringgit',
			'currency.names.thb' => 'Thai Baht',
			'currency.names.php' => 'Philippine Peso',
			'currency.names.vnd' => 'Vietnamese Dong',
			'currency.names.aud' => 'Australian Dollar',
			_ => null,
		};
	}
}
