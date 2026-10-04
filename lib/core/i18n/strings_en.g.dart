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
	@override late final _Translations$category$en category = _Translations$category$en._(_root);
	@override late final _Translations$language$en language = _Translations$language$en._(_root);
	@override late final _Translations$notificationCapture$en notificationCapture = _Translations$notificationCapture$en._(_root);
	@override late final _Translations$recurring$en recurring = _Translations$recurring$en._(_root);
	@override late final _Translations$plan$en plan = _Translations$plan$en._(_root);
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
	@override String quickAmountThousands({required Object amount}) => '+${amount}k';
	@override String quickAmountMillions({required Object amount}) => '+${amount}M';
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
	@override String get transactionsTabLabel => 'History';
	@override String get walletsTabLabel => 'Wallets';
	@override String get planTabLabel => 'Plan';
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
	@override String get noteFieldHint => 'Write a short note';
	@override String get noWalletsMessage => 'No wallets yet. Create one in the Wallets tab first.';
	@override String get sameWalletWarning => 'Source and destination wallets can\'t be the same.';
	@override String get incomeSavedMessage => 'Income recorded.';
	@override String get expenseSavedMessage => 'Expense recorded.';
	@override String get transferSavedMessage => 'Transfer recorded.';
	@override String get walletNotSelectedPrompt => 'Not selected yet';
	@override String get savingMessage => 'Saving...';
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
	@override String get categoryAddLabel => 'Add category';
	@override String get draftHeardLabel => 'Heard';
	@override String get draftCheckTitle => 'Check before recording';
	@override late final _Translations$record$draftIssue$en draftIssue = _Translations$record$draftIssue$en._(_root);
	@override late final _Translations$record$voice$en voice = _Translations$record$voice$en._(_root);
	@override late final _Translations$record$repeat$en repeat = _Translations$record$repeat$en._(_root);
}

