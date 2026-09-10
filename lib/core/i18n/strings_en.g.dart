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
			_ => null,
		};
	}
}
