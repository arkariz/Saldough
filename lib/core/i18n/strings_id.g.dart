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
	late final Translations$income$id income = Translations$income$id.internal(_root);
	late final Translations$worklog$id worklog = Translations$worklog$id.internal(_root);
	late final Translations$card$id card = Translations$card$id.internal(_root);
	late final Translations$grocery$id grocery = Translations$grocery$id.internal(_root);
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

// Path: income
class Translations$income$id {
	Translations$income$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Sumber pemasukan'
	String get pageTitle => 'Sumber pemasukan';

	/// id: 'Belum ada sumber pemasukan.'
	String get emptySources => 'Belum ada sumber pemasukan.';

	/// id: 'Tambah sumber pemasukan'
	String get addSourceTitle => 'Tambah sumber pemasukan';

	/// id: 'Sunting sumber pemasukan'
	String get editSourceTitle => 'Sunting sumber pemasukan';

	/// id: 'Nama'
	String get nameFieldHint => 'Nama';

	/// id: 'Nominal tetap (Rp)'
	String get fixedAmountFieldHint => 'Nominal tetap (Rp)';

	/// id: 'Tarif per jam (Rp)'
	String get hourlyRateFieldHint => 'Tarif per jam (Rp)';

	/// id: '$rate / jam'
	String hourlyRateSubtitle({required Object rate}) => '${rate} / jam';

	/// id: 'Gaji tetap'
	String get kindFixedSalary => 'Gaji tetap';

	/// id: 'Freelance per jam'
	String get kindHourlyFreelance => 'Freelance per jam';

	/// id: 'Sekali jalan'
	String get kindAdHoc => 'Sekali jalan';

	/// id: 'Aturan potongan'
	String get deductionRulesTitle => 'Aturan potongan';

	/// id: 'Tambah potongan'
	String get addDeductionRuleButton => 'Tambah potongan';

	/// id: 'Nama potongan'
	String get deductionLabelHint => 'Nama potongan';

	/// id: 'Nilai'
	String get deductionValueHint => 'Nilai';

	/// id: 'Per mil'
	String get deductionKindPermille => 'Per mil';

	/// id: 'Tetap (Rp)'
	String get deductionKindFixed => 'Tetap (Rp)';
}

// Path: worklog
class Translations$worklog$id {
	Translations$worklog$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Catatan jam kerja'
	String get pageTitle => 'Catatan jam kerja';

	/// id: 'Belum ada sumber pemasukan freelance. Tambah dulu di layar Sumber Pemasukan.'
	String get noFreelanceSource => 'Belum ada sumber pemasukan freelance. Tambah dulu di layar Sumber Pemasukan.';

	/// id: 'Catat jam kerja'
	String get addEntryTitle => 'Catat jam kerja';

	/// id: 'Jumlah jam'
	String get hoursFieldHint => 'Jumlah jam';

	/// id: 'Mulai buku baru'
	String get startsNewBookLabel => 'Mulai buku baru';

	/// id: 'Catat'
	String get addEntryButton => 'Catat';

	/// id: 'Buku berjalan'
	String get openBookTitle => 'Buku berjalan';

	/// id: '$hours jam'
	String totalHours({required Object hours}) => '${hours} jam';

	/// id: 'Tutup buku'
	String get closeBookButton => 'Tutup buku';

	/// id: 'Buku ditutup. Gaji bersih $netPay.'
	String bookClosedMessage({required Object netPay}) => 'Buku ditutup. Gaji bersih ${netPay}.';

	/// id: 'Riwayat buku'
	String get historyTitle => 'Riwayat buku';

	/// id: 'Belum ada buku yang ditutup.'
	String get emptyHistory => 'Belum ada buku yang ditutup.';

	/// id: 'Siklus tujuan (YYYY-MM)'
	String get targetCycleHint => 'Siklus tujuan (YYYY-MM)';

	/// id: 'Suntik ke siklus'
	String get injectButton => 'Suntik ke siklus';

	/// id: 'Disuntikkan ke siklus $cycleId.'
	String injectedMessage({required Object cycleId}) => 'Disuntikkan ke siklus ${cycleId}.';

	/// id: 'Disuntikkan ke siklus $cycleId.'
	String injectedInto({required Object cycleId}) => 'Disuntikkan ke siklus ${cycleId}.';
}

// Path: card
class Translations$card$id {
	Translations$card$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Kartu kredit'
	String get pageTitle => 'Kartu kredit';

	/// id: 'Kartu'
	String get cardsTitle => 'Kartu';

	/// id: 'Belum ada kartu terdaftar.'
	String get emptyCards => 'Belum ada kartu terdaftar.';

	/// id: 'Tambah kartu'
	String get addCardTitle => 'Tambah kartu';

	/// id: 'Sunting kartu'
	String get editCardTitle => 'Sunting kartu';

	/// id: 'Nama kartu'
	String get cardNameFieldHint => 'Nama kartu';