// Path: transaction
class _Translations$transaction$en extends Translations$transaction$id {
	_Translations$transaction$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pageTitle => 'History';
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
	@override String get makeRecurringAction => 'Make Recurring';
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
	@override String get repeatLabel => 'Repeat every period';
	@override String repeatHelpMonthly({required Object date}) => 'Starts again every month from ${date} with the same items.';
	@override String repeatHelpWeekly({required Object date}) => 'Starts again every week from ${date} with the same items.';
	@override String get repeatUnavailable => 'Monthly budgets can repeat when they start on the 1st–28th.';
	@override String get repeatPastNote => 'This period has ended. Changes here don\'t affect later periods.';
	@override String get scopeTitle => 'Apply to';
	@override String get scopeThisPeriod => 'This period only';
	@override String get scopeThisAndNext => 'This and later periods';
	@override String get recurringBadge => 'Repeats';
	@override String templateScheduledMonthly({required Object wallet}) => 'Repeats monthly · ${wallet}';
	@override String templateScheduledWeekly({required Object wallet}) => 'Repeats weekly · ${wallet}';
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
	@override String get languageTitle => 'Choose your language';
	@override String get languageBody => 'Used for the app and when recording by voice. You can change it later on the Account screen.';
	@override String get languageConfirm => 'Continue';
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
	@override String get homeVoiceTitle => 'Record by voice';
	@override String get homeVoiceBody => 'Tap, say one transaction, then check the form before recording it.';
	@override String get planTabsTitle => 'Plan';
	@override String get planTabsBody => 'This month, budgets, and recurring transactions live here. Tap to switch.';
	@override String get planUnplannedTitle => 'Unplanned money';
	@override String get planUnplannedBody => 'This month’s income minus everything already committed.';
	@override String get planForecastTitle => 'Wallet balance ≈';
	@override String get planForecastBody => 'Forecast balance to month end, including its lowest point.';
	@override String get homeForecastTitle => 'Balance forecast';
	@override String get homeForecastBody => 'Your forecast wallet balance at month end and its lowest point. Tap for the breakdown in Plan.';
	@override String get homePendingTitle => 'Waiting to record';
	@override String get homePendingBody => 'Recurring bills and income that are due. Record in one tap, edit first, or Skip.';
	@override String get recordRepeatTitle => 'Repeat';
	@override String get recordRepeatBody => 'For bills, salary, or subscriptions. Each next occurrence waits for you to record it; nothing is recorded silently.';
	@override String get recurringStartersTitle => 'Quick start';
	@override String get recurringStartersBody => 'Pick a common one, like salary or electricity. The form is filled in; just adjust it.';
	@override String get recurringSummaryTitle => 'Recurring still to go out';
	@override String get recurringSummaryBody => 'Recurring bills not yet recorded this month — money that already has somewhere to go.';
	@override String get recurringPendingTitle => 'Waiting to record';
	@override String get recurringPendingBody => 'Occurrences that are due. Record in one tap, edit first, or Skip this one.';
	@override String get recurringAddTitle => 'Add recurring';
	@override String get recurringAddBody => 'You can also use Repeat in RECORD, or Make Recurring in a transaction\'s details.';
	@override String get budgetRepeatTitle => 'Repeat every period';
	@override String get budgetRepeatBody => 'Turn on to start this budget again every month with the same items. No money is moved.';
	@override String get planMonthPickerTitle => 'Next months';
	@override String get planMonthPickerBody => 'See the forecast for the next two months. Each month shows its estimated month-end figure.';
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

// Path: category
class _Translations$category$en extends Translations$category$id {
	_Translations$category$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override Map<String, String> get builtIn => {
		'food': 'Food & Drinks',
		'groceries': 'Groceries',
		'transport': 'Transport',
		'bills': 'Bills',
		'internet': 'Phone & Internet',
		'health': 'Health',
		'entertainment': 'Entertainment',
		'shopping': 'Shopping',
		'education': 'Education',
		'family': 'Family',
		'donation': 'Donations',
		'expenseOther': 'Other',
		'salary': 'Salary',
		'freelance': 'Freelance',
		'bonus': 'Bonus',
		'gift': 'Gifts',
		'incomeOther': 'Other',
	};
	@override String get title => 'Categories';
	@override String get accountEntryTitle => 'Categories';
	@override String get accountEntryBody => 'Manage your income and expense categories.';
	@override String get expenseTab => 'Expense';
	@override String get incomeTab => 'Income';
	@override String get addAction => 'Add category';
	@override String get addTitle => 'New category';
	@override String get renameTitle => 'Rename category';
	@override String get nameHint => 'Category name';
	@override String get archiveAction => 'Archive';
	@override String get restoreAction => 'Restore';
	@override String get archivedSection => 'Archived';
	@override String get archivedHint => 'Not offered when recording, but old transactions keep it.';
	@override String get emptyActive => 'No active categories yet.';
	@override String archivedMessage({required Object name}) => '"${name}" archived.';
	@override String restoredMessage({required Object name}) => '"${name}" restored.';
}

// Path: language
class _Translations$language$en extends Translations$language$id {
	_Translations$language$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Language';
	@override String get pickerTitle => 'Choose language';
	@override String get hint => 'App text and voice recording';
}

// Path: notificationCapture
class _Translations$notificationCapture$en extends Translations$notificationCapture$id {
	_Translations$notificationCapture$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get accountEntryTitle => 'Record from notifications';
	@override String get accountEntryBody => 'Record automatically from bank and e-wallet notifications.';
	@override String get settingsTitle => 'Record from notifications';
	@override String get enableLabel => 'Turn on';
	@override String get accessMissingTitle => 'Permission needed to read notifications';
	@override String get accessMissingBody => 'Without it, Tanukonomy can\'t see your bank notifications.';
	@override String get accessAction => 'Grant permission';
	@override String get accessGranted => 'Notification permission is on';
	@override String get disclosureTitle => 'Before you grant permission';
	@override String get disclosureBody => 'Tanukonomy will be able to read notifications on your phone.\n\n• Only from apps you pick that match their filter.\n• OTP notifications are never stored.\n• Text that is hard to read may be sent to Gemini (Google).\n• Notification text stays on your phone for at most 7 days.';
	@override String get disclosureAccept => 'Continue';
	@override String get reminderPermissionDenied => 'Notification permission was denied. Turn it on in Android settings to get notified.';
	@override String get sourcesTitle => 'Apps';
	@override String get sourcesEmpty => 'Pick the bank or e-wallet apps whose notifications you want recorded.';
	@override String get addSource => 'Add app';
	@override String get sourceNoWallet => 'No wallet chosen';
	@override String get sourcePaused => 'Paused';
	@override String get pickAppTitle => 'Pick an app';
	@override String get searchApps => 'Search apps';
	@override String get builtInPatternsBadge => 'Built-in patterns';
	@override String get appsLoadFailed => 'Couldn\'t read the app list.';
	@override String get appsEmpty => 'No matching apps.';
	@override String get sourceEnabled => 'Listen to this app';
	@override String get walletLabel => 'Wallet';
	@override String get walletNone => 'Choose a wallet';
	@override String get keywordsLabel => 'Filter';
	@override String get keywordsHint => 'Only notifications containing one of these phrases are read.';
	@override String get keywordField => 'Add a phrase';
	@override String get addKeyword => 'Add';
	@override String get patternsTitle => 'Patterns';
	@override String get patternsHint => 'Teach Tanukonomy how to read this app\'s notification format.';
	@override String get patternsEmpty => 'No patterns yet. Tanukonomy still reads with general rules.';
	@override String get builtInUnverified => 'Built-in · you always check the result';
	@override String get builtInVerified => 'Built-in';
	@override String get newPattern => 'Make a pattern from an example';
	@override String get removeSource => 'Remove this app';
	@override String removeSourceConfirm({required Object app}) => 'Stop reading notifications from ${app}?';
	@override String get save => 'Save';
	@override String get patternTitle => 'Make a pattern';
	@override String get patternSampleLabel => 'Example notification';
	@override String get patternSampleHint => 'Paste the notification text here';
	@override String get patternInstructions => 'Pick a marker, then tap the words. Tap again to clear a mark.';
	@override String get roleAmount => 'Amount';
	@override String get roleNote => 'Note';
	@override String get roleIgnore => 'Ignore';
	@override String get patternKindLabel => 'Type';
	@override String get kindExpense => 'Out';
	@override String get kindIncome => 'In';
	@override String get kindTransferOut => 'Transfer out';
	@override String get kindTransferIn => 'Transfer in';
	@override String get patternCategory => 'Category';
	@override String get patternNoCategory => 'No category';
	@override String get patternTransferWallet => 'Other wallet';
	@override String get patternLabelField => 'Pattern name (optional)';
	@override String patternPreview({required Object amount}) => 'Reads as: ${amount}';
	@override String get patternInvalid => 'Mark one amount. Note words must be next to each other.';
	@override String get deletePattern => 'Delete pattern';
	@override String get inboxTitle => 'Notification inbox';
	@override String get inboxPendingTitle => 'To check';
	@override String get inboxAutoTitle => 'Recorded automatically';
	@override String get inboxEmpty => 'Nothing to check.';
	@override String get inboxAutoEmpty => 'Nothing recorded automatically yet.';
	@override String get inboxRetention => 'This list is kept for 7 days.';
	@override String get amountUnknown => 'Amount not read yet';
	@override String get possibleDuplicate => 'May already be recorded';
	@override String get recordAction => 'Record';
	@override String get dismissAction => 'Dismiss';
	@override String get makePatternAction => 'Make a pattern from this text';
	@override String get reviewAction => 'View';
	@override String get undoAction => 'Undo';
	@override String get undoConfirmTitle => 'Undo this transaction?';
	@override String get undoConfirm => 'The transaction is deleted and the wallet balance goes back to what it was.';
	@override String get undone => 'Automatic transaction undone.';
	@override String get dismissed => 'Capture dismissed.';
	@override String banner({required Object n}) => '${n} transactions from notifications to check';
	@override String get bannerAction => 'Check';
	@override String autoRecordedSnack({required Object amount, required Object app}) => 'Recorded automatically: ${amount} · ${app}';
	@override String autoRecordedSnackMany({required Object n}) => '${n} transactions recorded automatically from notifications';
	@override String get reminderChannel => 'Record from notifications';
	@override String get reminderCapturedTitle => 'Transaction from {app} captured';
	@override String get reminderCapturedBody => 'Tap to record it.';
	@override String reminderReviewTitle({required Object amount, required Object app}) => 'Check ${amount} from ${app}';
	@override String get reminderReviewBody => 'Tap to record it.';
	@override String reminderRecordedTitle({required Object amount, required Object app}) => 'Recorded ${amount} · ${app}';
	@override String get reminderRecordedBody => 'Tap to view.';
	@override String get debugSamplesTitle => 'Captured text samples (debug)';
	@override String get debugSamplesHint => 'Tap to copy. Anonymize before sharing.';
	@override String get debugSamplesEmpty => 'No notifications from registered apps yet.';
	@override String get debugShellSource => 'Add adb test source (com.android.shell)';
	@override String get copied => 'Copied.';
	@override String get keywordsEmptyWarning => 'Without a filter, no notifications are read.';
	@override String get addDefaultKeywords => 'Use the built-in filter';
	@override String get sourceKeywordsNone => 'Empty filter — nothing is read';
	@override String get enableHint => 'Transactions from the bank and e-wallet notifications you pick are recorded for you.';
	@override String get inboxEntryTitle => 'Inbox';
	@override String get inboxEntryBody => 'Check captures and undo automatic records.';
	@override String get behaviorTitle => 'When a transaction is caught';
	@override String get autoRecordLabel => 'Record automatically';
	@override String get autoRecordOffHint => 'Everything waits for you to check in the inbox.';
	@override String get autoRecordOnHint => 'Clear ones are saved right away. Unsure ones still wait for you.';
	@override String get autoRecordAnyCategoryLabel => 'Even if the category isn\'t clear';
	@override String get autoRecordAnyCategoryHint => 'You can fill in the category later.';
	@override String get reminderLabel => 'Notify me';
	@override String get reminderHint => 'Get a notification each time a transaction is caught.';
	@override String sourceWallet({required Object name}) => '${name} wallet';
	@override String get walletHelp => 'Transactions from this app are recorded in this wallet.';
	@override String get advancedTitle => 'Filter and patterns';
	@override String get advancedHint => 'Optional';
	@override String get patternMarkLabel => 'Mark the parts';
	@override String patternNotAmount({required Object word}) => '"${word}" is not an amount. Amounts use Rp or thousands separators.';
	@override String get kindTransfer => 'Transfer';
	@override String get transferDirectionLabel => 'Transfer direction';
	@override String get patternTransferWalletNone => 'Not set';
	@override String get patternTemplateToggle => 'Edit template';
	@override String get moreActions => 'More';
}

// Path: recurring
class _Translations$recurring$en extends Translations$recurring$id {
	_Translations$recurring$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$recurring$starters$en starters = _Translations$recurring$starters$en._(_root);
	@override String summaryTitle({required Object month}) => 'Recurring ${month}';
	@override String get remainingOutLabel => 'Still to go out';
	@override String recordedOfTotal({required Object recorded, required Object total}) => '${recorded} of ${total} recorded';
	@override String get scheduledInLabel => 'Scheduled income';
	@override String subscriptionsLine({required Object perMonth, required Object perYear}) => 'Subscriptions ${perMonth}/mo · ${perYear}/yr';
	@override String approxSemantics({required Object amount}) => 'about ${amount}';
	@override String filterAll({required Object n}) => 'All (${n})';
	@override String filterIncome({required Object n}) => 'In (${n})';
	@override String filterExpense({required Object n}) => 'Out (${n})';
	@override String filterTransfer({required Object n}) => 'Transfer (${n})';
	@override String get groupPending => 'Waiting to record';
	@override String get groupThisMonth => 'This month';
	@override String get groupLater => 'Later';
	@override String get groupPaused => 'Paused';
	@override String get groupEnded => 'Ended';
	@override String get recordedMeta => 'recorded';
	@override String get pendingMeta => 'waiting';
	@override String missedMeta({required Object n}) => '${n} missed';
	@override String get skippedMeta => 'skipped';
	@override String get paymentAutoDebit => 'auto-debit';
	@override String get paymentManual => 'I pay it';
	@override String get yearlyMeta => 'yearly';
	@override String priceUp({required Object amount, required Object usual}) => '${amount}, usually ${usual}';
	@override String get emptyTitle => 'No recurring yet';
	@override String get emptyBody => 'Add what comes every month, then see what is truly free.';
	@override String get filteredEmpty => 'Nothing here yet.';
	@override String get showAllAction => 'Show all';
	@override String get addAction => 'Add recurring';
	@override String get loadError => 'Could not load recurring.';
	@override String get retryAction => 'Try again';
	@override String get nextTitle => 'Next';
	@override String get recordedTitle => 'Recorded';
	@override String get skipAction => 'Skip';
	@override String get unskipAction => 'Undo skip';
	@override String get editAction => 'Edit';
	@override String get pauseAction => 'Pause';
	@override String get resumeAction => 'Resume';
	@override String get endAction => 'End';
	@override String get deleteAction => 'Delete';
	@override String get moreActions => 'More actions';
	@override String get deleteTitle => 'Delete recurring?';
	@override String get deleteBody => 'Recorded transactions are kept.';
	@override String progressLine({required Object k, required Object n}) => '${k} of ${n} recorded';
	@override String endsOnLine({required Object date}) => 'ends ${date}';
	@override String countLine({required Object n}) => '${n} times';
	@override String get pausedLine => 'Paused';
	@override String reminderLine({required Object n}) => 'I pay it · reminded ${n} day(s) before';
	@override String get autoDebitLine => 'Auto-debit';
	@override String pausedMessage({required Object name}) => '${name} paused.';
	@override String resumedMessage({required Object name}) => '${name} resumed.';
	@override String endedMessage({required Object name}) => '${name} ended.';
	@override String deletedMessage({required Object name}) => '${name} deleted.';
	@override String skippedMessage({required Object date}) => '${date} skipped.';
	@override String priceUpdateAction({required Object amount}) => 'Update to ${amount}';
	@override String get notFound => 'This recurring no longer exists.';
	@override String get noRecorded => 'Nothing recorded yet.';
	@override String recordedMessage({required Object name}) => '${name} recorded.';
	@override String recordedAllMessage({required Object n}) => '${n} recurring recorded.';
	@override String linkedMessage({required Object name}) => '${name} linked.';
	@override String get undoAction => 'Undo';
	@override String get similarTitle => 'Already recorded?';
	@override String similarBody({required Object name, required Object amount, required Object date}) => 'Looks like ${name} ${amount} · ${date}, already recorded.';
	@override String get linkAction => 'Link';
	@override String get recordNewAction => 'Record new';
	@override String get recordAction => 'Record';
	@override String get editFirstAction => 'Edit first';
	@override String get recordAllAction => 'Record all';
	@override String get seeAllAction => 'See all';
	@override String get pendingCardTitle => 'Waiting to record';
	@override String unusualAmountNotice({required Object usual}) => 'Usually ${usual}. Check the amount again.';
	@override String farDateNotice({required Object date}) => 'Scheduled for ${date}. Make sure the date is right.';
	@override String occurrenceNotice({required Object name, required Object date}) => 'Recording ${name} · ${date}';
	@override String matchLabel({required Object name, required Object date}) => 'Matches recurring ${name} · ${date}';
	@override String get linkedTitle => 'Matched to recurring';
	@override String get unlinkAction => 'Unlink';
	@override String get unlinkedMessage => 'Unlinked. The occurrence is waiting again.';
	@override String get reminderChannelName => 'Recurring reminders';
	@override String get reminderChannelDescription => 'Recurring bills and income that are due.';
	@override String reminderSoonTitle({required Object n}) => 'In ${n} day(s)';
	@override String get reminderTodayTitle => 'Due today';
	@override String reminderTodayManyTitle({required Object n}) => '${n} recurring due today';
	@override String alreadyRecordedMessage({required Object name}) => '${name} is already recorded.';
	@override String get remindersTitle => 'Recurring reminders';
	@override String get remindersBody => 'Reminded a day before bills you pay yourself, and on the due day.';
	@override String get remindersDenied => 'Notification permission was not granted. Turn it on in system settings.';
	@override String get ruleRemindersLabel => 'Remind me';
	@override String get remindersOffHint => 'Recurring reminders are off. Turn them on in Account.';
	@override String positionMeta({required Object k, required Object n}) => '${k} of ${n}';
	@override String toWalletMeta({required Object wallet}) => 'to ${wallet}';
	@override String remainingTitle({required Object month}) => 'Recurring still to go out · ${month}';
	@override String get plannedLabel => 'Planned';
	@override String get outLabel => 'Already out';
	@override String get chipAll => 'All';
	@override String get chipIncome => 'In';
	@override String get chipExpense => 'Out';
	@override String get chipTransfer => 'Transfer';
	@override String get budgetLinkLabel => 'Budget item';
	@override String get budgetLinkNone => 'Not linked. Link it so it isn\'t counted twice with a budget.';
	@override String budgetLinkValue({required Object item, required Object budget}) => '${item} · ${budget}';
	@override String get budgetLinkPickerTitle => 'Link to a repeating budget item';
	@override String get budgetLinkRemove => 'Unlink';
	@override String get budgetLinkEmpty => 'No repeating budget items in this wallet yet.';
	@override String budgetLinkedMessage({required Object name, required Object item}) => '${name} is linked to ${item}.';
	@override String budgetUnlinkedMessage({required Object name}) => '${name} is no longer linked to a budget item.';
	@override String fundingTitle({required Object wallet}) => 'Prepare funds in ${wallet}';
	@override String fundingBody({required Object name, required Object amount, required Object date, required Object shortfall}) => '${name} ${amount} on ${date}. Expected short ≈${shortfall}.';
	@override String installmentFreeLine({required Object month, required Object amount}) => 'From ${month} you free up +${amount}/mo.';
	@override String get unseenLabel => 'Not seen in notifications yet';
	@override String get notYetAction => 'Not yet';
	@override String snoozedMessage({required Object name}) => 'We\'ll ask about ${name} again in 2 days.';
	@override String idleTitle({required Object name}) => 'Still using ${name}?';
	@override String get idleBody => 'The last two were skipped or not seen.';
	@override String get idleKeep => 'Keep';
}

// Path: plan
class _Translations$plan$en extends Translations$plan$id {
	_Translations$plan$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get recurringSegmentLabel => 'Recurring';
	@override String get financialMonthTitle => 'Financial month start';
	@override String get financialMonthPickerTitle => 'Financial month starts on';
	@override String financialMonthDay({required Object day}) => 'Day ${day}';
	@override String get thisMonthSegmentLabel => 'This month';
	@override String unplannedTitle({required Object month}) => 'Unplanned money · ${month}';
	@override String get incomeRow => 'Income';
	@override String get billsRow => 'Recurring bills';
	@override String get budgetRow => 'Budgets';
	@override String get offPlanRow => 'Off plan';
	@override String get infoAction => 'Explanation';
	@override String get infoTitle => 'Unplanned money';
	@override String get infoIncome => '+ Planned income';
	@override String get infoBills => '− Recurring bills';
	@override String get infoBudget => '− Budgets';
	@override String get infoOffPlan => '± Off plan (already recorded)';
	@override String get infoResult => '= Unplanned money';
	@override String get infoNotBalance => 'Not your wallet balance.';
	@override String get balanceTitle => 'Wallet balance ≈';
	@override String get allWallets => 'All';
	@override String endOf({required Object date}) => 'End of ${date}';
	@override String lowestOn({required Object date}) => 'Lowest · ${date}';
	@override String get detailsAction => 'Details';
	@override String get todayLabel => 'today';
	@override String approx({required Object amount}) => 'about ${amount}';
	@override String get detailsTitle => 'Balance forecast';
	@override String get detailsNow => 'Balance now';
	@override String get detailsIncome => 'Recurring income';
	@override String get detailsBills => 'Recurring bills';
	@override String get detailsBudget => 'Budget left';
	@override String detailsUnplanned({required Object perDay}) => 'Off plan · ${perDay}/day';
	@override String get detailsUncertain => 'Unpaid freelance (not certain)';
	@override String get detailsTransfers => 'Recurring transfers';
	@override String detailsEnd({required Object date}) => 'End of ${date}';
	@override String get unplannedToggle => 'Count daily spending';
	@override String get unplannedUnavailable => 'Needs a full month of history.';
	@override String get nextTitle => 'Next';
	@override String get seeAllRecurring => 'All in Recurring';
	@override String get emptyTitle => 'Plan this month';
	@override String get emptyBody => 'Add what comes every month, then see what is truly free.';
	@override String chartSemantics({required Object low, required Object date, required Object end}) => 'Balance forecast, lowest ${low} on ${date}, month end ${end}';
	@override String chartPoint({required Object date, required Object amount}) => '${date} · ${amount}';
	@override String forecastRow({required Object date, required Object amount, required Object low, required Object lowDate}) => 'End ${date} ≈${amount} · lowest ≈${low} (${lowDate})';
	@override String get loadError => 'Could not load this month.';
	@override String get forecastBadge => 'FORECAST';
	@override String startOf({required Object date}) => 'Start ${date}';
	@override String compactMillion({required Object value}) => '${value}M';
	@override String compactThousand({required Object value}) => '${value}K';
	@override String get fundingTitle => 'PREPARE FUNDS';
	@override String fundingBody({required Object wallet, required Object shortfall, required Object name, required Object date}) => '${wallet} is expected to be short by ≈${shortfall} for ${name} on ${date}. Add funds to ${wallet} before then.';
	@override String fundingAction({required Object wallet}) => 'See ${wallet} forecast';
	@override String fundingMore({required Object n}) => '+${n} more';
	@override String reviewTitle({required Object month}) => '${month} has started';
	@override String reviewProgress({required Object done, required Object total}) => '${done}/${total}';
	@override String reviewBudgets({required Object amount}) => 'This month\'s repeating budgets: ${amount}, started automatically.';
	@override String reviewEstimate({required Object name, required Object amount}) => '${name} ≈${amount}, still right?';
	@override String reviewLookback({required Object month}) => 'Look back at ${month}';
	@override String get reviewOk => 'Looks right';
	@override String get reviewEdit => 'Edit';
	@override String get reviewEditEstimate => 'Edit estimate';
	@override String get reviewSee => 'See';
	@override String get reviewDone => 'Done reviewing';
	@override String get reviewLater => 'Later';
	@override String reviewCollapsed({required Object month, required Object done, required Object total}) => 'Review ${month} plan (${done}/${total})';
	@override String reviewDoneMessage({required Object month}) => '${month} plan is ready.';
	@override String homeReviewBody({required Object income, required Object committed, required Object free}) => 'Scheduled income ${income}, committed ${committed}, free ${free}.';
	@override String get homeReviewEstimates => 'Some repeating amounts are estimates worth checking.';
	@override String get homeReviewAction => 'Review plan';
	@override String lookbackTitle({required Object month}) => '${month} look back';
	@override String get lookbackPlanned => 'Plan';
	@override String get lookbackActual => 'Actual';
	@override String get lookbackFree => 'Free money';
	@override String lookbackBiggest({required Object line}) => 'Biggest difference: ${line}.';
	@override String accuracyExact({required Object month}) => 'The ${month} forecast was spot on.';
	@override String accuracyMissed({required Object month, required Object amount}) => 'The ${month} forecast was off by ${amount}.';
	@override String accuracyMissedBy({required Object month, required Object amount, required Object line}) => 'The ${month} forecast was off by ${amount}, mostly from ${line}.';
	@override String committedShare({required Object percent, required Object month}) => '${percent}% of ${month} income is already committed (repeating + budgets).';
	@override String committedShareVs({required Object percent, required Object month, required Object previous}) => '${percent}% of ${month} income is already committed (repeating + budgets); the month before, ${previous}%.';
	@override String installmentFree({required Object name, required Object month, required Object amount}) => 'After ${name} ends, from ${month} you free up +${amount}/mo.';
}

// Path: record.draftIssue
class _Translations$record$draftIssue$en extends Translations$record$draftIssue$id {
	_Translations$record$draftIssue$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get amountMissing => 'Couldn\'t catch the amount. Enter it yourself.';
	@override String get amountMultiple => 'More than one amount was mentioned. Enter the right one.';
	@override String get amountWithoutUnit => 'A number without a unit (thousand/million). Check the amount.';
	@override String get amountAmbiguous => 'The amount can be read two ways. Check it.';
	@override String get currencyUnsupported => 'The currency mentioned differs from the app currency.';
	@override String get walletUnknown => 'The wallet mentioned doesn\'t exist. Pick a wallet.';
	@override String get transferSourceMissing => 'The source wallet is unclear. Pick where it came from.';
	@override String get transferTargetMissing => 'The destination wallet is unclear. Pick where it went.';
	@override String get categoryUnknown => 'The category mentioned doesn\'t exist. Pick a category.';
	@override String get dateUnclear => 'The date mentioned can\'t be used. Pick the date.';
	@override String get kindUnclear => 'The direction isn\'t clear. Choose Out or In.';
}

// Path: record.voice
class _Translations$record$voice$en extends Translations$record$voice$id {
	_Translations$record$voice$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Record by voice';
	@override String get micLabel => 'Record by voice';
	@override String get listening => 'Go ahead, speak.';
	@override String get autoStopHint => 'Stops by itself when you pause.';
	@override String get example => 'Example: “lunch 35 thousand with BCA”';
	@override String get interpreting => 'Understanding…';
	@override String get typeInstead => 'Type instead';
	@override late final _Translations$record$voice$failure$en failure = _Translations$record$voice$failure$en._(_root);
	@override String get idleHint => 'Tap the microphone, then say one transaction.';
	@override String get recordingBadge => 'REC';
	@override String get startAction => 'Start recording';
	@override String get listeningButtonLabel => 'Listening';
	@override String get retryAction => 'Record again';
	@override String get languageTitle => 'Which language will you speak?';
	@override String get languageBody => 'Used to recognize your speech and for the app display. You can change it in Account.';
	@override String get languageContinue => 'Continue';
}

// Path: record.repeat
class _Translations$record$repeat$en extends Translations$record$repeat$id {
	_Translations$record$repeat$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Repeat';
	@override String get off => 'No';
	@override String get weekly => 'Weekly';
	@override String get monthly => 'Monthly';
	@override String get yearly => 'Yearly';
	@override String everyWeekday({required Object day}) => 'Every ${day}';
	@override String everyMonthDay({required Object day}) => 'Every month on day ${day}';
	@override String everyYearDate({required Object date}) => 'Every ${date}';
	@override String everyNWeeks({required Object n}) => 'Every ${n} weeks';
	@override String everyNMonths({required Object n}) => 'Every ${n} months';
	@override String everyNYears({required Object n}) => 'Every ${n} years';
	@override String get moreAction => 'More options';
	@override String get lessAction => 'Decrease';
	@override String get moreCountAction => 'Increase';
	@override String get endLabel => 'Ends';
	@override String get endNever => 'Never';
	@override String get endAfter => 'After N times';
	@override String get endOn => 'On a date';
	@override String endsAfterSummary({required Object n}) => '${n} times';
	@override String endsOnSummary({required Object date}) => 'until ${date}';
	@override String get amountLabel => 'Amount';
	@override String get amountFixed => 'Fixed';
	@override String get amountEstimated => 'Varies';
	@override String get paymentLabel => 'Payment';
	@override String get paymentManual => 'I pay it';
	@override String get paymentAutoDebit => 'Auto-debit';
	@override String get recordAndScheduleAction => 'Record & Schedule';
	@override String get saveScheduleAction => 'Save Schedule';
	@override String scheduledMessage({required Object name, required Object date}) => '${name} scheduled. First on ${date}.';
	@override String recordedMessage({required Object name}) => '${name} recorded and scheduled.';
	@override String recordedNextMessage({required Object name, required Object date}) => '${name} recorded. Next on ${date}.';
	@override String get fallbackName => 'Recurring';
	@override String updatedMessage({required Object name}) => '${name} updated.';
	@override String linkSuggestionAction({required Object item}) => 'Link to ${item}';
	@override String get autoRecordLabel => 'Record automatically';
	@override String get autoRecordHint => 'Recorded for you when you open the app on the date; auto-debit waits a day. You can undo it.';
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

// Path: recurring.starters
class _Translations$recurring$starters$en extends Translations$recurring$starters$id {
	_Translations$recurring$starters$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get salary => 'Salary';
	@override String get rent => 'Rent';
	@override String get electricity => 'Electricity';
	@override String get internet => 'Internet';
	@override String get bpjs => 'BPJS';
	@override String get installment => 'Installment';
	@override String get paylater => 'Paylater';
	@override String get subscription => 'Subscription';
	@override String get parents => 'Send to parents';
	@override String get arisan => 'Arisan';
	@override String get savings => 'Savings';
}

// Path: record.voice.failure
class _Translations$record$voice$failure$en extends Translations$record$voice$failure$id {
	_Translations$record$voice$failure$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get permissionDenied => 'Microphone access was denied. Allow it in device settings.';
	@override String get unavailable => 'This device doesn\'t have a speech recognizer yet.';
	@override String get languageOffline => 'This language can\'t be recognized offline on this phone yet. Connect to the internet, or download its language pack in the device\'s speech recognition settings.';
	@override String get noMatch => 'Didn\'t catch anything. Try again.';
	@override String get network => 'Recognizing speech needs internet on this device. Connect and record again, or type instead.';
	@override String get other => 'Something went wrong. Try again.';
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
			'common.quickAmountThousands' => ({required Object amount}) => '+${amount}k',
			'common.quickAmountMillions' => ({required Object amount}) => '+${amount}M',
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
			'appShell.transactionsTabLabel' => 'History',
			'appShell.walletsTabLabel' => 'Wallets',
			'appShell.planTabLabel' => 'Plan',
			'record.incomeAction' => 'Record Income',
			'record.expenseAction' => 'Record Expense',
			'record.transferAction' => 'Record Transfer',
			'record.toWalletFieldLabel' => 'Into Wallet',
			'record.fromWalletFieldLabel' => 'From Wallet',
			'record.destinationWalletFieldLabel' => 'To Wallet',
			'record.dateFieldLabel' => 'Date',
			'record.noteFieldHint' => 'Write a short note',
			'record.noWalletsMessage' => 'No wallets yet. Create one in the Wallets tab first.',
			'record.sameWalletWarning' => 'Source and destination wallets can\'t be the same.',
			'record.incomeSavedMessage' => 'Income recorded.',
			'record.expenseSavedMessage' => 'Expense recorded.',
			'record.transferSavedMessage' => 'Transfer recorded.',
			'record.walletNotSelectedPrompt' => 'Not selected yet',
			'record.savingMessage' => 'Saving...',
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
			'record.categoryAddLabel' => 'Add category',
			'record.draftHeardLabel' => 'Heard',
			'record.draftCheckTitle' => 'Check before recording',
			'record.draftIssue.amountMissing' => 'Couldn\'t catch the amount. Enter it yourself.',
			'record.draftIssue.amountMultiple' => 'More than one amount was mentioned. Enter the right one.',
			'record.draftIssue.amountWithoutUnit' => 'A number without a unit (thousand/million). Check the amount.',
			'record.draftIssue.amountAmbiguous' => 'The amount can be read two ways. Check it.',
			'record.draftIssue.currencyUnsupported' => 'The currency mentioned differs from the app currency.',
			'record.draftIssue.walletUnknown' => 'The wallet mentioned doesn\'t exist. Pick a wallet.',
			'record.draftIssue.transferSourceMissing' => 'The source wallet is unclear. Pick where it came from.',
			'record.draftIssue.transferTargetMissing' => 'The destination wallet is unclear. Pick where it went.',
			'record.draftIssue.categoryUnknown' => 'The category mentioned doesn\'t exist. Pick a category.',
			'record.draftIssue.dateUnclear' => 'The date mentioned can\'t be used. Pick the date.',
			'record.draftIssue.kindUnclear' => 'The direction isn\'t clear. Choose Out or In.',
			'record.voice.title' => 'Record by voice',
			'record.voice.micLabel' => 'Record by voice',
			'record.voice.listening' => 'Go ahead, speak.',
			'record.voice.autoStopHint' => 'Stops by itself when you pause.',
			'record.voice.example' => 'Example: “lunch 35 thousand with BCA”',
			'record.voice.interpreting' => 'Understanding…',
			'record.voice.typeInstead' => 'Type instead',
			'record.voice.failure.permissionDenied' => 'Microphone access was denied. Allow it in device settings.',
			'record.voice.failure.unavailable' => 'This device doesn\'t have a speech recognizer yet.',
			'record.voice.failure.languageOffline' => 'This language can\'t be recognized offline on this phone yet. Connect to the internet, or download its language pack in the device\'s speech recognition settings.',
			'record.voice.failure.noMatch' => 'Didn\'t catch anything. Try again.',
			'record.voice.failure.network' => 'Recognizing speech needs internet on this device. Connect and record again, or type instead.',
			'record.voice.failure.other' => 'Something went wrong. Try again.',
			'record.voice.idleHint' => 'Tap the microphone, then say one transaction.',
			'record.voice.recordingBadge' => 'REC',
			'record.voice.startAction' => 'Start recording',
			'record.voice.listeningButtonLabel' => 'Listening',
			'record.voice.retryAction' => 'Record again',
			'record.voice.languageTitle' => 'Which language will you speak?',
			'record.voice.languageBody' => 'Used to recognize your speech and for the app display. You can change it in Account.',
			'record.voice.languageContinue' => 'Continue',
			'record.repeat.label' => 'Repeat',
			'record.repeat.off' => 'No',
			'record.repeat.weekly' => 'Weekly',
			'record.repeat.monthly' => 'Monthly',
			'record.repeat.yearly' => 'Yearly',
			'record.repeat.everyWeekday' => ({required Object day}) => 'Every ${day}',
			'record.repeat.everyMonthDay' => ({required Object day}) => 'Every month on day ${day}',
			'record.repeat.everyYearDate' => ({required Object date}) => 'Every ${date}',
			'record.repeat.everyNWeeks' => ({required Object n}) => 'Every ${n} weeks',
			'record.repeat.everyNMonths' => ({required Object n}) => 'Every ${n} months',
			'record.repeat.everyNYears' => ({required Object n}) => 'Every ${n} years',
			'record.repeat.moreAction' => 'More options',
			'record.repeat.lessAction' => 'Decrease',
			'record.repeat.moreCountAction' => 'Increase',
			'record.repeat.endLabel' => 'Ends',
			'record.repeat.endNever' => 'Never',
			'record.repeat.endAfter' => 'After N times',
			'record.repeat.endOn' => 'On a date',
			'record.repeat.endsAfterSummary' => ({required Object n}) => '${n} times',
			'record.repeat.endsOnSummary' => ({required Object date}) => 'until ${date}',
			'record.repeat.amountLabel' => 'Amount',
			'record.repeat.amountFixed' => 'Fixed',
			'record.repeat.amountEstimated' => 'Varies',
			'record.repeat.paymentLabel' => 'Payment',
			'record.repeat.paymentManual' => 'I pay it',
			'record.repeat.paymentAutoDebit' => 'Auto-debit',
			'record.repeat.recordAndScheduleAction' => 'Record & Schedule',
			'record.repeat.saveScheduleAction' => 'Save Schedule',
			'record.repeat.scheduledMessage' => ({required Object name, required Object date}) => '${name} scheduled. First on ${date}.',
			'record.repeat.recordedMessage' => ({required Object name}) => '${name} recorded and scheduled.',
			'record.repeat.recordedNextMessage' => ({required Object name, required Object date}) => '${name} recorded. Next on ${date}.',
			'record.repeat.fallbackName' => 'Recurring',
			'record.repeat.updatedMessage' => ({required Object name}) => '${name} updated.',
			'record.repeat.linkSuggestionAction' => ({required Object item}) => 'Link to ${item}',
			'record.repeat.autoRecordLabel' => 'Record automatically',
			'record.repeat.autoRecordHint' => 'Recorded for you when you open the app on the date; auto-debit waits a day. You can undo it.',
			'transaction.pageTitle' => 'History',
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
			'transaction.makeRecurringAction' => 'Make Recurring',
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
			'budget.repeatLabel' => 'Repeat every period',
			'budget.repeatHelpMonthly' => ({required Object date}) => 'Starts again every month from ${date} with the same items.',
			'budget.repeatHelpWeekly' => ({required Object date}) => 'Starts again every week from ${date} with the same items.',
			'budget.repeatUnavailable' => 'Monthly budgets can repeat when they start on the 1st–28th.',
			'budget.repeatPastNote' => 'This period has ended. Changes here don\'t affect later periods.',
			'budget.scopeTitle' => 'Apply to',
			'budget.scopeThisPeriod' => 'This period only',
			'budget.scopeThisAndNext' => 'This and later periods',
			'budget.recurringBadge' => 'Repeats',
			'budget.templateScheduledMonthly' => ({required Object wallet}) => 'Repeats monthly · ${wallet}',
			'budget.templateScheduledWeekly' => ({required Object wallet}) => 'Repeats weekly · ${wallet}',
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
			_ => null,
		} ?? switch (path) {
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
			'onboarding.languageTitle' => 'Choose your language',
			'onboarding.languageBody' => 'Used for the app and when recording by voice. You can change it later on the Account screen.',
			'onboarding.languageConfirm' => 'Continue',
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
			'tour.homeVoiceTitle' => 'Record by voice',
			'tour.homeVoiceBody' => 'Tap, say one transaction, then check the form before recording it.',
			'tour.planTabsTitle' => 'Plan',
			'tour.planTabsBody' => 'This month, budgets, and recurring transactions live here. Tap to switch.',
			'tour.planUnplannedTitle' => 'Unplanned money',
			'tour.planUnplannedBody' => 'This month’s income minus everything already committed.',
			'tour.planForecastTitle' => 'Wallet balance ≈',
			'tour.planForecastBody' => 'Forecast balance to month end, including its lowest point.',
			'tour.homeForecastTitle' => 'Balance forecast',
			'tour.homeForecastBody' => 'Your forecast wallet balance at month end and its lowest point. Tap for the breakdown in Plan.',
			'tour.homePendingTitle' => 'Waiting to record',
			'tour.homePendingBody' => 'Recurring bills and income that are due. Record in one tap, edit first, or Skip.',
			'tour.recordRepeatTitle' => 'Repeat',
			'tour.recordRepeatBody' => 'For bills, salary, or subscriptions. Each next occurrence waits for you to record it; nothing is recorded silently.',
			'tour.recurringStartersTitle' => 'Quick start',
			'tour.recurringStartersBody' => 'Pick a common one, like salary or electricity. The form is filled in; just adjust it.',
			'tour.recurringSummaryTitle' => 'Recurring still to go out',
			'tour.recurringSummaryBody' => 'Recurring bills not yet recorded this month — money that already has somewhere to go.',
			'tour.recurringPendingTitle' => 'Waiting to record',
			'tour.recurringPendingBody' => 'Occurrences that are due. Record in one tap, edit first, or Skip this one.',
			'tour.recurringAddTitle' => 'Add recurring',
			'tour.recurringAddBody' => 'You can also use Repeat in RECORD, or Make Recurring in a transaction\'s details.',
			'tour.budgetRepeatTitle' => 'Repeat every period',
			'tour.budgetRepeatBody' => 'Turn on to start this budget again every month with the same items. No money is moved.',
			'tour.planMonthPickerTitle' => 'Next months',
			'tour.planMonthPickerBody' => 'See the forecast for the next two months. Each month shows its estimated month-end figure.',
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
			'category.builtIn.food' => 'Food & Drinks',
			'category.builtIn.groceries' => 'Groceries',
			'category.builtIn.transport' => 'Transport',
			'category.builtIn.bills' => 'Bills',
			'category.builtIn.internet' => 'Phone & Internet',
			'category.builtIn.health' => 'Health',
			'category.builtIn.entertainment' => 'Entertainment',
			'category.builtIn.shopping' => 'Shopping',
			'category.builtIn.education' => 'Education',
			'category.builtIn.family' => 'Family',
			'category.builtIn.donation' => 'Donations',
			'category.builtIn.expenseOther' => 'Other',
			'category.builtIn.salary' => 'Salary',
			'category.builtIn.freelance' => 'Freelance',
			'category.builtIn.bonus' => 'Bonus',
			'category.builtIn.gift' => 'Gifts',
			'category.builtIn.incomeOther' => 'Other',
			'category.title' => 'Categories',
			'category.accountEntryTitle' => 'Categories',
			'category.accountEntryBody' => 'Manage your income and expense categories.',
			'category.expenseTab' => 'Expense',
			'category.incomeTab' => 'Income',
			'category.addAction' => 'Add category',
			'category.addTitle' => 'New category',
			'category.renameTitle' => 'Rename category',
			'category.nameHint' => 'Category name',
			'category.archiveAction' => 'Archive',
			'category.restoreAction' => 'Restore',
			'category.archivedSection' => 'Archived',
			'category.archivedHint' => 'Not offered when recording, but old transactions keep it.',
			'category.emptyActive' => 'No active categories yet.',
			'category.archivedMessage' => ({required Object name}) => '"${name}" archived.',
			'category.restoredMessage' => ({required Object name}) => '"${name}" restored.',
			'language.label' => 'Language',
			'language.pickerTitle' => 'Choose language',
			'language.hint' => 'App text and voice recording',
			'notificationCapture.accountEntryTitle' => 'Record from notifications',
			'notificationCapture.accountEntryBody' => 'Record automatically from bank and e-wallet notifications.',
			'notificationCapture.settingsTitle' => 'Record from notifications',
			'notificationCapture.enableLabel' => 'Turn on',
			'notificationCapture.accessMissingTitle' => 'Permission needed to read notifications',
			'notificationCapture.accessMissingBody' => 'Without it, Tanukonomy can\'t see your bank notifications.',
			'notificationCapture.accessAction' => 'Grant permission',
			'notificationCapture.accessGranted' => 'Notification permission is on',
			'notificationCapture.disclosureTitle' => 'Before you grant permission',
			'notificationCapture.disclosureBody' => 'Tanukonomy will be able to read notifications on your phone.\n\n• Only from apps you pick that match their filter.\n• OTP notifications are never stored.\n• Text that is hard to read may be sent to Gemini (Google).\n• Notification text stays on your phone for at most 7 days.',
			'notificationCapture.disclosureAccept' => 'Continue',
			'notificationCapture.reminderPermissionDenied' => 'Notification permission was denied. Turn it on in Android settings to get notified.',
			'notificationCapture.sourcesTitle' => 'Apps',
			'notificationCapture.sourcesEmpty' => 'Pick the bank or e-wallet apps whose notifications you want recorded.',
			'notificationCapture.addSource' => 'Add app',
			'notificationCapture.sourceNoWallet' => 'No wallet chosen',
			'notificationCapture.sourcePaused' => 'Paused',
			'notificationCapture.pickAppTitle' => 'Pick an app',
			'notificationCapture.searchApps' => 'Search apps',
			'notificationCapture.builtInPatternsBadge' => 'Built-in patterns',
			'notificationCapture.appsLoadFailed' => 'Couldn\'t read the app list.',
			'notificationCapture.appsEmpty' => 'No matching apps.',
			'notificationCapture.sourceEnabled' => 'Listen to this app',
			'notificationCapture.walletLabel' => 'Wallet',
			'notificationCapture.walletNone' => 'Choose a wallet',
			'notificationCapture.keywordsLabel' => 'Filter',
			'notificationCapture.keywordsHint' => 'Only notifications containing one of these phrases are read.',
			'notificationCapture.keywordField' => 'Add a phrase',
			'notificationCapture.addKeyword' => 'Add',
			'notificationCapture.patternsTitle' => 'Patterns',
			'notificationCapture.patternsHint' => 'Teach Tanukonomy how to read this app\'s notification format.',
			'notificationCapture.patternsEmpty' => 'No patterns yet. Tanukonomy still reads with general rules.',
			'notificationCapture.builtInUnverified' => 'Built-in · you always check the result',
			'notificationCapture.builtInVerified' => 'Built-in',
			'notificationCapture.newPattern' => 'Make a pattern from an example',
			'notificationCapture.removeSource' => 'Remove this app',
			'notificationCapture.removeSourceConfirm' => ({required Object app}) => 'Stop reading notifications from ${app}?',
			'notificationCapture.save' => 'Save',
			'notificationCapture.patternTitle' => 'Make a pattern',
			'notificationCapture.patternSampleLabel' => 'Example notification',
			'notificationCapture.patternSampleHint' => 'Paste the notification text here',
			'notificationCapture.patternInstructions' => 'Pick a marker, then tap the words. Tap again to clear a mark.',
			'notificationCapture.roleAmount' => 'Amount',
			'notificationCapture.roleNote' => 'Note',
			'notificationCapture.roleIgnore' => 'Ignore',
			'notificationCapture.patternKindLabel' => 'Type',
			'notificationCapture.kindExpense' => 'Out',
			'notificationCapture.kindIncome' => 'In',
			'notificationCapture.kindTransferOut' => 'Transfer out',
			'notificationCapture.kindTransferIn' => 'Transfer in',
			'notificationCapture.patternCategory' => 'Category',
			'notificationCapture.patternNoCategory' => 'No category',
			'notificationCapture.patternTransferWallet' => 'Other wallet',
			'notificationCapture.patternLabelField' => 'Pattern name (optional)',
			'notificationCapture.patternPreview' => ({required Object amount}) => 'Reads as: ${amount}',
			'notificationCapture.patternInvalid' => 'Mark one amount. Note words must be next to each other.',
			'notificationCapture.deletePattern' => 'Delete pattern',
			'notificationCapture.inboxTitle' => 'Notification inbox',
			'notificationCapture.inboxPendingTitle' => 'To check',
			'notificationCapture.inboxAutoTitle' => 'Recorded automatically',
			'notificationCapture.inboxEmpty' => 'Nothing to check.',
			'notificationCapture.inboxAutoEmpty' => 'Nothing recorded automatically yet.',
			'notificationCapture.inboxRetention' => 'This list is kept for 7 days.',
			'notificationCapture.amountUnknown' => 'Amount not read yet',
			'notificationCapture.possibleDuplicate' => 'May already be recorded',
			'notificationCapture.recordAction' => 'Record',
			'notificationCapture.dismissAction' => 'Dismiss',
			'notificationCapture.makePatternAction' => 'Make a pattern from this text',
			'notificationCapture.reviewAction' => 'View',
			'notificationCapture.undoAction' => 'Undo',
			'notificationCapture.undoConfirmTitle' => 'Undo this transaction?',
			'notificationCapture.undoConfirm' => 'The transaction is deleted and the wallet balance goes back to what it was.',
			'notificationCapture.undone' => 'Automatic transaction undone.',
			'notificationCapture.dismissed' => 'Capture dismissed.',
			'notificationCapture.banner' => ({required Object n}) => '${n} transactions from notifications to check',
			'notificationCapture.bannerAction' => 'Check',
			'notificationCapture.autoRecordedSnack' => ({required Object amount, required Object app}) => 'Recorded automatically: ${amount} · ${app}',
			'notificationCapture.autoRecordedSnackMany' => ({required Object n}) => '${n} transactions recorded automatically from notifications',
			'notificationCapture.reminderChannel' => 'Record from notifications',
			'notificationCapture.reminderCapturedTitle' => 'Transaction from {app} captured',
			'notificationCapture.reminderCapturedBody' => 'Tap to record it.',
			'notificationCapture.reminderReviewTitle' => ({required Object amount, required Object app}) => 'Check ${amount} from ${app}',
			'notificationCapture.reminderReviewBody' => 'Tap to record it.',
			'notificationCapture.reminderRecordedTitle' => ({required Object amount, required Object app}) => 'Recorded ${amount} · ${app}',
			'notificationCapture.reminderRecordedBody' => 'Tap to view.',
			'notificationCapture.debugSamplesTitle' => 'Captured text samples (debug)',
			'notificationCapture.debugSamplesHint' => 'Tap to copy. Anonymize before sharing.',
			'notificationCapture.debugSamplesEmpty' => 'No notifications from registered apps yet.',
			'notificationCapture.debugShellSource' => 'Add adb test source (com.android.shell)',
			'notificationCapture.copied' => 'Copied.',
			'notificationCapture.keywordsEmptyWarning' => 'Without a filter, no notifications are read.',
			'notificationCapture.addDefaultKeywords' => 'Use the built-in filter',
			'notificationCapture.sourceKeywordsNone' => 'Empty filter — nothing is read',
			'notificationCapture.enableHint' => 'Transactions from the bank and e-wallet notifications you pick are recorded for you.',
			'notificationCapture.inboxEntryTitle' => 'Inbox',
			'notificationCapture.inboxEntryBody' => 'Check captures and undo automatic records.',
			'notificationCapture.behaviorTitle' => 'When a transaction is caught',
			'notificationCapture.autoRecordLabel' => 'Record automatically',
			'notificationCapture.autoRecordOffHint' => 'Everything waits for you to check in the inbox.',
			'notificationCapture.autoRecordOnHint' => 'Clear ones are saved right away. Unsure ones still wait for you.',
			'notificationCapture.autoRecordAnyCategoryLabel' => 'Even if the category isn\'t clear',
			'notificationCapture.autoRecordAnyCategoryHint' => 'You can fill in the category later.',
			'notificationCapture.reminderLabel' => 'Notify me',
			'notificationCapture.reminderHint' => 'Get a notification each time a transaction is caught.',
			'notificationCapture.sourceWallet' => ({required Object name}) => '${name} wallet',
			'notificationCapture.walletHelp' => 'Transactions from this app are recorded in this wallet.',
			'notificationCapture.advancedTitle' => 'Filter and patterns',
			'notificationCapture.advancedHint' => 'Optional',
			'notificationCapture.patternMarkLabel' => 'Mark the parts',
			'notificationCapture.patternNotAmount' => ({required Object word}) => '"${word}" is not an amount. Amounts use Rp or thousands separators.',
			'notificationCapture.kindTransfer' => 'Transfer',
			'notificationCapture.transferDirectionLabel' => 'Transfer direction',
			'notificationCapture.patternTransferWalletNone' => 'Not set',
			'notificationCapture.patternTemplateToggle' => 'Edit template',
			'notificationCapture.moreActions' => 'More',
			'recurring.starters.salary' => 'Salary',
			'recurring.starters.rent' => 'Rent',
			'recurring.starters.electricity' => 'Electricity',
			'recurring.starters.internet' => 'Internet',
			'recurring.starters.bpjs' => 'BPJS',
			'recurring.starters.installment' => 'Installment',
			'recurring.starters.paylater' => 'Paylater',
			'recurring.starters.subscription' => 'Subscription',
			'recurring.starters.parents' => 'Send to parents',
			'recurring.starters.arisan' => 'Arisan',
			'recurring.starters.savings' => 'Savings',
			'recurring.summaryTitle' => ({required Object month}) => 'Recurring ${month}',
			'recurring.remainingOutLabel' => 'Still to go out',
			'recurring.recordedOfTotal' => ({required Object recorded, required Object total}) => '${recorded} of ${total} recorded',
			'recurring.scheduledInLabel' => 'Scheduled income',
			'recurring.subscriptionsLine' => ({required Object perMonth, required Object perYear}) => 'Subscriptions ${perMonth}/mo · ${perYear}/yr',
			'recurring.approxSemantics' => ({required Object amount}) => 'about ${amount}',
			'recurring.filterAll' => ({required Object n}) => 'All (${n})',
			'recurring.filterIncome' => ({required Object n}) => 'In (${n})',
			'recurring.filterExpense' => ({required Object n}) => 'Out (${n})',
			'recurring.filterTransfer' => ({required Object n}) => 'Transfer (${n})',
			'recurring.groupPending' => 'Waiting to record',
			'recurring.groupThisMonth' => 'This month',
			'recurring.groupLater' => 'Later',
			'recurring.groupPaused' => 'Paused',
			'recurring.groupEnded' => 'Ended',
			'recurring.recordedMeta' => 'recorded',
			'recurring.pendingMeta' => 'waiting',
			'recurring.missedMeta' => ({required Object n}) => '${n} missed',
			'recurring.skippedMeta' => 'skipped',
			'recurring.paymentAutoDebit' => 'auto-debit',
			'recurring.paymentManual' => 'I pay it',
			'recurring.yearlyMeta' => 'yearly',
			'recurring.priceUp' => ({required Object amount, required Object usual}) => '${amount}, usually ${usual}',
			'recurring.emptyTitle' => 'No recurring yet',
			'recurring.emptyBody' => 'Add what comes every month, then see what is truly free.',
			'recurring.filteredEmpty' => 'Nothing here yet.',
			'recurring.showAllAction' => 'Show all',
			'recurring.addAction' => 'Add recurring',
			'recurring.loadError' => 'Could not load recurring.',
			'recurring.retryAction' => 'Try again',
			'recurring.nextTitle' => 'Next',
			'recurring.recordedTitle' => 'Recorded',
			'recurring.skipAction' => 'Skip',
			'recurring.unskipAction' => 'Undo skip',
			'recurring.editAction' => 'Edit',
			'recurring.pauseAction' => 'Pause',
			'recurring.resumeAction' => 'Resume',
			'recurring.endAction' => 'End',
			'recurring.deleteAction' => 'Delete',
			'recurring.moreActions' => 'More actions',
			'recurring.deleteTitle' => 'Delete recurring?',
			'recurring.deleteBody' => 'Recorded transactions are kept.',
			'recurring.progressLine' => ({required Object k, required Object n}) => '${k} of ${n} recorded',
			'recurring.endsOnLine' => ({required Object date}) => 'ends ${date}',
			'recurring.countLine' => ({required Object n}) => '${n} times',
			'recurring.pausedLine' => 'Paused',
			'recurring.reminderLine' => ({required Object n}) => 'I pay it · reminded ${n} day(s) before',
			'recurring.autoDebitLine' => 'Auto-debit',
			'recurring.pausedMessage' => ({required Object name}) => '${name} paused.',
			'recurring.resumedMessage' => ({required Object name}) => '${name} resumed.',
			'recurring.endedMessage' => ({required Object name}) => '${name} ended.',
			'recurring.deletedMessage' => ({required Object name}) => '${name} deleted.',
			'recurring.skippedMessage' => ({required Object date}) => '${date} skipped.',
			'recurring.priceUpdateAction' => ({required Object amount}) => 'Update to ${amount}',
			'recurring.notFound' => 'This recurring no longer exists.',
			'recurring.noRecorded' => 'Nothing recorded yet.',
			'recurring.recordedMessage' => ({required Object name}) => '${name} recorded.',
			'recurring.recordedAllMessage' => ({required Object n}) => '${n} recurring recorded.',
			'recurring.linkedMessage' => ({required Object name}) => '${name} linked.',
			'recurring.undoAction' => 'Undo',
			'recurring.similarTitle' => 'Already recorded?',
			'recurring.similarBody' => ({required Object name, required Object amount, required Object date}) => 'Looks like ${name} ${amount} · ${date}, already recorded.',
			'recurring.linkAction' => 'Link',
			'recurring.recordNewAction' => 'Record new',
			'recurring.recordAction' => 'Record',
			'recurring.editFirstAction' => 'Edit first',
			'recurring.recordAllAction' => 'Record all',
			'recurring.seeAllAction' => 'See all',
			'recurring.pendingCardTitle' => 'Waiting to record',
			'recurring.unusualAmountNotice' => ({required Object usual}) => 'Usually ${usual}. Check the amount again.',
			'recurring.farDateNotice' => ({required Object date}) => 'Scheduled for ${date}. Make sure the date is right.',
			'recurring.occurrenceNotice' => ({required Object name, required Object date}) => 'Recording ${name} · ${date}',
			'recurring.matchLabel' => ({required Object name, required Object date}) => 'Matches recurring ${name} · ${date}',
			'recurring.linkedTitle' => 'Matched to recurring',
			'recurring.unlinkAction' => 'Unlink',
			'recurring.unlinkedMessage' => 'Unlinked. The occurrence is waiting again.',
			'recurring.reminderChannelName' => 'Recurring reminders',
			'recurring.reminderChannelDescription' => 'Recurring bills and income that are due.',
			'recurring.reminderSoonTitle' => ({required Object n}) => 'In ${n} day(s)',
			'recurring.reminderTodayTitle' => 'Due today',
			'recurring.reminderTodayManyTitle' => ({required Object n}) => '${n} recurring due today',
			'recurring.alreadyRecordedMessage' => ({required Object name}) => '${name} is already recorded.',
			'recurring.remindersTitle' => 'Recurring reminders',
			'recurring.remindersBody' => 'Reminded a day before bills you pay yourself, and on the due day.',
			'recurring.remindersDenied' => 'Notification permission was not granted. Turn it on in system settings.',
			'recurring.ruleRemindersLabel' => 'Remind me',
			'recurring.remindersOffHint' => 'Recurring reminders are off. Turn them on in Account.',
			'recurring.positionMeta' => ({required Object k, required Object n}) => '${k} of ${n}',
			'recurring.toWalletMeta' => ({required Object wallet}) => 'to ${wallet}',
			'recurring.remainingTitle' => ({required Object month}) => 'Recurring still to go out · ${month}',
			'recurring.plannedLabel' => 'Planned',
			'recurring.outLabel' => 'Already out',
			'recurring.chipAll' => 'All',
			'recurring.chipIncome' => 'In',
			'recurring.chipExpense' => 'Out',
			'recurring.chipTransfer' => 'Transfer',
			'recurring.budgetLinkLabel' => 'Budget item',
			'recurring.budgetLinkNone' => 'Not linked. Link it so it isn\'t counted twice with a budget.',
			'recurring.budgetLinkValue' => ({required Object item, required Object budget}) => '${item} · ${budget}',
			'recurring.budgetLinkPickerTitle' => 'Link to a repeating budget item',
			'recurring.budgetLinkRemove' => 'Unlink',
			_ => null,
		} ?? switch (path) {
			'recurring.budgetLinkEmpty' => 'No repeating budget items in this wallet yet.',
			'recurring.budgetLinkedMessage' => ({required Object name, required Object item}) => '${name} is linked to ${item}.',
			'recurring.budgetUnlinkedMessage' => ({required Object name}) => '${name} is no longer linked to a budget item.',
			'recurring.fundingTitle' => ({required Object wallet}) => 'Prepare funds in ${wallet}',
			'recurring.fundingBody' => ({required Object name, required Object amount, required Object date, required Object shortfall}) => '${name} ${amount} on ${date}. Expected short ≈${shortfall}.',
			'recurring.installmentFreeLine' => ({required Object month, required Object amount}) => 'From ${month} you free up +${amount}/mo.',
			'recurring.unseenLabel' => 'Not seen in notifications yet',
			'recurring.notYetAction' => 'Not yet',
			'recurring.snoozedMessage' => ({required Object name}) => 'We\'ll ask about ${name} again in 2 days.',
			'recurring.idleTitle' => ({required Object name}) => 'Still using ${name}?',
			'recurring.idleBody' => 'The last two were skipped or not seen.',
			'recurring.idleKeep' => 'Keep',
			'plan.recurringSegmentLabel' => 'Recurring',
			'plan.financialMonthTitle' => 'Financial month start',
			'plan.financialMonthPickerTitle' => 'Financial month starts on',
			'plan.financialMonthDay' => ({required Object day}) => 'Day ${day}',
			'plan.thisMonthSegmentLabel' => 'This month',
			'plan.unplannedTitle' => ({required Object month}) => 'Unplanned money · ${month}',
			'plan.incomeRow' => 'Income',
			'plan.billsRow' => 'Recurring bills',
			'plan.budgetRow' => 'Budgets',
			'plan.offPlanRow' => 'Off plan',
			'plan.infoAction' => 'Explanation',
			'plan.infoTitle' => 'Unplanned money',
			'plan.infoIncome' => '+ Planned income',
			'plan.infoBills' => '− Recurring bills',
			'plan.infoBudget' => '− Budgets',
			'plan.infoOffPlan' => '± Off plan (already recorded)',
			'plan.infoResult' => '= Unplanned money',
			'plan.infoNotBalance' => 'Not your wallet balance.',
			'plan.balanceTitle' => 'Wallet balance ≈',
			'plan.allWallets' => 'All',
			'plan.endOf' => ({required Object date}) => 'End of ${date}',
			'plan.lowestOn' => ({required Object date}) => 'Lowest · ${date}',
			'plan.detailsAction' => 'Details',
			'plan.todayLabel' => 'today',
			'plan.approx' => ({required Object amount}) => 'about ${amount}',
			'plan.detailsTitle' => 'Balance forecast',
			'plan.detailsNow' => 'Balance now',
			'plan.detailsIncome' => 'Recurring income',
			'plan.detailsBills' => 'Recurring bills',
			'plan.detailsBudget' => 'Budget left',
			'plan.detailsUnplanned' => ({required Object perDay}) => 'Off plan · ${perDay}/day',
			'plan.detailsUncertain' => 'Unpaid freelance (not certain)',
			'plan.detailsTransfers' => 'Recurring transfers',
			'plan.detailsEnd' => ({required Object date}) => 'End of ${date}',
			'plan.unplannedToggle' => 'Count daily spending',
			'plan.unplannedUnavailable' => 'Needs a full month of history.',
			'plan.nextTitle' => 'Next',
			'plan.seeAllRecurring' => 'All in Recurring',
			'plan.emptyTitle' => 'Plan this month',
			'plan.emptyBody' => 'Add what comes every month, then see what is truly free.',
			'plan.chartSemantics' => ({required Object low, required Object date, required Object end}) => 'Balance forecast, lowest ${low} on ${date}, month end ${end}',
			'plan.chartPoint' => ({required Object date, required Object amount}) => '${date} · ${amount}',
			'plan.forecastRow' => ({required Object date, required Object amount, required Object low, required Object lowDate}) => 'End ${date} ≈${amount} · lowest ≈${low} (${lowDate})',
			'plan.loadError' => 'Could not load this month.',
			'plan.forecastBadge' => 'FORECAST',
			'plan.startOf' => ({required Object date}) => 'Start ${date}',
			'plan.compactMillion' => ({required Object value}) => '${value}M',
			'plan.compactThousand' => ({required Object value}) => '${value}K',
			'plan.fundingTitle' => 'PREPARE FUNDS',
			'plan.fundingBody' => ({required Object wallet, required Object shortfall, required Object name, required Object date}) => '${wallet} is expected to be short by ≈${shortfall} for ${name} on ${date}. Add funds to ${wallet} before then.',
			'plan.fundingAction' => ({required Object wallet}) => 'See ${wallet} forecast',
			'plan.fundingMore' => ({required Object n}) => '+${n} more',
			'plan.reviewTitle' => ({required Object month}) => '${month} has started',
			'plan.reviewProgress' => ({required Object done, required Object total}) => '${done}/${total}',
			'plan.reviewBudgets' => ({required Object amount}) => 'This month\'s repeating budgets: ${amount}, started automatically.',
			'plan.reviewEstimate' => ({required Object name, required Object amount}) => '${name} ≈${amount}, still right?',
			'plan.reviewLookback' => ({required Object month}) => 'Look back at ${month}',
			'plan.reviewOk' => 'Looks right',
			'plan.reviewEdit' => 'Edit',
			'plan.reviewEditEstimate' => 'Edit estimate',
			'plan.reviewSee' => 'See',
			'plan.reviewDone' => 'Done reviewing',
			'plan.reviewLater' => 'Later',
			'plan.reviewCollapsed' => ({required Object month, required Object done, required Object total}) => 'Review ${month} plan (${done}/${total})',
			'plan.reviewDoneMessage' => ({required Object month}) => '${month} plan is ready.',
			'plan.homeReviewBody' => ({required Object income, required Object committed, required Object free}) => 'Scheduled income ${income}, committed ${committed}, free ${free}.',
			'plan.homeReviewEstimates' => 'Some repeating amounts are estimates worth checking.',
			'plan.homeReviewAction' => 'Review plan',
			'plan.lookbackTitle' => ({required Object month}) => '${month} look back',
			'plan.lookbackPlanned' => 'Plan',
			'plan.lookbackActual' => 'Actual',
			'plan.lookbackFree' => 'Free money',
			'plan.lookbackBiggest' => ({required Object line}) => 'Biggest difference: ${line}.',
			'plan.accuracyExact' => ({required Object month}) => 'The ${month} forecast was spot on.',
			'plan.accuracyMissed' => ({required Object month, required Object amount}) => 'The ${month} forecast was off by ${amount}.',
			'plan.accuracyMissedBy' => ({required Object month, required Object amount, required Object line}) => 'The ${month} forecast was off by ${amount}, mostly from ${line}.',
			'plan.committedShare' => ({required Object percent, required Object month}) => '${percent}% of ${month} income is already committed (repeating + budgets).',
			'plan.committedShareVs' => ({required Object percent, required Object month, required Object previous}) => '${percent}% of ${month} income is already committed (repeating + budgets); the month before, ${previous}%.',
			'plan.installmentFree' => ({required Object name, required Object month, required Object amount}) => 'After ${name} ends, from ${month} you free up +${amount}/mo.',
			_ => null,
		};
	}
}
