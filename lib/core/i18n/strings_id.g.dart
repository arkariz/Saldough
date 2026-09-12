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
	late final Translations$investment$id investment = Translations$investment$id.internal(_root);
	late final Translations$shell$id shell = Translations$shell$id.internal(_root);
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

	/// id: 'Ganti nama baris'
	String get renameRollUpLineTitle => 'Ganti nama baris';

	/// id: 'Nama'
	String get labelFieldHint => 'Nama';

	/// id: 'Nominal (Rp)'
	String get amountFieldHint => 'Nominal (Rp)';

	/// id: 'Belum ada baris pemasukan. Tambahkan yang pertama di bawah.'
	String get emptyIncome => 'Belum ada baris pemasukan. Tambahkan yang pertama di bawah.';

	/// id: 'Belum ada baris anggaran. Tambahkan yang pertama di bawah.'
	String get emptyBudget => 'Belum ada baris anggaran. Tambahkan yang pertama di bawah.';

	/// id: 'Buat bulan berikutnya'
	String get rollOverButton => 'Buat bulan berikutnya';

	/// id: 'Siklus $month sudah dibuat.'
	String cycleCreatedMessage({required Object month}) => 'Siklus ${month} sudah dibuat.';

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

	/// id: 'Kartu sumbernya belum terdaftar. Tambah dulu di Belanja › Kartu Kredit.'
	String get rollUpSourceUnavailableCard => 'Kartu sumbernya belum terdaftar. Tambah dulu di Belanja › Kartu Kredit.';

	/// id: 'Rencana belanja masih kosong. Isi dulu di tab Belanja.'
	String get rollUpSourceUnavailableGrocery => 'Rencana belanja masih kosong. Isi dulu di tab Belanja.';

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

	/// id: 'Nominalnya masih ikut bulan lalu — periksa sebelum ditandai benar.'
	String get unreviewedBannerHint => 'Nominalnya masih ikut bulan lalu — periksa sebelum ditandai benar.';

	/// id: 'Hapus siklus ini'
	String get deleteCycle => 'Hapus siklus ini';

	/// id: 'Hapus siklus $month?'
	String confirmDeleteCycleTitle({required Object month}) => 'Hapus siklus ${month}?';

	/// id: 'Seluruh baris pemasukan dan anggaran bulan ini akan terhapus. Tindakan ini tidak bisa dibatalkan.'
	String get deleteCycleConfirmMessage => 'Seluruh baris pemasukan dan anggaran bulan ini akan terhapus. Tindakan ini tidak bisa dibatalkan.';

	/// id: 'Belum ada sumber pemasukan. Nominal bisa diisi manual, atau tambah sumber dulu supaya nominalnya ikut otomatis dari jam kerja atau gaji tetap.'
	String get noIncomeSourcesHint => 'Belum ada sumber pemasukan. Nominal bisa diisi manual, atau tambah sumber dulu supaya nominalnya ikut otomatis dari jam kerja atau gaji tetap.';

	/// id: 'Tambah sumber pemasukan'
	String get addIncomeSourceButton => 'Tambah sumber pemasukan';

	/// id: 'Sumber nominal'
	String get budgetSourceFieldLabel => 'Sumber nominal';

	/// id: 'Manual'
	String get budgetSourceManual => 'Manual';

	/// id: 'Rencana belanja'
	String get budgetSourceGrocery => 'Rencana belanja';

	/// id: 'Kartu kredit'
	String get budgetSourceCard => 'Kartu kredit';

	/// id: 'Pilih kartu'
	String get selectCardHint => 'Pilih kartu';

	/// id: 'Sumber ini sudah ditautkan ke baris anggaran lain.'
	String get rollUpSourceAlreadyUsed => 'Sumber ini sudah ditautkan ke baris anggaran lain.';

	/// id: 'Hapus baris $name?'
	String confirmDeleteIncomeLineTitle({required Object name}) => 'Hapus baris ${name}?';

	/// id: 'Hapus baris $name?'
	String confirmDeleteBudgetLineTitle({required Object name}) => 'Hapus baris ${name}?';

	/// id: 'Baris ini akan terhapus dari siklus bulan ini. Tindakan ini tidak bisa dibatalkan.'
	String get confirmDeleteLineMessage => 'Baris ini akan terhapus dari siklus bulan ini. Tindakan ini tidak bisa dibatalkan.';

	/// id: 'Belum ada kartu terdaftar. Tambah dulu di Belanja › Kartu Kredit.'
	String get noCardsHint => 'Belum ada kartu terdaftar. Tambah dulu di Belanja › Kartu Kredit.';

	/// id: 'Semua kartu sudah ditautkan ke baris anggaran lain.'
	String get allCardsUsedHint => 'Semua kartu sudah ditautkan ke baris anggaran lain.';
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

	/// id: 'Catat Jam Kerja'
	String get worklogEntryPointLabel => 'Catat Jam Kerja';

	/// id: 'Belum ada buku berjalan.'
	String get noOpenBook => 'Belum ada buku berjalan.';

	/// id: 'Buku berjalan: $hours jam.'
	String openBookSummary({required Object hours}) => 'Buku berjalan: ${hours} jam.';

	/// id: 'Catat jam'
	String get logHoursButton => 'Catat jam';

	/// id: 'Hapus sumber $name?'
	String confirmDeleteSourceTitle({required Object name}) => 'Hapus sumber ${name}?';

	/// id: 'Baris pemasukan di siklus mana pun yang menaut sumber ini tidak lagi ikut berubah saat sumbernya disunting. Nominal yang sudah tercatat tidak terhapus. Tindakan ini tidak bisa dibatalkan.'
	String get confirmDeleteSourceMessage => 'Baris pemasukan di siklus mana pun yang menaut sumber ini tidak lagi ikut berubah saat sumbernya disunting. Nominal yang sudah tercatat tidak terhapus. Tindakan ini tidak bisa dibatalkan.';
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

	/// id: 'Buka Sumber Pemasukan'
	String get goToIncomeSourcesButton => 'Buka Sumber Pemasukan';

	/// id: 'Catat jam kerja'
	String get addEntryTitle => 'Catat jam kerja';

	/// id: 'Jumlah jam'
	String get hoursFieldHint => 'Jumlah jam';

	/// id: 'Catat'
	String get addEntryButton => 'Catat';

	/// id: 'Buku berjalan'
	String get openBookTitle => 'Buku berjalan';

	/// id: 'Sejak $date'
	String openSince({required Object date}) => 'Sejak ${date}';

	/// id: 'Ubah jumlah jam'
	String get editEntryTitle => 'Ubah jumlah jam';

	/// id: 'Hapus entri ini?'
	String get confirmDeleteEntryTitle => 'Hapus entri ini?';

	/// id: 'Entri jam kerja ini akan dihapus dari buku yang sedang berjalan. Total jam dan perkiraan gaji ikut berubah. Tindakan ini tidak bisa dibatalkan.'
	String get confirmDeleteEntryMessage => 'Entri jam kerja ini akan dihapus dari buku yang sedang berjalan. Total jam dan perkiraan gaji ikut berubah. Tindakan ini tidak bisa dibatalkan.';

	/// id: '$hours jam'
	String totalHours({required Object hours}) => '${hours} jam';

	/// id: 'Tutup buku'
	String get closeBookButton => 'Tutup buku';

	/// id: 'Buku ditutup'
	String get bookClosedTitle => 'Buku ditutup';

	/// id: 'Perkiraan gaji (bisa berubah sebelum buku ditutup)'
	String get estimateLabel => 'Perkiraan gaji (bisa berubah sebelum buku ditutup)';

	/// id: 'Rincian gaji'
	String get breakdownTitle => 'Rincian gaji';

	/// id: 'Gaji kotor'
	String get grossPayLabel => 'Gaji kotor';

	/// id: 'Gaji bersih'
	String get netPayLabel => 'Gaji bersih';

	/// id: 'Riwayat buku'
	String get historyTitle => 'Riwayat buku';

	/// id: 'Belum ada buku yang ditutup.'
	String get emptyHistory => 'Belum ada buku yang ditutup.';

	/// id: 'Sudah disuntik'
	String get injectedBadge => 'Sudah disuntik';

	/// id: 'Belum disuntik'
	String get notInjectedBadge => 'Belum disuntik';

	/// id: 'Nanti saja'
	String get injectLaterButton => 'Nanti saja';

	/// id: 'Siklus tujuan'
	String get targetCycleHint => 'Siklus tujuan';

	/// id: 'Belum ada siklus yang bisa dipilih. Buat siklus dulu di tab Siklus.'
	String get noCyclesForInject => 'Belum ada siklus yang bisa dipilih. Buat siklus dulu di tab Siklus.';

	/// id: 'Suntik ke siklus'
	String get injectButton => 'Suntik ke siklus';

	/// id: 'Disuntikkan ke siklus $cycleId.'
	String injectedMessage({required Object cycleId}) => 'Disuntikkan ke siklus ${cycleId}.';

	/// id: 'Disuntikkan ke siklus $cycleId.'
	String injectedInto({required Object cycleId}) => 'Disuntikkan ke siklus ${cycleId}.';

	/// id: 'Timpa nominal yang sudah disuntik?'
	String get overwriteWarningTitle => 'Timpa nominal yang sudah disuntik?';

	/// id: 'Siklus $cycleId sudah menerima suntikan sebesar $amount dari buku lain milik sumber ini. Menyuntik buku ini akan MENIMPA nominal itu, bukan menjumlahkannya.'
	String overwriteWarningMessage({required Object cycleId, required Object amount}) => 'Siklus ${cycleId} sudah menerima suntikan sebesar ${amount} dari buku lain milik sumber ini. Menyuntik buku ini akan MENIMPA nominal itu, bukan menjumlahkannya.';

	/// id: 'Timpa'
	String get overwriteConfirmButton => 'Timpa';
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

	/// id: 'Siklus tagihan berjalan — $cardName'
	String openStatementTitleFor({required Object cardName}) => 'Siklus tagihan berjalan — ${cardName}';

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

	/// id: 'Langganan berulang — $cardName'
	String subscriptionsTitleFor({required Object cardName}) => 'Langganan berulang — ${cardName}';

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

	/// id: 'Riwayat siklus tagihan — $cardName'
	String historyTitleFor({required Object cardName}) => 'Riwayat siklus tagihan — ${cardName}';

	/// id: 'Belum ada siklus tagihan yang ditutup.'
	String get emptyHistory => 'Belum ada siklus tagihan yang ditutup.';

	/// id: '$start – $end'
	String statementPeriodLabel({required Object start, required Object end}) => '${start} – ${end}';

	/// id: 'Hapus kartu $name?'
	String confirmDeleteCardTitle({required Object name}) => 'Hapus kartu ${name}?';

	/// id: 'Seluruh siklus tagihan dan transaksi kartu ini akan terhapus. Baris anggaran yang menaut kartu ini akan kehilangan sumbernya. Tindakan ini tidak bisa dibatalkan.'
	String get confirmDeleteCardMessage => 'Seluruh siklus tagihan dan transaksi kartu ini akan terhapus. Baris anggaran yang menaut kartu ini akan kehilangan sumbernya. Tindakan ini tidak bisa dibatalkan.';

	/// id: 'Hapus langganan $name?'
	String confirmDeleteSubscriptionTitle({required Object name}) => 'Hapus langganan ${name}?';

	/// id: 'Langganan ini tidak lagi disiapkan otomatis tiap siklus tagihan. Transaksi yang sudah tercatat tidak terpengaruh. Tindakan ini tidak bisa dibatalkan.'
	String get confirmDeleteSubscriptionMessage => 'Langganan ini tidak lagi disiapkan otomatis tiap siklus tagihan. Transaksi yang sudah tercatat tidak terpengaruh. Tindakan ini tidak bisa dibatalkan.';
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

	/// id: 'Bulan'
	String get cycleIdFieldHint => 'Bulan';

	/// id: 'Hapus $name?'
	String confirmDeleteItemTitle({required Object name}) => 'Hapus ${name}?';

	/// id: 'Total bulanan rencana belanja akan berubah, dan baris anggaran yang menautnya ikut menyesuaikan. Tindakan ini tidak bisa dibatalkan.'
	String get confirmDeleteItemMessage => 'Total bulanan rencana belanja akan berubah, dan baris anggaran yang menautnya ikut menyesuaikan. Tindakan ini tidak bisa dibatalkan.';
}