	/// id: 'Tanggal cetak tagihan'
	String get statementDayFieldHint => 'Tanggal cetak tagihan';

	/// id: 'Cetak tanggal $day'
	String statementDaySubtitle({required Object day}) => 'Cetak tanggal ${day}';

	/// id: 'Siklus tagihan berjalan'
	String get openStatementTitle => 'Siklus tagihan berjalan';

	/// id: 'Perlu dikonfirmasi'
	String get pendingConfirmationTitle => 'Perlu dikonfirmasi';

	/// id: 'Tutup siklus tagihan'
	String get closeStatementButton => 'Tutup siklus tagihan';

	/// id: 'Siklus tagihan ditutup. Siklus berikutnya dibuka.'
	String get statementClosedMessage => 'Siklus tagihan ditutup. Siklus berikutnya dibuka.';

	/// id: 'Catat transaksi'
	String get addTransactionTitle => 'Catat transaksi';

	/// id: 'Merchant'
	String get merchantFieldHint => 'Merchant';

	/// id: 'Nominal (Rp)'
	String get amountFieldHint => 'Nominal (Rp)';

	/// id: 'Catatan (opsional)'
	String get noteFieldHint => 'Catatan (opsional)';

	/// id: 'Catat'
	String get addTransactionButton => 'Catat';

	/// id: 'Langganan berulang'
	String get subscriptionsTitle => 'Langganan berulang';

	/// id: 'Belum ada langganan terdaftar.'
	String get emptySubscriptions => 'Belum ada langganan terdaftar.';

	/// id: 'Tambah langganan'
	String get addSubscriptionTitle => 'Tambah langganan';

	/// id: 'Sunting langganan'
	String get editSubscriptionTitle => 'Sunting langganan';

	/// id: 'Tanggal disiapkan tiap bulan'
	String get subscriptionDayFieldHint => 'Tanggal disiapkan tiap bulan';

	/// id: 'Aktif'
	String get subscriptionActiveLabel => 'Aktif';

	/// id: '$amount / bulan, tanggal $day'
	String subscriptionSubtitle({required Object amount, required Object day}) => '${amount} / bulan, tanggal ${day}';

	/// id: 'Nonaktif'
	String get subscriptionInactiveBadge => 'Nonaktif';

	/// id: 'Riwayat siklus tagihan'
	String get historyTitle => 'Riwayat siklus tagihan';

	/// id: 'Belum ada siklus tagihan yang ditutup.'
	String get emptyHistory => 'Belum ada siklus tagihan yang ditutup.';

	/// id: '$start – $end'
	String statementPeriodLabel({required Object start, required Object end}) => '${start} – ${end}';
}

// Path: grocery
class Translations$grocery$id {
	Translations$grocery$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Rencana belanja'
	String get pageTitle => 'Rencana belanja';

	/// id: 'Total bulanan'
	String get rollUpTotal => 'Total bulanan';

	/// id: 'Pengali minggu per bulan'
	String get weeksPerMonthFieldHint => 'Pengali minggu per bulan';

	/// id: 'Daftar mingguan'
	String get weeklyTitle => 'Daftar mingguan';

	/// id: 'Daftar bulanan'
	String get monthlyTitle => 'Daftar bulanan';

	/// id: 'Belum ada bahan.'
	String get emptyItems => 'Belum ada bahan.';

	/// id: 'Tambah bahan'
	String get addItemButton => 'Tambah bahan';

	/// id: 'Sunting bahan'
	String get editItemTitle => 'Sunting bahan';

	/// id: 'Nama bahan'
	String get itemNameFieldHint => 'Nama bahan';

	/// id: 'Jumlah'
	String get quantityFieldHint => 'Jumlah';

	/// id: 'Harga satuan (Rp)'
	String get unitPriceFieldHint => 'Harga satuan (Rp)';

	/// id: 'Timpa harga'
	String get overridePriceLabel => 'Timpa harga';

	/// id: 'Harga timpaan (Rp)'
	String get overrideAmountFieldHint => 'Harga timpaan (Rp)';

