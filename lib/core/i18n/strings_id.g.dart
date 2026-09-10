///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsId = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.id,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <id>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$id app = Translations$app$id.internal(_root);
	late final Translations$common$id common = Translations$common$id.internal(_root);
	late final Translations$cycle$id cycle = Translations$cycle$id.internal(_root);
}

// Path: app
class Translations$app$id {
	Translations$app$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Saldough'
	String get title => 'Saldough';
}

// Path: common
class Translations$common$id {
	Translations$common$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Simpan'
	String get save => 'Simpan';

	/// id: 'Batal'
	String get cancel => 'Batal';

	/// id: 'Hapus'
	String get delete => 'Hapus';

	/// id: 'Sunting'
	String get edit => 'Sunting';

	/// id: 'Tambah'
	String get add => 'Tambah';

	/// id: 'Coba lagi'
	String get retry => 'Coba lagi';

	/// id: 'Memuat...'
	String get loading => 'Memuat...';

	/// id: 'Ada yang salah. Coba lagi.'
	String get genericErrorMessage => 'Ada yang salah. Coba lagi.';

	/// id: 'Hapus?'
	String get confirmDeleteTitle => 'Hapus?';

	/// id: 'Tindakan ini tidak bisa dibatalkan.'
	String get confirmDeleteMessage => 'Tindakan ini tidak bisa dibatalkan.';
}

// Path: cycle
class Translations$cycle$id {
	Translations$cycle$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Pemasukan'
	String get incomeSectionTitle => 'Pemasukan';

	/// id: 'Anggaran'
	String get budgetSectionTitle => 'Anggaran';

	/// id: 'Total'
	String get totalLabel => 'Total';

	/// id: 'Sisa'
	String get remainderLabel => 'Sisa';

	/// id: 'Tambah baris pemasukan'
	String get addIncomeLine => 'Tambah baris pemasukan';

	/// id: 'Tambah baris anggaran'
	String get addBudgetLine => 'Tambah baris anggaran';

	/// id: 'Sunting baris pemasukan'
	String get editIncomeLine => 'Sunting baris pemasukan';

	/// id: 'Sunting baris anggaran'
	String get editBudgetLine => 'Sunting baris anggaran';

	/// id: 'Nama'
	String get labelFieldHint => 'Nama';

	/// id: 'Nominal (Rp)'
	String get amountFieldHint => 'Nominal (Rp)';

	/// id: 'Belum ada baris pemasukan.'
	String get emptyIncome => 'Belum ada baris pemasukan.';

	/// id: 'Belum ada baris anggaran.'
	String get emptyBudget => 'Belum ada baris anggaran.';

	/// id: 'Buat bulan berikutnya'
	String get rollOverButton => 'Buat bulan berikutnya';

	/// id: 'Tutup siklus'
	String get closeCycle => 'Tutup siklus';

	/// id: 'Buka kembali'
	String get reopenCycle => 'Buka kembali';

	/// id: 'Siklus ini sudah ditutup.'
	String get closedBanner => 'Siklus ini sudah ditutup.';

	/// id: 'Siklus sudah ditutup. Buka kembali untuk menyunting.'
	String get closedCannotEdit => 'Siklus sudah ditutup. Buka kembali untuk menyunting.';

	/// id: 'Baris ini dihitung otomatis, tidak bisa disunting langsung.'
	String get rollUpNotEditable => 'Baris ini dihitung otomatis, tidak bisa disunting langsung.';

	/// id: 'Sumber belum tersedia'
	String get rollUpSourceUnavailable => 'Sumber belum tersedia';

	/// id: 'Tandai tetap'
	String get markFixed => 'Tandai tetap';

	/// id: 'Tandai insidental'
	String get markIncidental => 'Tandai insidental';

	/// id: 'Perlu ditinjau'
	String get needsReviewBadge => 'Perlu ditinjau';

	/// id: 'Sudah benar'
	String get confirmReviewed => 'Sudah benar';

	/// id: 'Ada $count baris perlu ditinjau.'
	String unreviewedBanner({required Object count}) => 'Ada ${count} baris perlu ditinjau.';
}

/// The flat map containing all translations for locale <id>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Saldough',
			'common.save' => 'Simpan',
			'common.cancel' => 'Batal',
			'common.delete' => 'Hapus',
			'common.edit' => 'Sunting',
			'common.add' => 'Tambah',
			'common.retry' => 'Coba lagi',
			'common.loading' => 'Memuat...',
			'common.genericErrorMessage' => 'Ada yang salah. Coba lagi.',
			'common.confirmDeleteTitle' => 'Hapus?',
			'common.confirmDeleteMessage' => 'Tindakan ini tidak bisa dibatalkan.',
			'cycle.incomeSectionTitle' => 'Pemasukan',
			'cycle.budgetSectionTitle' => 'Anggaran',
			'cycle.totalLabel' => 'Total',
			'cycle.remainderLabel' => 'Sisa',
			'cycle.addIncomeLine' => 'Tambah baris pemasukan',
			'cycle.addBudgetLine' => 'Tambah baris anggaran',
			'cycle.editIncomeLine' => 'Sunting baris pemasukan',
			'cycle.editBudgetLine' => 'Sunting baris anggaran',
			'cycle.labelFieldHint' => 'Nama',
			'cycle.amountFieldHint' => 'Nominal (Rp)',
			'cycle.emptyIncome' => 'Belum ada baris pemasukan.',
			'cycle.emptyBudget' => 'Belum ada baris anggaran.',
			'cycle.rollOverButton' => 'Buat bulan berikutnya',
			'cycle.closeCycle' => 'Tutup siklus',
			'cycle.reopenCycle' => 'Buka kembali',
			'cycle.closedBanner' => 'Siklus ini sudah ditutup.',
			'cycle.closedCannotEdit' => 'Siklus sudah ditutup. Buka kembali untuk menyunting.',
			'cycle.rollUpNotEditable' => 'Baris ini dihitung otomatis, tidak bisa disunting langsung.',
			'cycle.rollUpSourceUnavailable' => 'Sumber belum tersedia',
			'cycle.markFixed' => 'Tandai tetap',
			'cycle.markIncidental' => 'Tandai insidental',
			'cycle.needsReviewBadge' => 'Perlu ditinjau',
			'cycle.confirmReviewed' => 'Sudah benar',
			'cycle.unreviewedBanner' => ({required Object count}) => 'Ada ${count} baris perlu ditinjau.',
			_ => null,
		};
	}
}