// Path: investment
class Translations$investment$id {
	Translations$investment$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Investasi'
	String get pageTitle => 'Investasi';

	/// id: 'Total portofolio'
	String get totalPortfolioTitle => 'Total portofolio';

	/// id: 'Pos tujuan'
	String get goalsTitle => 'Pos tujuan';

	/// id: 'Belum ada pos tujuan.'
	String get emptyGoals => 'Belum ada pos tujuan.';

	/// id: 'Tambah pos'
	String get addGoalTitle => 'Tambah pos';

	/// id: 'Sunting pos'
	String get editGoalTitle => 'Sunting pos';

	/// id: 'Nama pos'
	String get goalNameFieldHint => 'Nama pos';

	/// id: 'Saldo awal (Rp)'
	String get openingBalanceFieldHint => 'Saldo awal (Rp)';

	/// id: 'Alokasi bulan ini'
	String get allocationPlanTitle => 'Alokasi bulan ini';

	/// id: 'Siklus'
	String get cycleIdFieldHint => 'Siklus';

	/// id: 'Belum ada siklus yang bisa dipilih. Buat siklus dulu di tab Siklus.'
	String get noCyclesAvailable => 'Belum ada siklus yang bisa dipilih. Buat siklus dulu di tab Siklus.';

	/// id: 'Siklus ini belum ada.'
	String get cycleNotFound => 'Siklus ini belum ada.';