	/// id: 'ditimpa'
	String get overriddenBadge => 'ditimpa';
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
			'income.pageTitle' => 'Sumber pemasukan',
			'income.emptySources' => 'Belum ada sumber pemasukan.',
			'income.addSourceTitle' => 'Tambah sumber pemasukan',
			'income.editSourceTitle' => 'Sunting sumber pemasukan',
			'income.nameFieldHint' => 'Nama',
			'income.fixedAmountFieldHint' => 'Nominal tetap (Rp)',
			'income.hourlyRateFieldHint' => 'Tarif per jam (Rp)',
			'income.hourlyRateSubtitle' => ({required Object rate}) => '${rate} / jam',
			'income.kindFixedSalary' => 'Gaji tetap',
			'income.kindHourlyFreelance' => 'Freelance per jam',
			'income.kindAdHoc' => 'Sekali jalan',
			'income.deductionRulesTitle' => 'Aturan potongan',
			'income.addDeductionRuleButton' => 'Tambah potongan',
			'income.deductionLabelHint' => 'Nama potongan',
			'income.deductionValueHint' => 'Nilai',
			'income.deductionKindPermille' => 'Per mil',
			'income.deductionKindFixed' => 'Tetap (Rp)',
			'worklog.pageTitle' => 'Catatan jam kerja',
			'worklog.noFreelanceSource' => 'Belum ada sumber pemasukan freelance. Tambah dulu di layar Sumber Pemasukan.',
			'worklog.addEntryTitle' => 'Catat jam kerja',
			'worklog.hoursFieldHint' => 'Jumlah jam',
			'worklog.startsNewBookLabel' => 'Mulai buku baru',
			'worklog.addEntryButton' => 'Catat',
			'worklog.openBookTitle' => 'Buku berjalan',
			'worklog.totalHours' => ({required Object hours}) => '${hours} jam',
			'worklog.closeBookButton' => 'Tutup buku',
			'worklog.bookClosedMessage' => ({required Object netPay}) => 'Buku ditutup. Gaji bersih ${netPay}.',
			'worklog.historyTitle' => 'Riwayat buku',
			'worklog.emptyHistory' => 'Belum ada buku yang ditutup.',
			'worklog.targetCycleHint' => 'Siklus tujuan (YYYY-MM)',
			'worklog.injectButton' => 'Suntik ke siklus',
			'worklog.injectedMessage' => ({required Object cycleId}) => 'Disuntikkan ke siklus ${cycleId}.',
			'worklog.injectedInto' => ({required Object cycleId}) => 'Disuntikkan ke siklus ${cycleId}.',
			'card.pageTitle' => 'Kartu kredit',
			'card.cardsTitle' => 'Kartu',
			'card.emptyCards' => 'Belum ada kartu terdaftar.',
			'card.addCardTitle' => 'Tambah kartu',
			'card.editCardTitle' => 'Sunting kartu',
			'card.cardNameFieldHint' => 'Nama kartu',
			'card.statementDayFieldHint' => 'Tanggal cetak tagihan',
			'card.statementDaySubtitle' => ({required Object day}) => 'Cetak tanggal ${day}',
			'card.openStatementTitle' => 'Siklus tagihan berjalan',
			'card.pendingConfirmationTitle' => 'Perlu dikonfirmasi',
			'card.closeStatementButton' => 'Tutup siklus tagihan',
			'card.statementClosedMessage' => 'Siklus tagihan ditutup. Siklus berikutnya dibuka.',
			'card.addTransactionTitle' => 'Catat transaksi',
			'card.merchantFieldHint' => 'Merchant',
			'card.amountFieldHint' => 'Nominal (Rp)',
			'card.noteFieldHint' => 'Catatan (opsional)',
			'card.addTransactionButton' => 'Catat',
			'card.subscriptionsTitle' => 'Langganan berulang',
			'card.emptySubscriptions' => 'Belum ada langganan terdaftar.',
			'card.addSubscriptionTitle' => 'Tambah langganan',
			'card.editSubscriptionTitle' => 'Sunting langganan',
			'card.subscriptionDayFieldHint' => 'Tanggal disiapkan tiap bulan',
			'card.subscriptionActiveLabel' => 'Aktif',
			'card.subscriptionSubtitle' => ({required Object amount, required Object day}) => '${amount} / bulan, tanggal ${day}',
			'card.subscriptionInactiveBadge' => 'Nonaktif',
			'card.historyTitle' => 'Riwayat siklus tagihan',
			'card.emptyHistory' => 'Belum ada siklus tagihan yang ditutup.',
			'card.statementPeriodLabel' => ({required Object start, required Object end}) => '${start} – ${end}',
			'grocery.pageTitle' => 'Rencana belanja',
			'grocery.rollUpTotal' => 'Total bulanan',
			'grocery.weeksPerMonthFieldHint' => 'Pengali minggu per bulan',
			'grocery.weeklyTitle' => 'Daftar mingguan',
			'grocery.monthlyTitle' => 'Daftar bulanan',
			'grocery.emptyItems' => 'Belum ada bahan.',
			'grocery.addItemButton' => 'Tambah bahan',
			'grocery.editItemTitle' => 'Sunting bahan',
			'grocery.itemNameFieldHint' => 'Nama bahan',
			'grocery.quantityFieldHint' => 'Jumlah',
			'grocery.unitPriceFieldHint' => 'Harga satuan (Rp)',
			'grocery.overridePriceLabel' => 'Timpa harga',
			'grocery.overrideAmountFieldHint' => 'Harga timpaan (Rp)',
			'grocery.overriddenBadge' => 'ditimpa',
			_ => null,
		};
	}
}