	/// id: 'Siklus ini sudah ditutup. Buka kembali untuk menyunting alokasi.'
	String get cycleClosedMessage => 'Siklus ini sudah ditutup. Buka kembali untuk menyunting alokasi.';

	/// id: 'Sisa siklus'
	String get remainderLabel => 'Sisa siklus';

	/// id: 'Tambahan dana (Rp)'
	String get returnDepositFieldHint => 'Tambahan dana (Rp)';

	/// id: '%'
	String get percentageFieldHint => '%';

	/// id: 'Total persentase: $total%'
	String totalPercentageLabel({required Object total}) => 'Total persentase: ${total}%';

	/// id: 'Pinjaman antar pos'
	String get loansTitle => 'Pinjaman antar pos';

	/// id: 'Belum ada pinjaman.'
	String get emptyLoans => 'Belum ada pinjaman.';

	/// id: 'Tambah pinjaman'
	String get addLoanTitle => 'Tambah pinjaman';

	/// id: 'Sunting pinjaman'
	String get editLoanTitle => 'Sunting pinjaman';

	/// id: 'Dari pos'
	String get fromGoalFieldHint => 'Dari pos';

	/// id: 'Ke pos'
	String get toGoalFieldHint => 'Ke pos';

	/// id: 'Pokok (Rp)'
	String get principalFieldHint => 'Pokok (Rp)';

	/// id: 'Dikembalikan (Rp)'
	String get repaidFieldHint => 'Dikembalikan (Rp)';

	/// id: 'Catatan (opsional)'
	String get noteFieldHint => 'Catatan (opsional)';

	/// id: 'Riwayat'
	String get historyTitle => 'Riwayat';

	/// id: 'Alokasi siklus $cycleId'
	String allocationHistoryLabel({required Object cycleId}) => 'Alokasi siklus ${cycleId}';

	/// id: 'Pinjaman dari $fromName'
	String loanInLabel({required Object fromName}) => 'Pinjaman dari ${fromName}';

	/// id: 'Pinjaman ke $toName'
	String loanOutLabel({required Object toName}) => 'Pinjaman ke ${toName}';

	/// id: '$fromName → $toName'
	String loanRouteLabel({required Object fromName, required Object toName}) => '${fromName} → ${toName}';

	/// id: 'Pokok $principal, dikembalikan $repaid'
	String loanAmountsLabel({required Object principal, required Object repaid}) => 'Pokok ${principal}, dikembalikan ${repaid}';

	/// id: 'Total persentase harus 0 atau 100.'
	String get invalidTotalMessage => 'Total persentase harus 0 atau 100.';

	/// id: 'Rencana alokasi disimpan.'
	String get allocationSavedMessage => 'Rencana alokasi disimpan.';

	/// id: 'Pinjaman disimpan.'
	String get loanSavedMessage => 'Pinjaman disimpan.';

	/// id: 'Hapus pos $name?'
	String confirmDeleteGoalTitle({required Object name}) => 'Hapus pos ${name}?';

	/// id: 'Saldo pos dan seluruh riwayat alokasinya akan terhapus. Tindakan ini tidak bisa dibatalkan.'
	String get confirmDeleteGoalMessage => 'Saldo pos dan seluruh riwayat alokasinya akan terhapus. Tindakan ini tidak bisa dibatalkan.';

	/// id: 'Hapus pinjaman ini?'
	String get confirmDeleteLoanTitle => 'Hapus pinjaman ini?';

	/// id: 'Catatan pokok dan pengembaliannya akan terhapus, dan saldo kedua pos ikut berubah. Tindakan ini tidak bisa dibatalkan.'
	String get confirmDeleteLoanMessage => 'Catatan pokok dan pengembaliannya akan terhapus, dan saldo kedua pos ikut berubah. Tindakan ini tidak bisa dibatalkan.';
}

// Path: shell
class Translations$shell$id {
	Translations$shell$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Siklus'
	String get cycleTabLabel => 'Siklus';

	/// id: 'Pemasukan'
	String get incomeTabLabel => 'Pemasukan';

	/// id: 'Belanja'
	String get groceryTabLabel => 'Belanja';

	/// id: 'Investasi'
	String get investmentTabLabel => 'Investasi';
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
			'cycle.incomeSectionTitle' => 'Pemasukan',
			'cycle.budgetSectionTitle' => 'Anggaran',
			'cycle.totalLabel' => 'Total',
			'cycle.remainderLabel' => 'Sisa',
			'cycle.addIncomeLine' => 'Tambah baris pemasukan',
			'cycle.addBudgetLine' => 'Tambah baris anggaran',
			'cycle.editIncomeLine' => 'Sunting baris pemasukan',
			'cycle.editBudgetLine' => 'Sunting baris anggaran',
			'cycle.renameRollUpLineTitle' => 'Ganti nama baris',
			'cycle.labelFieldHint' => 'Nama',
			'cycle.amountFieldHint' => 'Nominal (Rp)',
			'cycle.emptyIncome' => 'Belum ada baris pemasukan. Tambahkan yang pertama di bawah.',
			'cycle.emptyBudget' => 'Belum ada baris anggaran. Tambahkan yang pertama di bawah.',
			'cycle.rollOverButton' => 'Buat bulan berikutnya',
			'cycle.cycleCreatedMessage' => ({required Object month}) => 'Siklus ${month} sudah dibuat.',
			'cycle.closeCycle' => 'Tutup siklus',
			'cycle.reopenCycle' => 'Buka kembali',
			'cycle.closedBanner' => 'Siklus ini sudah ditutup.',
			'cycle.closedCannotEdit' => 'Siklus sudah ditutup. Buka kembali untuk menyunting.',
			'cycle.rollUpNotEditable' => 'Baris ini dihitung otomatis, tidak bisa disunting langsung.',
			'cycle.rollUpSourceUnavailableCard' => 'Kartu sumbernya belum terdaftar. Tambah dulu di Belanja › Kartu Kredit.',
			'cycle.rollUpSourceUnavailableGrocery' => 'Rencana belanja masih kosong. Isi dulu di tab Belanja.',
			'cycle.markFixed' => 'Tandai tetap',
			'cycle.markIncidental' => 'Tandai insidental',
			'cycle.needsReviewBadge' => 'Perlu ditinjau',
			'cycle.confirmReviewed' => 'Sudah benar',
			'cycle.unreviewedBanner' => ({required Object count}) => 'Ada ${count} baris perlu ditinjau.',
			'cycle.unreviewedBannerHint' => 'Nominalnya masih ikut bulan lalu — periksa sebelum ditandai benar.',
			'cycle.deleteCycle' => 'Hapus siklus ini',
			'cycle.confirmDeleteCycleTitle' => ({required Object month}) => 'Hapus siklus ${month}?',
			'cycle.deleteCycleConfirmMessage' => 'Seluruh baris pemasukan dan anggaran bulan ini akan terhapus. Tindakan ini tidak bisa dibatalkan.',
			'cycle.noIncomeSourcesHint' => 'Belum ada sumber pemasukan. Nominal bisa diisi manual, atau tambah sumber dulu supaya nominalnya ikut otomatis dari jam kerja atau gaji tetap.',
			'cycle.addIncomeSourceButton' => 'Tambah sumber pemasukan',
			'cycle.budgetSourceFieldLabel' => 'Sumber nominal',
			'cycle.budgetSourceManual' => 'Manual',
			'cycle.budgetSourceGrocery' => 'Rencana belanja',
			'cycle.budgetSourceCard' => 'Kartu kredit',
			'cycle.selectCardHint' => 'Pilih kartu',
			'cycle.rollUpSourceAlreadyUsed' => 'Sumber ini sudah ditautkan ke baris anggaran lain.',
			'cycle.confirmDeleteIncomeLineTitle' => ({required Object name}) => 'Hapus baris ${name}?',
			'cycle.confirmDeleteBudgetLineTitle' => ({required Object name}) => 'Hapus baris ${name}?',
			'cycle.confirmDeleteLineMessage' => 'Baris ini akan terhapus dari siklus bulan ini. Tindakan ini tidak bisa dibatalkan.',
			'cycle.noCardsHint' => 'Belum ada kartu terdaftar. Tambah dulu di Belanja › Kartu Kredit.',
			'cycle.allCardsUsedHint' => 'Semua kartu sudah ditautkan ke baris anggaran lain.',
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
			'income.worklogEntryPointLabel' => 'Catat Jam Kerja',
			'income.noOpenBook' => 'Belum ada buku berjalan.',
			'income.openBookSummary' => ({required Object hours}) => 'Buku berjalan: ${hours} jam.',
			'income.logHoursButton' => 'Catat jam',
			'income.confirmDeleteSourceTitle' => ({required Object name}) => 'Hapus sumber ${name}?',
			'income.confirmDeleteSourceMessage' => 'Baris pemasukan di siklus mana pun yang menaut sumber ini tidak lagi ikut berubah saat sumbernya disunting. Nominal yang sudah tercatat tidak terhapus. Tindakan ini tidak bisa dibatalkan.',
			'worklog.pageTitle' => 'Catatan jam kerja',
			'worklog.noFreelanceSource' => 'Belum ada sumber pemasukan freelance. Tambah dulu di layar Sumber Pemasukan.',
			'worklog.goToIncomeSourcesButton' => 'Buka Sumber Pemasukan',
			'worklog.addEntryTitle' => 'Catat jam kerja',
			'worklog.hoursFieldHint' => 'Jumlah jam',
			'worklog.addEntryButton' => 'Catat',
			'worklog.openBookTitle' => 'Buku berjalan',
			'worklog.openSince' => ({required Object date}) => 'Sejak ${date}',
			'worklog.editEntryTitle' => 'Ubah jumlah jam',
			'worklog.confirmDeleteEntryTitle' => 'Hapus entri ini?',
			'worklog.confirmDeleteEntryMessage' => 'Entri jam kerja ini akan dihapus dari buku yang sedang berjalan. Total jam dan perkiraan gaji ikut berubah. Tindakan ini tidak bisa dibatalkan.',
			'worklog.totalHours' => ({required Object hours}) => '${hours} jam',
			'worklog.closeBookButton' => 'Tutup buku',
			'worklog.bookClosedTitle' => 'Buku ditutup',
			'worklog.estimateLabel' => 'Perkiraan gaji (bisa berubah sebelum buku ditutup)',
			'worklog.breakdownTitle' => 'Rincian gaji',
			'worklog.grossPayLabel' => 'Gaji kotor',
			'worklog.netPayLabel' => 'Gaji bersih',
			'worklog.historyTitle' => 'Riwayat buku',
			'worklog.emptyHistory' => 'Belum ada buku yang ditutup.',
			'worklog.injectedBadge' => 'Sudah disuntik',
			'worklog.notInjectedBadge' => 'Belum disuntik',
			'worklog.injectLaterButton' => 'Nanti saja',
			'worklog.targetCycleHint' => 'Siklus tujuan',
			'worklog.noCyclesForInject' => 'Belum ada siklus yang bisa dipilih. Buat siklus dulu di tab Siklus.',
			'worklog.injectButton' => 'Suntik ke siklus',
			'worklog.injectedMessage' => ({required Object cycleId}) => 'Disuntikkan ke siklus ${cycleId}.',
			'worklog.injectedInto' => ({required Object cycleId}) => 'Disuntikkan ke siklus ${cycleId}.',
			'worklog.overwriteWarningTitle' => 'Timpa nominal yang sudah disuntik?',
			'worklog.overwriteWarningMessage' => ({required Object cycleId, required Object amount}) => 'Siklus ${cycleId} sudah menerima suntikan sebesar ${amount} dari buku lain milik sumber ini. Menyuntik buku ini akan MENIMPA nominal itu, bukan menjumlahkannya.',
			'worklog.overwriteConfirmButton' => 'Timpa',
			'card.pageTitle' => 'Kartu kredit',
			'card.cardsTitle' => 'Kartu',
			'card.emptyCards' => 'Belum ada kartu terdaftar.',
			'card.addCardTitle' => 'Tambah kartu',
			'card.editCardTitle' => 'Sunting kartu',
			'card.cardNameFieldHint' => 'Nama kartu',
			'card.statementDayFieldHint' => 'Tanggal cetak tagihan',
			'card.statementDaySubtitle' => ({required Object day}) => 'Cetak tanggal ${day}',
			'card.openStatementTitleFor' => ({required Object cardName}) => 'Siklus tagihan berjalan — ${cardName}',
			'card.pendingConfirmationTitle' => 'Perlu dikonfirmasi',
			'card.closeStatementButton' => 'Tutup siklus tagihan',
			'card.statementClosedMessage' => 'Siklus tagihan ditutup. Siklus berikutnya dibuka.',
			'card.addTransactionTitle' => 'Catat transaksi',
			'card.merchantFieldHint' => 'Merchant',
			'card.amountFieldHint' => 'Nominal (Rp)',
			'card.noteFieldHint' => 'Catatan (opsional)',
			'card.addTransactionButton' => 'Catat',
			'card.subscriptionsTitleFor' => ({required Object cardName}) => 'Langganan berulang — ${cardName}',
			'card.emptySubscriptions' => 'Belum ada langganan terdaftar.',
			'card.addSubscriptionTitle' => 'Tambah langganan',
			'card.editSubscriptionTitle' => 'Sunting langganan',
			'card.subscriptionDayFieldHint' => 'Tanggal disiapkan tiap bulan',
			'card.subscriptionActiveLabel' => 'Aktif',
			'card.subscriptionSubtitle' => ({required Object amount, required Object day}) => '${amount} / bulan, tanggal ${day}',
			'card.subscriptionInactiveBadge' => 'Nonaktif',
			'card.historyTitleFor' => ({required Object cardName}) => 'Riwayat siklus tagihan — ${cardName}',
			'card.emptyHistory' => 'Belum ada siklus tagihan yang ditutup.',
			'card.statementPeriodLabel' => ({required Object start, required Object end}) => '${start} – ${end}',
			'card.confirmDeleteCardTitle' => ({required Object name}) => 'Hapus kartu ${name}?',
			'card.confirmDeleteCardMessage' => 'Seluruh siklus tagihan dan transaksi kartu ini akan terhapus. Baris anggaran yang menaut kartu ini akan kehilangan sumbernya. Tindakan ini tidak bisa dibatalkan.',
			'card.confirmDeleteSubscriptionTitle' => ({required Object name}) => 'Hapus langganan ${name}?',
			'card.confirmDeleteSubscriptionMessage' => 'Langganan ini tidak lagi disiapkan otomatis tiap siklus tagihan. Transaksi yang sudah tercatat tidak terpengaruh. Tindakan ini tidak bisa dibatalkan.',
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
			'grocery.cycleIdFieldHint' => 'Bulan',
			'grocery.confirmDeleteItemTitle' => ({required Object name}) => 'Hapus ${name}?',
			'grocery.confirmDeleteItemMessage' => 'Total bulanan rencana belanja akan berubah, dan baris anggaran yang menautnya ikut menyesuaikan. Tindakan ini tidak bisa dibatalkan.',
			'investment.pageTitle' => 'Investasi',
			'investment.totalPortfolioTitle' => 'Total portofolio',
			'investment.goalsTitle' => 'Pos tujuan',
			'investment.emptyGoals' => 'Belum ada pos tujuan.',
			'investment.addGoalTitle' => 'Tambah pos',
			'investment.editGoalTitle' => 'Sunting pos',
			'investment.goalNameFieldHint' => 'Nama pos',
			'investment.openingBalanceFieldHint' => 'Saldo awal (Rp)',
			'investment.allocationPlanTitle' => 'Alokasi bulan ini',
			'investment.cycleIdFieldHint' => 'Siklus',
			'investment.noCyclesAvailable' => 'Belum ada siklus yang bisa dipilih. Buat siklus dulu di tab Siklus.',
			'investment.cycleNotFound' => 'Siklus ini belum ada.',
			'investment.cycleClosedMessage' => 'Siklus ini sudah ditutup. Buka kembali untuk menyunting alokasi.',
			'investment.remainderLabel' => 'Sisa siklus',
			'investment.returnDepositFieldHint' => 'Tambahan dana (Rp)',
			'investment.percentageFieldHint' => '%',
			'investment.totalPercentageLabel' => ({required Object total}) => 'Total persentase: ${total}%',
			'investment.loansTitle' => 'Pinjaman antar pos',
			'investment.emptyLoans' => 'Belum ada pinjaman.',
			'investment.addLoanTitle' => 'Tambah pinjaman',
			'investment.editLoanTitle' => 'Sunting pinjaman',
			'investment.fromGoalFieldHint' => 'Dari pos',
			'investment.toGoalFieldHint' => 'Ke pos',
			'investment.principalFieldHint' => 'Pokok (Rp)',
			'investment.repaidFieldHint' => 'Dikembalikan (Rp)',
			'investment.noteFieldHint' => 'Catatan (opsional)',
			'investment.historyTitle' => 'Riwayat',
			'investment.allocationHistoryLabel' => ({required Object cycleId}) => 'Alokasi siklus ${cycleId}',
			'investment.loanInLabel' => ({required Object fromName}) => 'Pinjaman dari ${fromName}',
			'investment.loanOutLabel' => ({required Object toName}) => 'Pinjaman ke ${toName}',
			'investment.loanRouteLabel' => ({required Object fromName, required Object toName}) => '${fromName} → ${toName}',
			'investment.loanAmountsLabel' => ({required Object principal, required Object repaid}) => 'Pokok ${principal}, dikembalikan ${repaid}',
			'investment.invalidTotalMessage' => 'Total persentase harus 0 atau 100.',
			'investment.allocationSavedMessage' => 'Rencana alokasi disimpan.',
			'investment.loanSavedMessage' => 'Pinjaman disimpan.',
			'investment.confirmDeleteGoalTitle' => ({required Object name}) => 'Hapus pos ${name}?',
			'investment.confirmDeleteGoalMessage' => 'Saldo pos dan seluruh riwayat alokasinya akan terhapus. Tindakan ini tidak bisa dibatalkan.',
			'investment.confirmDeleteLoanTitle' => 'Hapus pinjaman ini?',
			'investment.confirmDeleteLoanMessage' => 'Catatan pokok dan pengembaliannya akan terhapus, dan saldo kedua pos ikut berubah. Tindakan ini tidak bisa dibatalkan.',
			'shell.cycleTabLabel' => 'Siklus',
			'shell.incomeTabLabel' => 'Pemasukan',
			'shell.groceryTabLabel' => 'Belanja',
			'shell.investmentTabLabel' => 'Investasi',
			_ => null,
		};
	}
}
